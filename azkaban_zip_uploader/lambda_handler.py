import os
import logging
import json
import urllib3
import boto3

logger = logging.getLogger(__name__)
log_level = os.environ["LOG_LEVEL"] if "LOG_LEVEL" in os.environ else "INFO"
logger.setLevel(logging.getLevelName(log_level.upper()))
logger.info("Logging at {} level".format(log_level.upper()))

def handler(event, context):
    s3_client = boto3.client("s3")
    http = urllib3.PoolManager(cert_reqs='CERT_NONE')
    logger.info(f"Establishing Azkaban session")
    azkaban_session_id = establish_azkaban_session(http)
    logger.info(f"Azkaban session established")

    bucket_id = event.get("Records")[0].get("s3").get("bucket").get("name")
    key = event.get("Records")[0].get("s3").get("object").get("key")
    prefix = os.path.dirname(key) if '/' in key else key

    logger.info("Getting list of files from s3")
    zips = get_files_from_s3(bucket_id, prefix, s3_client)
    logger.info(f"List of files from s3 returned: {zips}")

    for zip in zips:
        logger.info(f"Getting file: {zip}")
        file = get_file(bucket_id, zip, s3_client)
        logger.info(f"Got file: {zip}")

        basename = os.path.basename(zip) if '/' in zip else zip

        logger.info(f"Uploading {zip} to Azkaban")
        upload_to_azkaban_api(file, basename, azkaban_session_id, http, os.getenv('AZKABAN_API_URL'))
        logger.info(f"{zip} successfully uploaded to Azkaban")


def get_files_from_s3(bucket_id, s3_dir, s3_client):

    files_in_s3 = s3_client.list_objects_v2(
        Prefix=s3_dir,
        Bucket=bucket_id
    )['Contents']

    return [file['Key'] for file in files_in_s3 if file['Key'].endswith(".zip")]



def get_file(bucket_id, key, s3_client):
    zip_file = s3_client.get_object(
        Bucket=bucket_id,
        Key=key
    )['Body'].read()

    return zip_file


def upload_to_azkaban_api(zip_file, zip_file_name, session_id, http, azkaban_url):
    project_name = os.path.splitext(zip_file_name)[0]

    # creates project, if doesn't exist
    create_project(azkaban_url, http, session_id, project_name)

    boundary = "----WebKitFormBoundaryK42OAofX56OI15GD"
    auth_response_json = http.request(
        'POST',
        f'https://{azkaban_url}:8443/manager',
        multipart_boundary=boundary,
        fields={
            'ajax': (None, 'upload', None),
            'file': (zip_file_name, zip_file, 'application/zip'),
            'project': (None, project_name, None),
            'session.id': (None, session_id, None)
        }
    )
    try:
        auth_response_body = json.loads(auth_response_json.data.decode('utf-8'))
        if auth_response_body.get('error'):
            raise urllib3.exceptions.ResponseError(f"Failure uploading {project_name} to Azkaban API - Error in API response body.")
    except json.JSONDecodeError:
        if auth_response_json.status != 200:
            raise urllib3.exceptions.ResponseError(f"Failure uploading {project_name} to Azkaban API - non 200 status returned.")
        pass

def create_project(azkaban_url, http, session_id, project_name):
    auth_response_json = http.request(
        'POST',
        f'https://{azkaban_url}:8443/manager?action=create',
        headers={
            "Content-Type": "application/x-www-form-urlencoded"
        },
        body=f'name={project_name}&session.id={session_id}&description="Project for {project_name}"'.encode('utf-8')
    )

    auth_response_body = json.loads(auth_response_json.data.decode('utf-8'))

    if auth_response_body.get('status') == 'success':
        logger.info(f'Project \"{project_name}\" was created.')
    elif auth_response_body.get('error') and auth_response_body.get('message') == 'Project already exists.':
        logger.info(f'Project \"{project_name}\" already exists - using existing project.')
    else:
        raise urllib3.exceptions.ResponseError(
            auth_response_body.get('message') or 'Response not recognised for project creation call.'
        )

def establish_azkaban_session(http):
    azkaban_url = os.getenv('AZKABAN_API_URL')
    azkaban_secret = os.getenv('AZKABAN_SECRET')

    secrets_manager_client = boto3.client('secretsmanager')

    logger.info(f"Retrieving Azkaban secret")
    secret_dict = secrets_manager_client.get_secret_value(
        SecretId=azkaban_secret
    )
    logger.info(f"Azkaban secret retrieved")
    binary_dict = json.loads(secret_dict['SecretBinary'])

    azkaban_username = binary_dict.get("azkaban_username")
    azkaban_password = binary_dict.get("azkaban_password")

    auth_response_json = http.request(
        'POST',
        f'https://{azkaban_url}:8443/manager?action=login',
        headers={
            "Content-Type": "application/x-www-form-urlencoded"
        },
        body=f'username={azkaban_username}&password={azkaban_password}'.encode('utf-8')
    )
    auth_response_body = json.loads(auth_response_json.data.decode('utf-8'))

    if auth_response_body.get("status") == "success":
        return auth_response_body.get("session.id")
    else:
        raise urllib3.exceptions.ResponseError("Failure establising Azkaban API session.")
