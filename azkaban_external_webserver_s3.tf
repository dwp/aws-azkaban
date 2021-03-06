data template_file "azkaban_external_webserver_properties" {
  template = file("${path.module}/config/azkaban_external/web-server/azkaban.properties")
  vars = {
    db_host                         = aws_rds_cluster.azkaban_external_database.endpoint
    db_port                         = aws_rds_cluster.azkaban_external_database.port
    environment                     = local.environment
    azkaban_external_webserver_port = jsondecode(data.aws_secretsmanager_secret_version.azkaban_external.secret_binary).ports.azkaban_webserver_port
  }
}

resource "aws_s3_bucket_object" "azkaban_external_webserver_properties" {
  bucket     = data.terraform_remote_state.common.outputs.config_bucket.id
  key        = "${local.name}/azkaban_external/web-server/azkaban.properties"
  content    = data.template_file.azkaban_external_webserver_properties.rendered
  kms_key_id = data.terraform_remote_state.common.outputs.config_bucket_cmk.arn
}

data template_file "azkaban_external_webserver_start" {
  template = file("${path.module}/config/azkaban_external/web-server/start-web.sh")
}

data template_file "azkaban_external_webserver_internal" {
  template = file("${path.module}/config/azkaban_external/web-server/internal-start-web.sh")
}

data template_file "azkaban_external_webserver_jmx_exporter_config" {
  template = file("${path.module}/config/azkaban_external/web-server/jmx-exporter/config.yml")
}

resource "aws_s3_bucket_object" "azkaban_external_webserver_start" {
  bucket     = data.terraform_remote_state.common.outputs.config_bucket.id
  key        = "${local.name}/azkaban_external/web-server/start-web.sh"
  content    = data.template_file.azkaban_external_webserver_start.rendered
  kms_key_id = data.terraform_remote_state.common.outputs.config_bucket_cmk.arn
}

resource "aws_s3_bucket_object" "azkaban_external_webserver_internal" {
  bucket     = data.terraform_remote_state.common.outputs.config_bucket.id
  key        = "${local.name}/azkaban_external/web-server/internal-start-web.sh"
  content    = data.template_file.azkaban_external_webserver_internal.rendered
  kms_key_id = data.terraform_remote_state.common.outputs.config_bucket_cmk.arn
}

resource "aws_s3_bucket_object" "azkaban_external_webserver_jmx_exporter_config" {
  bucket     = data.terraform_remote_state.common.outputs.config_bucket.id
  key        = "${local.name}/jmx_exporter/web-server/jmx-exporter.yml"
  content    = data.template_file.azkaban_external_webserver_jmx_exporter_config.rendered
  kms_key_id = data.terraform_remote_state.common.outputs.config_bucket_cmk.arn
}
