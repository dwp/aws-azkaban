resource "aws_vpc_peering_connection" "analytical_env" {
  peer_vpc_id = data.terraform_remote_state.aws_analytical_environment_infra.outputs.vpc_main.vpc.id
  vpc_id      = module.workflow_manager_vpc.vpc.id
  auto_accept = true
  tags        = merge(local.common_tags, { Name = local.name })
}

resource "aws_route" "analytical_env_azkaban_webserver" {
  count                     = length(data.terraform_remote_state.aws_analytical_environment_infra.outputs.vpc.aws_route_table_private_ids)
  route_table_id            = data.terraform_remote_state.aws_analytical_environment_infra.outputs.vpc.aws_route_table_private_ids[count.index]
  destination_cidr_block    = module.workflow_manager_vpc.vpc.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.analytical_env.id
}

resource "aws_route" "azkaban_webserver_analytical_env" {
  count                     = length(data.aws_availability_zones.current.zone_ids)
  route_table_id            = aws_route_table.workflow_manager_private[count.index].id
  destination_cidr_block    = data.terraform_remote_state.aws_analytical_environment_infra.outputs.vpc_main.vpc.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.analytical_env.id
}

resource "aws_security_group_rule" "azkaban_allow_ingress_analytical_env" {
  description              = "Allow analytical environment to access azkaban"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = var.https_port
  to_port                  = var.https_port
  security_group_id        = aws_security_group.workflow_manager_loadbalancer.id
  source_security_group_id = data.terraform_remote_state.orchestration_service.outputs.ecs_user_host.security_group_id
}

resource "aws_security_group_rule" "azkaban_allow_egress_analytical_env" {
  description              = "Allow analytical environment to access azkaban"
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = var.https_port
  to_port                  = var.https_port
  security_group_id        = data.terraform_remote_state.orchestration_service.outputs.ecs_user_host.security_group_id
  source_security_group_id = aws_security_group.workflow_manager_loadbalancer.id
}
  
