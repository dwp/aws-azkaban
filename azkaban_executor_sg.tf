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
  to_port                  = aws_rds_cluster.azkaban_database.port
  protocol                 = "tcp"
  from_port                = aws_rds_cluster.azkaban_database.port
  security_group_id        = aws_security_group.azkaban_executor.id
  source_security_group_id = aws_security_group.azkaban_database.id
}

resource "aws_security_group_rule" "allow_azkaban_executor_ingress_azkaban_webserver" {
  description              = "Allows azkaban webserver to access azkaban executor"
  type                     = "ingress"
  to_port                  = jsondecode(data.aws_secretsmanager_secret_version.workflow_manager.secret_binary).ports.azkaban_executor_port
  protocol                 = "tcp"
  from_port                = jsondecode(data.aws_secretsmanager_secret_version.workflow_manager.secret_binary).ports.azkaban_executor_port
  security_group_id        = aws_security_group.azkaban_executor.id
  source_security_group_id = aws_security_group.azkaban_webserver.id
}

resource "aws_security_group_rule" "allow_azkaban_executor_egress_azkaban_webserver" {
  description              = "Allows azkaban webserver to access azkaban executor"
  type                     = "egress"
  to_port                  = jsondecode(data.aws_secretsmanager_secret_version.workflow_manager.secret_binary).ports.azkaban_webserver_port
  protocol                 = "tcp"
  from_port                = jsondecode(data.aws_secretsmanager_secret_version.workflow_manager.secret_binary).ports.azkaban_webserver_port
  security_group_id        = aws_security_group.azkaban_executor.id
  source_security_group_id = aws_security_group.azkaban_webserver.id
}

resource "aws_security_group_rule" "azkaban_executor_egress_internet_proxy" {
  description              = "Allow Azkaban executor internet access via the proxy"
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = var.internet_proxy_port
  to_port                  = var.internet_proxy_port
  source_security_group_id = aws_security_group.internet_proxy_endpoint.id
  security_group_id        = aws_security_group.azkaban_executor.id
}

resource "aws_security_group_rule" "azkaban_executor_ingress_internet_proxy" {
  description              = "Allow proxy access from Azkaban executor"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = var.internet_proxy_port
  to_port                  = var.internet_proxy_port
  source_security_group_id = aws_security_group.azkaban_executor.id
  security_group_id        = aws_security_group.internet_proxy_endpoint.id
}
