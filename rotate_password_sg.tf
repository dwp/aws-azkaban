resource "aws_security_group" "azkaban_rotate_password" {
  name        = "azkaban-rotate-password"
  description = "Rules necesary for rotating azkaban database passwords"
  vpc_id      = module.workflow_manager_vpc.vpc.id
  tags        = merge(local.common_tags, { Name = "azkaban-rotate-password" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "allow_rotate_password_lambda_egress_azkaban_database" {
  description              = "Allows rotate password lambda to access azkaban database"
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = aws_rds_cluster.azkaban_database.port
  to_port                  = aws_rds_cluster.azkaban_database.port
  security_group_id        = aws_security_group.azkaban_rotate_password.id
  source_security_group_id = aws_security_group.azkaban_database.id
}
