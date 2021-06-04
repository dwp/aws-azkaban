import lambda_handler
from unittest import TestCase
from mock import call, patch, Mock
from datetime import datetime
import boto3
import json
from botocore.stub import Stubber
import urllib3

mock_s3_client = boto3.client('s3', region_name="eu-west-2")
s3_stubber = Stubber(mock_s3_client)
list_objects_response = {
    'IsTruncated': False,
    'Contents': [
        {
            'Key': 'return1.zip',
            'LastModified': datetime(2015, 1, 1),
            'ETag': 'string',
            'Size': 123,
            'StorageClass': 'STANDARD',
            'Owner': {
                'DisplayName': 'string',
                'ID': 'string'
            }
        },
        {
            'Key': 'do_not_return.txt',
            'LastModified': datetime(2015, 1, 1),
            'ETag': 'string',
            'Size': 123,
            'StorageClass': 'STANDARD',
            'Owner': {
                'DisplayName': 'string',
                'ID': 'string'
            }
        },
        {
            'Key': 'return2.zip',
            'LastModified': datetime(2015, 1, 1),
            'ETag': 'string',
            'Size': 123,
            'StorageClass': 'STANDARD',
            'Owner': {
                'DisplayName': 'string',
                'ID': 'string'
            }
        },
    ],
    'Name': 'string',
    'EncodingType': 'url',
    'KeyCount': 123,
    'ContinuationToken': 'string'
}
s3_stubber.add_response('list_objects_v2', list_objects_response)
s3_stubber.activate()

mock_sm_client = boto3.client('secretsmanager', region_name="eu-west-2")
sm_stubber = Stubber(mock_sm_client)
mock_secret_value_response = {
    'ARN': 'arn:aws:secretsmanager:eu-west-7:123456789012:secret:tutorials/MyFirstSecret-jiObOV',
    'Name': 'string',
    'VersionId': 'EXAMPLE1-90ab-cdef-fedc-ba987EXAMPLE',
    'SecretBinary': b'{"azkaban_username": "test_user", "azkaban_password": "pw123"}',
    'CreatedDate': datetime(2015, 1, 1)
}
sm_stubber.add_response('get_secret_value', mock_secret_value_response)
sm_stubber.add_response('get_secret_value', mock_secret_value_response)
sm_stubber.activate()

data_non_fail = json.dumps({
    "status" : "error",
    "message" : "Project already exists.",
}).encode('utf-8')

http_non_fail_error= Mock()
http_non_fail_error.data = data_non_fail

data_fail = json.dumps({
    "error" : "error",
    "message" : "Other message.",
}).encode('utf-8')

http_raise_error = Mock()
http_raise_error.data = data_fail

http_status_error = Mock()
http_status_error.data = "non JSON error response".encode('utf-8')
http_status_error.status = 418

session_data = json.dumps({
    "status" : "success",
    "session.id" : "test-session-id-12345432"
}).encode('utf-8')

http_session = Mock()
http_session.data = session_data
http_session.status = 200

class LambdaHandlerTests(TestCase):
    def test_get_files_from_s3(self):
        result = lambda_handler.project_object_keys(mock_s3_client, "bucket_id", "s3_dir")

        assert result == ['return1.zip', 'return2.zip']

    @patch('lambda_handler.create_project')
    @patch('urllib3.PoolManager')
    def test_upload_to_azkaban_api_error_in_response(self, mock_http, mock_create_project):
        mock_http.request.return_value = http_raise_error

        with self.assertRaises(urllib3.exceptions.ResponseError) as context:
            lambda_handler.upload_to_azkaban_api('zip_file', 'zip_file_name', 'session_id', mock_http, 'azkaban_url')

        mock_http.request.assert_called_once()
        self.assertTrue(str(context.exception) == "Failure uploading zip_file_name to Azkaban API - Error in API response body.")

    @patch('lambda_handler.create_project')
    @patch('urllib3.PoolManager')
    def test_upload_to_azkaban_api_non_200_status(self, mock_http, mock_create_project):
        mock_http.request.return_value = http_status_error

        with self.assertRaises(urllib3.exceptions.ResponseError) as context:
            lambda_handler.upload_to_azkaban_api('zip_file', 'zip_file_name', 'session_id', mock_http, 'azkaban_url')

        mock_http.request.assert_called_once()
        self.assertTrue(str(context.exception) == "Failure uploading zip_file_name to Azkaban API - non 200 status returned.")


    @patch('urllib3.PoolManager')
    def test_create_project_error_handling_error_path(self, mock_http):
        mock_http.request.return_value = http_raise_error

        with self.assertRaises(urllib3.exceptions.ResponseError) as context:
            lambda_handler.create_project('azkaban_url', mock_http, 'session_id', 'test_project')

        mock_http.request.assert_called_once()
        self.assertTrue(str(context.exception) == 'Other message.')

    @patch('urllib3.PoolManager')
    def test_create_project_error_handling_happy_path(self, mock_http):
        mock_http.request.return_value = http_non_fail_error

        lambda_handler.create_project('azkaban_url', mock_http, 'session_id', 'test_project')
        mock_http.request.assert_called_once()

    @patch('lambda_handler.os.getenv')
    @patch('urllib3.PoolManager')
    @patch('lambda_handler.boto3')
    def test_establish_azkaban_session_raise_error(self, mock_boto3, mock_http, mock_getenv):
        mock_boto3.client.return_value = mock_sm_client
        mock_http.request.return_value = http_non_fail_error
        mock_getenv.side_effect = ["www.test_url.com", "test_secret"]

        with self.assertRaises(urllib3.exceptions.ResponseError) as context:
            lambda_handler.establish_azkaban_session(mock_http)

        mock_http.request.assert_called_once()
        self.assertTrue(str(context.exception) == 'Failure establising Azkaban API session.')

    @patch('lambda_handler.os.getenv')
    @patch('urllib3.PoolManager')
    @patch('lambda_handler.boto3')
    def test_establish_azkaban_session(self, mock_boto3, mock_http, mock_getenv):
        mock_boto3.client.return_value = mock_sm_client
        mock_http.request.return_value = http_session
        mock_getenv.side_effect = ["www.test_url.com", "test_secret"]

        result = lambda_handler.establish_azkaban_session(mock_http)
        assert result == "test-session-id-12345432"

