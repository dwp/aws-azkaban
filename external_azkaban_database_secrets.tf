resource "aws_secretsmanager_secret" "azkaban_external_master_password" {
  name        = "azkaban-external-master-rds-password"
  description = "Azkaban master external database password"

  lifecycle {
    ignore_changes = [tags]
  }
}

resource "aws_secretsmanager_secret" "azkaban_external_webserver_password" {
  name        = "azkaban-external-webserver-rds-password"
  description = "Azkaban external webserver database password"

  lifecycle {
    ignore_changes = [tags]
  }
}

resource "aws_secretsmanager_secret" "azkaban_external_executor_password" {
  name        = "azkaban-external-executor-rds-password"
  description = "Azkaban external executor database password"

  lifecycle {
    ignore_changes = [tags]
  }
}
