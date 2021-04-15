resource "aws_security_group" "azkaban_external_rotate_password" {
  name        = "azkaban-external-rotate-password"
  description = "Rules necesary for rotating azkaban external database passwords"
  vpc_id      = module.workflow_manager_vpc.vpc.id
  tags        = merge(local.common_tags, { Name = "azkaban-external-rotate-password" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "allow_rotate_password_lambda_egress_azkaban_external_database" {
  description              = "Allows rotate password lambda to access azkaban external database"
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = aws_rds_cluster.azkaban_external_database.port
  to_port                  = aws_rds_cluster.azkaban_external_database.port
  security_group_id        = aws_security_group.azkaban_external_rotate_password.id
  source_security_group_id = aws_security_group.azkaban_external_database.id
}

