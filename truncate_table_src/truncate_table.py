import os
import logging
import boto3

rds_client = boto3.client('rds-data')

# Initialise logging
logger = logging.getLogger(__name__)
log_level = os.environ["LOG_LEVEL"] if "LOG_LEVEL" in os.environ else "INFO"
logger.setLevel(logging.getLevelName(log_level.upper()))
logger.info("Logging at {} level".format(log_level.upper()))

RDS_CREDENTIALS_SECRET_ARN = os.environ["RDS_CREDENTIALS_SECRET_ARN"]
RDS_DATABASE_NAME = os.environ["RDS_DATABASE_NAME"]
RDS_CLUSTER_ARN = os.environ["RDS_CLUSTER_ARN"]


def execute_statement(sql, database_name=None):
    kwargs = {
        "secretArn": RDS_CREDENTIALS_SECRET_ARN,
        "resourceArn": RDS_CLUSTER_ARN,
        "sql": sql
    }
    if database_name is not None:
        kwargs["database"] = database_name

    response = rds_client.execute_statement(**kwargs)
    return response


def handler(event, context):
    if 'table_to_truncate' in event:
        table = event["table_to_truncate"]
        logger.info(f"Truncating table {table}")
        return execute_statement(f"TRUNCATE TABLE `{table}`", RDS_DATABASE_NAME)
    else:
        logger.info("No table specified")
