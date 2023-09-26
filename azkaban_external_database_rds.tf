resource "random_id" "password_salt_2" {
  byte_length = 16
}

resource "aws_cloudwatch_log_group" "azkaban_external_database_error" {
  name              = "/aws/rds/cluster/azkaban-external-database/error"
  retention_in_days = 30
  tags              = merge(local.common_tags, { Name = "azkaban-external-database-error" })
}

resource "aws_cloudwatch_log_group" "azkaban_external_database_general" {
  name              = "/aws/rds/cluster/azkaban-external-database/general"
  retention_in_days = 30
  tags              = merge(local.common_tags, { Name = "azkaban-external-database-general" })
}

resource "aws_rds_cluster" "azkaban_external_database" {
  cluster_identifier   = "azkaban-external-database"
  database_name        = jsondecode(data.aws_secretsmanager_secret_version.azkaban_external.secret_binary).db_name
  engine               = "aurora-mysql"
  engine_version       = "5.7.serverless_mysql_aurora.2.11.3"
  engine_mode          = "serverless"
  enable_http_endpoint = true

  master_username = jsondecode(data.aws_secretsmanager_secret_version.azkaban_external.secret_binary).db_username
  master_password = "password_already_rotated_${substr(random_id.password_salt_2.hex, 0, 16)}"

  apply_immediately            = true
  backup_retention_period      = 7
  preferred_backup_window      = "23:00-01:00"
  preferred_maintenance_window = "sun:01:00-sun:06:00"

  db_subnet_group_name            = aws_db_subnet_group.azkaban_external_database.name
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.azkaban_external_database.name
  availability_zones              = data.aws_availability_zones.current.names
  vpc_security_group_ids          = [aws_security_group.azkaban_external_database.id]

  lifecycle {
    ignore_changes = [master_password]
  }

  depends_on = [aws_cloudwatch_log_group.azkaban_external_database_error, aws_cloudwatch_log_group.azkaban_external_database_general]

  tags = merge(local.common_tags, { Name = "azkaban-external-database" })
}

resource "aws_db_subnet_group" "azkaban_external_database" {
  name       = "azkaban-external-database"
  subnet_ids = aws_subnet.workflow_manager_private.*.id
  tags       = merge(local.common_tags, { Name = "azkaban-external-database" })
}

resource "aws_rds_cluster_parameter_group" "azkaban_external_database" {
  name        = "azkaban-external-database"
  family      = "aurora-mysql5.7"
  description = "Parameters for the External Azkaban database"

  parameter {
    name  = "require_secure_transport"
    value = "OFF"
  }

  parameter {
    name  = "general_log"
    value = "1"
  }
}
