data template_file "azkaban_external_executor_properties" {
  template = file("${path.module}/config/azkaban_external/exec-server/azkaban.properties")
  vars = {
    db_host                             = aws_rds_cluster.azkaban_database.endpoint
    db_port                             = aws_rds_cluster.azkaban_database.port
    azkaban_external_webserver_hostname = "azkaban-external-webserver.${local.service_discovery_fqdn}"
    environment                         = local.environment
  }
}

data template_file "azkaban_external_executor_internal" {
  template = file("${path.module}/config/azkaban_external/exec-server/internal-start-executor.sh")
  vars = {
    azkaban_external_executor_port      = jsondecode(data.aws_secretsmanager_secret_version.workflow_manager.secret_binary).ports.azkaban_external_executor_port
    azkaban_external_webserver_hostname = "azkaban-external-webserver.${local.service_discovery_fqdn}"
    azkaban_external_webserver_port     = jsondecode(data.aws_secretsmanager_secret_version.workflow_manager.secret_binary).ports.azkaban_external_webserver_port
    admin_username                      = jsondecode(data.aws_secretsmanager_secret_version.workflow_manager.secret_binary).azkaban_username
    admin_password                      = jsondecode(data.aws_secretsmanager_secret_version.workflow_manager.secret_binary).azkaban_password
  }
}

resource "aws_s3_bucket_object" "azkaban_external_executor_internal" {
  bucket     = data.terraform_remote_state.common.outputs.config_bucket.id
  key        = "${local.name}/azkaban_external/exec-server/internal-start-executor.sh"
  content    = data.template_file.azkaban_executor_internal.rendered
  kms_key_id = data.terraform_remote_state.common.outputs.config_bucket_cmk.arn
}
