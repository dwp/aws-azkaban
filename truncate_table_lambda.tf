resource "aws_lambda_function" "truncate_table" {
  filename         = "${path.module}/lambda.zip"
  function_name    = "azkaban-truncate-table"
  role             = aws_iam_role.truncate_table.arn
  handler          = "truncate_table.handler"
  runtime          = "python3.7"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  timeout                        = 300
  reserved_concurrent_executions = 1

  environment {
    variables = {
      RDS_DATABASE_NAME          = "azkabans"
      RDS_CLUSTER_ARN            = aws_rds_cluster.azkaban_database.arn
      RDS_CREDENTIALS_SECRET_ARN = aws_secretsmanager_secret.azkaban_executor_password.arn
      LOG_LEVEL                  = "DEBUG"
    }
  }
  tracing_config {
    mode = "PassThrough"
  }
  tags = merge(
  local.common_tags,
  {
    "Name" = "azkaban-manage-mysql-user"
  },
  {
    "ProtectsSensitiveData" = "False"
  },
  )

  depends_on = [data.archive_file.lambda_zip]
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/truncate_table_src"
  output_path = "${path.module}/lambda.zip"
}
