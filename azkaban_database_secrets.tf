resource "aws_secretsmanager_secret" "azkaban_master_password" {
  name        = "azkaban-master-rds-password"
  description = "Azkaban master database password"

  lifecycle {
    ignore_changes = [tags]
  }
}

resource "aws_secretsmanager_secret" "azkaban_webserver_password" {
  name        = "azkaban-webserver-rds-password"
  description = "Azkaban webserver database password"

  lifecycle {
    ignore_changes = [tags]
  }
}

resource "aws_secretsmanager_secret" "azkaban_executor_password" {
  name        = "azkaban-executor-rds-password"
  description = "Azkaban webserver database password"

  lifecycle {
    ignore_changes = [tags]
  }
}
