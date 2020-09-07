data "aws_availability_zones" "current" {}


module "workflow_manager_vpc" {
  source                                     = "dwp/vpc/aws"
  version                                    = "2.0.14"
  vpc_name                                   = "workflow-manager"
  region                                     = var.region
  vpc_cidr_block                             = local.cidr_block[local.environment].workflow-manager-vpc
  interface_vpce_source_security_group_count = 1
  interface_vpce_source_security_group_ids   = [aws_security_group.workflow_manager_common.id]
  interface_vpce_subnet_ids                  = aws_subnet.workflow_manager_private.*.id
  gateway_vpce_route_table_ids               = aws_route_table.workflow_manager_private.*.id
  kms_endpoint                               = true
  logs_endpoint                              = true
  monitoring_endpoint                        = true
  s3_endpoint                                = true
  secretsmanager_endpoint                    = true
  ecrapi_endpoint                            = true
  ecrdkr_endpoint                            = true
  ecs_endpoint                               = true
  emr_endpoint                               = true
  common_tags                                = local.common_tags
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
