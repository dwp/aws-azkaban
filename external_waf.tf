module "waf" {
  source  = "dwp/waf/aws"
  version = "0.0.4"

  name                  = local.external_name
  s3_log_bucket         = data.terraform_remote_state.security-tools.outputs.logstore_bucket.arn
  s3_log_prefix         = "waf/${local.external_name}"
  whitelist_cidr_blocks = var.whitelist_cidr_blocks

  tags = merge(local.common_tags, { Name = "${local.external_name}-azkaban-external-waf" })
}

resource "aws_wafregional_web_acl_association" "lb" {
  resource_arn = aws_lb.azkaban_external.arn
  web_acl_id   = module.waf.wafregional_web_acl_id
}
