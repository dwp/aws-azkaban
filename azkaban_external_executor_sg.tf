resource "aws_security_group" "azkaban_external_executor" {
  name        = "azkaban-azkaban-executor"
  description = "Rules necesary for accessing other services"
  vpc_id      = module.workflow_manager_vpc.vpc.id
  tags        = merge(local.common_tags, { Name = "azkaban-external-executor" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "allow_azkaban_external_executor_egress_azkaban_external_database" {
  description              = "Allows azkaban external executor to access azkaban external database"
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = aws_rds_cluster.azkaban_external_database.port
  to_port                  = aws_rds_cluster.azkaban_external_database.port
  security_group_id        = aws_security_group.azkaban_external_executor.id
  source_security_group_id = aws_security_group.azkaban_external_database.id
}

resource "aws_security_group_rule" "allow_azkaban_external_executor_ingress_azkaban_external_webserver" {
  description              = "Allows azkaban external webserver to access azkaban external executor"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = jsondecode(data.aws_secretsmanager_secret_version.azkaban_external.secret_binary).ports.azkaban_executor_port
  to_port                  = jsondecode(data.aws_secretsmanager_secret_version.azkaban_external.secret_binary).ports.azkaban_executor_port
  security_group_id        = aws_security_group.azkaban_external_executor.id
  source_security_group_id = aws_security_group.azkaban_external_webserver.id
}

resource "aws_security_group_rule" "allow_azkaban_external_executor_egress_azkaban_external_webserver" {
  description              = "Allows azkaban webserver to access azkaban executor"
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = jsondecode(data.aws_secretsmanager_secret_version.azkaban_external.secret_binary).ports.azkaban_webserver_port
  to_port                  = jsondecode(data.aws_secretsmanager_secret_version.azkaban_external.secret_binary).ports.azkaban_webserver_port
  security_group_id        = aws_security_group.azkaban_external_executor.id
  source_security_group_id = aws_security_group.azkaban_external_webserver.id
}

resource "aws_security_group_rule" "azkaban_external_executor_egress_internet_proxy" {
  description              = "Allow Azkaban executor internet access via the proxy"
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = var.internet_proxy_port
  to_port                  = var.internet_proxy_port
  source_security_group_id = aws_security_group.internet_proxy_endpoint.id
  security_group_id        = aws_security_group.azkaban_external_executor.id
}

resource "aws_security_group_rule" "azkaban_external_executor_ingress_internet_proxy" {
  description              = "Allow proxy access from Azkaban executor"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = var.internet_proxy_port
  to_port                  = var.internet_proxy_port
  source_security_group_id = aws_security_group.azkaban_external_executor.id
  security_group_id        = aws_security_group.internet_proxy_endpoint.id
}
