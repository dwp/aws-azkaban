data template_file "azkaban_external_webserver_properties" {
  template = file("${path.module}/config/azkaban_external/web-server/azkaban.properties")
  vars = {
    db_host                         = aws_rds_cluster.azkaban_database.endpoint
    db_port                         = aws_rds_cluster.azkaban_database.port
    environment                     = local.environment
    azkaban_external_webserver_port = jsondecode(data.aws_secretsmanager_secret_version.workflow_manager.secret_binary).ports.azkaban_external_webserver_port
  }
}

resource "aws_s3_bucket_object" "azkaban_external_webserver_properties" {
  bucket     = data.terraform_remote_state.common.outputs.config_bucket.id
  key        = "${local.name}/azkaban_external/web-server/azkaban.properties"
  content    = data.template_file.azkaban_webserver_properties.rendered
  kms_key_id = data.terraform_remote_state.common.outputs.config_bucket_cmk.arn
}
