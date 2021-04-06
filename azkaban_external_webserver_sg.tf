resource "aws_security_group" "azkaban_external_webserver" {
  name        = "azkaban-external-webserver"
  description = "Rules necesary for accessing other services"
  vpc_id      = module.workflow_manager_vpc.vpc.id
  tags        = merge(local.common_tags, { Name = "azkaban-external-webserver" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "allow_azkaban_external_webserver_egress_azkaban_database" {
  description              = "Allows azkaban webserver to access azkaban database"
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = aws_rds_cluster.azkaban_database.port
  to_port                  = aws_rds_cluster.azkaban_database.port
  security_group_id        = aws_security_group.azkaban_external_webserver.id
  source_security_group_id = aws_security_group.azkaban_database.id
}

resource "aws_security_group_rule" "allow_azkaban_external_webserver_egress_azkaban_external_executor" {
  description              = "Allows azkaban external webserver to access azkaban external executor"
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = jsondecode(data.aws_secretsmanager_secret_version.workflow_manager.secret_binary).ports.azkaban_external_executor_port
  to_port                  = jsondecode(data.aws_secretsmanager_secret_version.workflow_manager.secret_binary).ports.azkaban_external_executor_port
  security_group_id        = aws_security_group.azkaban_external_webserver.id
  source_security_group_id = aws_security_group.azkaban_external_executor.id
}

resource "aws_security_group_rule" "allow_azkaban_external_webserver_ingress_azkaban_external_executor" {
  description              = "Allows azkaban webserver to access azkaban executor"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = jsondecode(data.aws_secretsmanager_secret_version.workflow_manager.secret_binary).ports.azkaban_external_webserver_port
  to_port                  = jsondecode(data.aws_secretsmanager_secret_version.workflow_manager.secret_binary).ports.azkaban_external_webserver_port
  security_group_id        = aws_security_group.azkaban_external_webserver.id
  source_security_group_id = aws_security_group.azkaban_external_executor.id
}

resource "aws_security_group_rule" "allow_azkaban_external_webserver_ingress_external_loadbalancer" {
  description              = "Allows loadbalancer to access azkaban webserver"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = jsondecode(data.aws_secretsmanager_secret_version.workflow_manager.secret_binary).ports.azkaban_external_webserver_port
  to_port                  = jsondecode(data.aws_secretsmanager_secret_version.workflow_manager.secret_binary).ports.azkaban_external_webserver_port
  security_group_id        = aws_security_group.azkaban_external_webserver.id
  source_security_group_id = aws_security_group.azkaban_external_loadbalancer.id
}

resource "aws_security_group_rule" "allow_azkaban_external_webserver_ingress_zip_uploader" {
  description              = "Allows zip_uploader lambda to access azkaban webserver api endpoint"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = jsondecode(data.aws_secretsmanager_secret_version.workflow_manager.secret_binary).ports.azkaban_external_webserver_port
  to_port                  = jsondecode(data.aws_secretsmanager_secret_version.workflow_manager.secret_binary).ports.azkaban_external_webserver_port
  security_group_id        = aws_security_group.azkaban_external_webserver.id
  source_security_group_id = aws_security_group.azkaban_zip_uploader.id
}

resource "aws_security_group_rule" "azkaban_external_webserver_egress_internet_proxy" {
  description              = "Allow Azkaban External Webserver internet access via the proxy"
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = var.internet_proxy_port
  to_port                  = var.internet_proxy_port
  source_security_group_id = aws_security_group.internet_proxy_endpoint.id
  security_group_id        = aws_security_group.azkaban_external_webserver.id
}

resource "aws_security_group_rule" "azkaban_external_webserver_ingress_internet_proxy" {
  description              = "Allow proxy access from Azkaban Webserver"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = var.internet_proxy_port
  to_port                  = var.internet_proxy_port
  source_security_group_id = aws_security_group.azkaban_external_webserver.id
  security_group_id        = aws_security_group.internet_proxy_endpoint.id
}

