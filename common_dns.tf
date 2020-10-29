locals {
  service_discovery_fqdn = "workflow-manager.services.${var.parent_domain_name}"
  loadbalancer_fqdn      = "workflow-manager.${var.parent_domain_name}"
}

resource "aws_service_discovery_private_dns_namespace" "workflow_manager" {
  name = local.service_discovery_fqdn
  vpc  = module.workflow_manager_vpc.vpc.id
}

resource "aws_route53_zone" "workflow_manager" {
  name = local.loadbalancer_fqdn

  vpc {
    vpc_id = module.workflow_manager_vpc.vpc.id
  }

  lifecycle {
    ignore_changes = [vpc]
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

resource "aws_acm_certificate" "azkaban_loadbalancer" {
  domain_name               = "azkaban.${local.loadbalancer_fqdn}"
  certificate_authority_arn = data.terraform_remote_state.certificate_authority.outputs.root_ca.arn

  options {
    certificate_transparency_logging_preference = "DISABLED"
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(local.common_tags, { Name = "azkaban-lb" })
}

resource "aws_route53_zone_association" "analytical_env" {
  zone_id = aws_route53_zone.workflow_manager.id
  vpc_id  = data.terraform_remote_state.aws_analytical_environment_infra.outputs.vpc_main.vpc.id
}