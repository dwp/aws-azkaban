resource "aws_security_group" "azkaban_database" {
  name        = "azkaban-database"
  description = "Rules necesary for allowing access to the database"
  vpc_id      = module.workflow_manager_vpc.vpc.id
  tags        = merge(local.common_tags, { Name = "azkaban-database" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "allow_azkaban_webserver_ingress_azkaban_database" {
  description              = "Allows azkaban webserver to access azkaban database"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = aws_rds_cluster.azkaban_database.port
  to_port                  = aws_rds_cluster.azkaban_database.port
  security_group_id        = aws_security_group.azkaban_database.id
  source_security_group_id = aws_security_group.azkaban_webserver.id
}

resource "aws_security_group_rule" "allow_azkaban_executor_ingress_azkaban_database" {
  description              = "Allows azkaban executor to access azkaban database"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = aws_rds_cluster.azkaban_database.port
  to_port                  = aws_rds_cluster.azkaban_database.port
  security_group_id        = aws_security_group.azkaban_database.id
  source_security_group_id = aws_security_group.azkaban_executor.id
}

resource "aws_security_group_rule" "allow_rotate_password_lambda_ingress_azkaban_database" {
  description              = "Allows rotate password lambda to access azkaban database"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = aws_rds_cluster.azkaban_database.port
  to_port                  = aws_rds_cluster.azkaban_database.port
  security_group_id        = aws_security_group.azkaban_database.id
  source_security_group_id = aws_security_group.azkaban_rotate_password.id
}
