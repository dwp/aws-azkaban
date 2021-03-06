resource "aws_security_group" "workflow_manager_common" {
  name        = "workflow_manager_common"
  description = "Rules necessary for pulling container images and accessing VPC endpoints"
  vpc_id      = module.workflow_manager_vpc.vpc.id
  tags        = merge(local.common_tags, { Name = "workflow_manager_common" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "allow_workflow_manager_egress_https" {
  description       = "Allows ECS to pull container from S3"
  type              = "egress"
  protocol          = "tcp"
  from_port         = var.https_port
  to_port           = var.https_port
  security_group_id = aws_security_group.workflow_manager_common.id
  prefix_list_ids   = [module.workflow_manager_vpc.prefix_list_ids.s3]
}
