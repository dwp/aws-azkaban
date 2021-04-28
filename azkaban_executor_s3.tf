data template_file "azkaban_executor_properties" {
  template = file("${path.module}/config/azkaban/exec-server/azkaban.properties")
  vars = {
    db_host                    = aws_rds_cluster.azkaban_database.endpoint
    db_port                    = aws_rds_cluster.azkaban_database.port
    azkaban_webserver_hostname = "azkaban-webserver.${local.service_discovery_fqdn}"
    environment                = local.environment
  }
}

data template_file "azkaban_executor_start" {
  template = file("${path.module}/config/azkaban/exec-server/start-exec.sh")
}

data template_file "azkaban_executor_commonprivate" {
  template = file("${path.module}/config/azkaban/exec-server/commonprivate.properties")
}

data template_file "azkaban_executor_private" {
  template = file("${path.module}/config/azkaban/exec-server/private.properties")
}

data template_file "azkaban_executor_internal" {
  template = file("${path.module}/config/azkaban/exec-server/internal-start-executor.sh")
  vars = {
    azkaban_executor_port      = jsondecode(data.aws_secretsmanager_secret_version.workflow_manager.secret_binary).ports.azkaban_executor_port
    azkaban_webserver_hostname = "azkaban-webserver.${local.service_discovery_fqdn}"
    azkaban_webserver_port     = jsondecode(data.aws_secretsmanager_secret_version.workflow_manager.secret_binary).ports.azkaban_webserver_port
    admin_username             = jsondecode(data.aws_secretsmanager_secret_version.workflow_manager.secret_binary).azkaban_username
    admin_password             = jsondecode(data.aws_secretsmanager_secret_version.workflow_manager.secret_binary).azkaban_password
  }
}

resource "aws_s3_bucket_object" "azkaban_executor_properties" {
  bucket     = data.terraform_remote_state.common.outputs.config_bucket.id
  key        = "${local.name}/azkaban/exec-server/azkaban.properties"
  content    = data.template_file.azkaban_executor_properties.rendered
  kms_key_id = data.terraform_remote_state.common.outputs.config_bucket_cmk.arn
}

resource "aws_s3_bucket_object" "azkaban_executor_start" {
  bucket     = data.terraform_remote_state.common.outputs.config_bucket.id
  key        = "${local.name}/azkaban/exec-server/start-exec.sh"
  content    = data.template_file.azkaban_executor_start.rendered
  kms_key_id = data.terraform_remote_state.common.outputs.config_bucket_cmk.arn
}

resource "aws_s3_bucket_object" "azkaban_executor_commonprivate" {
  bucket     = data.terraform_remote_state.common.outputs.config_bucket.id
  key        = "${local.name}/azkaban/exec-server/commonprivate.properties"
  content    = data.template_file.azkaban_executor_commonprivate.rendered
  kms_key_id = data.terraform_remote_state.common.outputs.config_bucket_cmk.arn
}

resource "aws_s3_bucket_object" "azkaban_executor_private" {
  bucket     = data.terraform_remote_state.common.outputs.config_bucket.id
  key        = "${local.name}/azkaban/exec-server/private.properties"
  content    = data.template_file.azkaban_executor_private.rendered
  kms_key_id = data.terraform_remote_state.common.outputs.config_bucket_cmk.arn
}

resource "aws_s3_bucket_object" "azkaban_executor_internal" {
  bucket     = data.terraform_remote_state.common.outputs.config_bucket.id
  key        = "${local.name}/azkaban/exec-server/internal-start-executor.sh"
  content    = data.template_file.azkaban_executor_internal.rendered
  kms_key_id = data.terraform_remote_state.common.outputs.config_bucket_cmk.arn
}

resource "aws_s3_bucket_object" "azkaban_executor_script" {
  bucket     = data.terraform_remote_state.common.outputs.config_bucket.id
  key        = "${local.name}/azkaban/step.sh"
  content    = file("${path.module}/config/azkaban/step.sh")
  kms_key_id = data.terraform_remote_state.common.outputs.config_bucket_cmk.arn
}
