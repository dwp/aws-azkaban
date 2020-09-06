locals {
  service_discovery_fqdn = "${local.environment}.workflow-manager.services.${var.parent_domain_name}"
  loadbalancer_fqdn      = "${local.environment}.workflow-manager.${var.parent_domain_name}"
}

resource "aws_service_discovery_private_dns_namespace" "workflow_manager" {
  name = "${local.environment}.workflow-manager.services.${var.parent_domain_name}"
  vpc  = module.workflow_manager_vpc.vpc.id
}

resource "aws_route53_zone" "workflow_manager" {
  name = "${local.environment}.workflow-manager.${var.parent_domain_name}"

  vpc {
    vpc_id = module.workflow_manager_vpc.vpc.id
  }
}

resource "aws_route53_record" "azkaban_loadbalancer" {
  name    = "azkaban.${local.loadbalancer_fqdn}"
  type    = "A"
  zone_id = aws_route53_zone.workflow_manager.id

  alias {
    evaluate_target_health = false
    name                   = aws_lb.workflow_manager.dns_name
    zone_id                = aws_lb.workflow_manager.zone_id
  }
}
