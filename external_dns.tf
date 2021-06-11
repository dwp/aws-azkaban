resource "aws_route53_record" "azkaban_external" {
  provider = aws.management-dns

  name    = local.fqdn
  type    = "A"
  zone_id = data.aws_route53_zone.main.zone_id

  alias {
    evaluate_target_health = false
    name                   = aws_lb.azkaban_external.dns_name
    zone_id                = aws_lb.azkaban_external.zone_id
  }
}

provider "aws" {
  alias  = "management-dns"
  version = "~> 3.42.0"
  region = var.region

  assume_role {
    role_arn = "arn:aws:iam::${local.account[local.management_account[local.environment]]}:role/${var.assume_role}"
  }
}

locals {
  root_dns_name = data.terraform_remote_state.aws_analytical_environment_infra.outputs.root_dns_name
  dns_zone      = data.terraform_remote_state.aws_analytical_environment_infra.outputs.parent_domain_name
  fqdn          = format("azkaban-external.%s.", local.root_dns_name)
}

data "aws_route53_zone" "main" {
  provider = aws.management-dns

  name = local.dns_zone
}

resource "aws_acm_certificate" "azkaban_external_loadbalancer" {
  domain_name       = local.fqdn
  validation_method = "DNS"

  options {
    certificate_transparency_logging_preference = "ENABLED"
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(local.common_tags, { Name = "azkaban-external-lb" })
}

resource "aws_route53_record" "record_acm_verify" {
  provider = aws.management-dns

  name    = aws_acm_certificate.azkaban_external_loadbalancer.domain_validation_options.0.resource_record_name
  type    = aws_acm_certificate.azkaban_external_loadbalancer.domain_validation_options.0.resource_record_type
  zone_id = data.aws_route53_zone.main.zone_id

  ttl = "600"

  records = [aws_acm_certificate.azkaban_external_loadbalancer.domain_validation_options.0.resource_record_value]
}

resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = aws_acm_certificate.azkaban_external_loadbalancer.arn
  validation_record_fqdns = [aws_route53_record.record_acm_verify.fqdn]
}
