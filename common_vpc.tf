data "aws_availability_zones" "current" {}


module "workflow_manager_vpc" {
  source         = "dwp/vpc/aws"
  version        = "3.0.10"
  vpc_name       = "workflow-manager"
  region         = var.region
  vpc_cidr_block = local.cidr_block[local.environment].workflow-manager-vpc
  interface_vpce_source_security_group_ids = [
    aws_security_group.workflow_manager_common.id,
    aws_security_group.azkaban_external_executor.id,
    aws_security_group.azkaban_executor.id,
  ]
  interface_vpce_subnet_ids    = aws_subnet.workflow_manager_private.*.id
  gateway_vpce_route_table_ids = aws_route_table.workflow_manager_private.*.id
  aws_vpce_services = [
    "kms",
    "logs",
    "monitoring",
    "s3",
    "secretsmanager",
    "ecr.api",
    "ecr.dkr",
    "ecs",
    "elasticmapreduce",
    "sts",
    "dynamodb",
    "sns",
  ]
  common_tags = local.common_tags
}

resource "aws_subnet" "workflow_manager_private" {
  count                = length(data.aws_availability_zones.current.zone_ids)
  cidr_block           = cidrsubnet(module.workflow_manager_vpc.vpc.cidr_block, var.subnets.private.newbits, var.subnets.private.netnum + count.index)
  vpc_id               = module.workflow_manager_vpc.vpc.id
  availability_zone_id = data.aws_availability_zones.current.zone_ids[count.index]
  tags                 = merge(local.common_tags, { Name = "${local.name}-private-${data.aws_availability_zones.current.names[count.index]}" })
}

resource "aws_route_table" "workflow_manager_private" {
  count  = length(data.aws_availability_zones.current.zone_ids)
  vpc_id = module.workflow_manager_vpc.vpc.id
  tags   = merge(local.common_tags, { Name = "${local.name}-private-${data.aws_availability_zones.current.names[count.index]}" })
}

resource "aws_route_table_association" "workflow_manager_private" {
  count          = length(data.aws_availability_zones.current.zone_ids)
  route_table_id = aws_route_table.workflow_manager_private[count.index].id
  subnet_id      = aws_subnet.workflow_manager_private[count.index].id
}

resource "aws_cloudwatch_log_group" "workflow_manager" {
  name = "${data.terraform_remote_state.common.outputs.ecs_cluster_main_log_group.name}/${local.name}"
  tags = merge(local.common_tags, { Name = local.name })
}

resource "aws_vpc_endpoint" "internet_proxy" {
  vpc_id              = module.workflow_manager_vpc.vpc.id
  service_name        = data.terraform_remote_state.internet_egress.outputs.internet_proxy_service.service_name
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.internet_proxy_endpoint.id]
  subnet_ids          = aws_subnet.workflow_manager_private.*.id
  private_dns_enabled = false
  tags                = merge(local.common_tags, { Name = local.name })
}

resource "aws_security_group" "internet_proxy_endpoint" {
  name        = "proxy_vpc_endpoint"
  description = "Control access to the Internet Proxy VPC Endpoint"
  vpc_id      = module.workflow_manager_vpc.vpc.id
  tags        = merge(local.common_tags, { Name = local.name })
}
