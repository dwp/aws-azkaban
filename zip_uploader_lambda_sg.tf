resource "aws_security_group" "azkaban_zip_uploader" {
  name        = "azkaban-zip-uploader"
  description = "Rule to allow API access for Azkaban External"
  vpc_id      = module.workflow_manager_vpc.vpc.id
  tags        = merge(local.common_tags, { Name = "azkaban-zip-uploader" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "allow_access_to_azkaban_api" {
  description              = "Allows API calls to reach Azkaban External Webserver service endpoint."
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = jsondecode(data.aws_secretsmanager_secret_version.azkaban_external.secret_binary).ports.azkaban_webserver_port
  to_port                  = jsondecode(data.aws_secretsmanager_secret_version.azkaban_external.secret_binary).ports.azkaban_webserver_port
  security_group_id        = aws_security_group.azkaban_zip_uploader.id
  source_security_group_id = aws_security_group.workflow_manager_common.id
}
