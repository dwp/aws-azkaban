resource "aws_security_group" "azkaban_executor" {
  name        = "azkaban-executor"
  description = "Rules necesary for accessing other services"
  vpc_id      = module.workflow_manager_vpc.vpc.id
  tags        = merge(local.common_tags, { Name = "azkaban-executor" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "allow_azkaban_executor_egress_azkaban_database" {
  description              = "Allows azkaban executor to access azkaban database"
  type                     = "egress"
  to_port                  = aws_db_instance.azkaban_database.port
  protocol                 = "tcp"
  from_port                = aws_db_instance.azkaban_database.port
  security_group_id        = aws_security_group.azkaban_executor.id
  source_security_group_id = aws_security_group.azkaban_database.id
}

resource "aws_security_group_rule" "allow_azkaban_webserver_ingress_azkaban_executor" {
  description              = "Allows azkaban webserver to access azkaban executor"
  type                     = "ingress"
  to_port                  = jsondecode(data.aws_secretsmanager_secret_version.workflow_manager.secret_binary).ports.azkaban_executor_port
  protocol                 = "tcp"
  from_port                = jsondecode(data.aws_secretsmanager_secret_version.workflow_manager.secret_binary).ports.azkaban_executor_port
  security_group_id        = aws_security_group.azkaban_executor.id
  source_security_group_id = aws_security_group.azkaban_webserver.id
}
