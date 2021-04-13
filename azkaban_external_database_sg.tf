resource "aws_security_group" "azkaban_external_database" {
  name        = "azkaban-external-database"
  description = "Rules necesary for allowing access to the database"
  vpc_id      = module.workflow_manager_vpc.vpc.id
  tags        = merge(local.common_tags, { Name = "azkaban-external-database" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "allow_azkaban_external_webserver_ingress_azkaban_external_database" {
  description              = "Allows azkaban external webserver to access azkaban external database"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = aws_rds_cluster.azkaban_external_database.port
  to_port                  = aws_rds_cluster.azkaban_external_database.port
  security_group_id        = aws_security_group.azkaban_external_database.id
  source_security_group_id = aws_security_group.azkaban_external_webserver.id
}

resource "aws_security_group_rule" "allow_azkaban_external_executor_ingress_azkaban_external_database" {
  description              = "Allows azkaban external executor to access azkaban external database"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = aws_rds_cluster.azkaban_external_database.port
  to_port                  = aws_rds_cluster.azkaban_external_database.port
  security_group_id        = aws_security_group.azkaban_external_database.id
  source_security_group_id = aws_security_group.azkaban_external_executor.id
}

resource "aws_security_group_rule" "allow_rotate_password_lambda_ingress_azkaban_external_database" {
  description              = "Allows rotate password lambda to access azkaban database"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = aws_rds_cluster.azkaban_external_database.port
  to_port                  = aws_rds_cluster.azkaban_external_database.port
  security_group_id        = aws_security_group.azkaban_external_database.id
  source_security_group_id = aws_security_group.azkaban_rotate_password.id
}
