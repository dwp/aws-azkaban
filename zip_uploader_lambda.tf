resource "aws_lambda_function" "zip_uploader" {
  filename         = "${path.module}/zip_uploader_lambda.zip"
  function_name    = "azkaban-zip-uploader"
  role             = aws_iam_role.lambda_zip_uploader.arn
  handler          = "lambda_handler.handler"
  runtime          = "python3.7"
  source_code_hash = data.archive_file.zip_uploader_lambda_zip.output_base64sha256

  timeout                        = 300
  reserved_concurrent_executions = 1

  vpc_config {
    subnet_ids         = aws_subnet.workflow_manager_private.*.id
    security_group_ids = [aws_security_group.workflow_manager_common.id, aws_security_group.azkaban_zip_uploader.id]
  }

  environment {
    variables = {
      LOG_LEVEL       = local.azkaban_zip_uploader_log_level[local.environment]
      AZKABAN_API_URL = "azkaban-external-webserver.${local.service_discovery_fqdn}"
      AZKABAN_API_PORT = "7443"
      AZKABAN_SECRET  = data.aws_secretsmanager_secret.azkaban_external_cognito.name
      ENVIRONMENT     = local.environment
    }
  }
  tracing_config {
    mode = "PassThrough"
  }
  tags = merge(
    local.common_tags,
    {
      "Name" = "azkaban-zip-uploader"
    },
    {
      "ProtectsSensitiveData" = "False"
    },
  )

  depends_on = [data.archive_file.zip_uploader_lambda_zip]
}

data "archive_file" "zip_uploader_lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/azkaban_zip_uploader"
  output_path = "${path.module}/zip_uploader_lambda.zip"
}

resource "aws_s3_bucket_notification" "aws-lambda-trigger" {
  bucket = data.terraform_remote_state.common.outputs.config_bucket.id
  lambda_function {
    lambda_function_arn = aws_lambda_function.zip_uploader.arn
    events              = ["s3:ObjectCreated:Put"]
    filter_prefix       = "workflow-manager/azkaban_uploads/"
    filter_suffix       = ".success"
  }
}

resource "aws_lambda_permission" "zip_uploader_trigger_permission" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.zip_uploader.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = data.terraform_remote_state.common.outputs.config_bucket.arn
}
