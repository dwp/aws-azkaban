resource "aws_security_group" "azkaban_webserver" {
  name        = "azkaban-webserver"
  description = "Rules necesary for accessing other services"
  vpc_id      = module.workflow_manager_vpc.vpc.id
  tags        = merge(local.common_tags, { Name = "azkaban-webserver" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "allow_azkaban_webserver_egress_azkaban_database" {
  description              = "Allows azkaban webserver to access azkaban database"
  type                     = "egress"
  from_port                = aws_db_instance.azkaban_database.port
  to_port                  = aws_db_instance.azkaban_database.port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.azkaban_webserver.id
  source_security_group_id = aws_security_group.azkaban_database.id
}

resource "aws_security_group_rule" "allow_azkaban_webserver_egress_azkaban_executor" {
  description              = "Allows azkaban webserver to access azkaban executor"
  type                     = "egress"
  to_port                  = jsondecode(data.aws_secretsmanager_secret_version.workflow_manager.secret_binary).ports.azkaban_executor_port
  protocol                 = "tcp"
  from_port                = jsondecode(data.aws_secretsmanager_secret_version.workflow_manager.secret_binary).ports.azkaban_executor_port
  security_group_id        = aws_security_group.azkaban_webserver.id
  source_security_group_id = aws_security_group.azkaban_executor.id
}

resource "aws_security_group_rule" "allow_azkaban_webserver_ingress_loadbalancer" {
  description              = "Allows loadbalancer to access azkaban webserver"
  type                     = "ingress"
  to_port                  = jsondecode(data.aws_secretsmanager_secret_version.workflow_manager.secret_binary).ports.azkaban_webserver_port
  protocol                 = "tcp"
  from_port                = jsondecode(data.aws_secretsmanager_secret_version.workflow_manager.secret_binary).ports.azkaban_webserver_port
  security_group_id        = aws_security_group.azkaban_webserver.id
  source_security_group_id = aws_security_group.workflow_manager_loadbalancer.id
}

resource "aws_security_group_rule" "allow_azkaban_webserver_ingress_azkaban_executor" {
  description              = "Allows azkaban webserver to access azkaban executor"
  type                     = "ingress"
  to_port                  = jsondecode(data.aws_secretsmanager_secret_version.workflow_manager.secret_binary).ports.azkaban_webserver_port
  protocol                 = "tcp"
  from_port                = jsondecode(data.aws_secretsmanager_secret_version.workflow_manager.secret_binary).ports.azkaban_webserver_port
  security_group_id        = aws_security_group.azkaban_webserver.id
  source_security_group_id = aws_security_group.azkaban_executor.id
}

resource "aws_security_group_rule" "azkaban_webserver_egress_internet_proxy" {
  description              = "Allow Azkaban Webserver internet access via the proxy"
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = var.internet_proxy_port
  to_port                  = var.internet_proxy_port
  source_security_group_id = aws_security_group.internet_proxy_endpoint.id
  security_group_id        = aws_security_group.azkaban_webserver.id
}

resource "aws_security_group_rule" "azkaban_webserver_ingress_internet_proxy" {
  description              = "Allow proxy access from Azkaban Webserver"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = var.internet_proxy_port
  to_port                  = var.internet_proxy_port
  source_security_group_id = aws_security_group.azkaban_webserver.id
  security_group_id        = aws_security_group.internet_proxy_endpoint.id
}

