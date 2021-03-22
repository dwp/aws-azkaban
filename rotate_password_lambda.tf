
variable "manage_mysql_user_zip" {
  type = map(string)
  default = {
    base_path = ""
    version   = ""
  }
}

resource "aws_lambda_function" "manage_mysql_user" {
  filename      = "${var.manage_mysql_user_zip["base_path"]}/manage-mysql-user-${var.manage_mysql_user_zip["version"]}.zip"
  function_name = "manage-azkaban-mysql-user"
  role          = aws_iam_role.lambda_manage_mysql_user.arn
  handler       = "manage-mysql-user.handler"
  runtime       = "python3.7"
  source_code_hash = filebase64sha256(
    format(
      "%s/manage-mysql-user-%s.zip",
      var.manage_mysql_user_zip["base_path"],
      var.manage_mysql_user_zip["version"],
    ),
  )
  publish = false
  vpc_config {
    subnet_ids         = aws_subnet.workflow_manager_private.*.id
    security_group_ids = [aws_security_group.workflow_manager_common.id, aws_security_group.azkaban_rotate_password.id]
  }
  timeout                        = 300
  reserved_concurrent_executions = 1
  environment {
    variables = {
      RDS_ENDPOINT                    = aws_rds_cluster.azkaban_database.endpoint
      RDS_DATABASE_NAME               = jsondecode(data.aws_secretsmanager_secret_version.workflow_manager.secret_binary).db_name
      RDS_MASTER_USERNAME             = jsondecode(data.aws_secretsmanager_secret_version.workflow_manager.secret_binary).db_username
      RDS_MASTER_PASSWORD_SECRET_NAME = aws_secretsmanager_secret.azkaban_master_password.name
      RDS_CA_CERT                     = "/var/task/AmazonRootCA1.pem" # For Aurora serverless
      LOG_LEVEL                       = "DEBUG"
    }
  }
  tracing_config {
    mode = "PassThrough"
  }
  tags = merge(
    local.common_tags,
    {
      "Name" = "manage-azkaban-mysql-user"
    },
    {
      "ProtectsSensitiveData" = "False"
    },
  )
  depends_on = [aws_cloudwatch_log_group.manage_mysql_user]
}

resource "aws_cloudwatch_log_group" "manage_mysql_user" {
  name              = "/aws/lambda/manage-azkaban-mysql-user"
  retention_in_days = 180
}
