data template_file "azkaban_executor_users" {
  template = file("${path.module}/config/azkaban/exec-server/azkaban-users.xml")
  vars = {
    admin_username = "azkaban"
    admin_password = "azkaban"
  }
}

data template_file "azkaban_executor_properties" {
  template = file("${path.module}/config/azkaban/exec-server/azkaban.properties")
  vars = {
    db_host                    = aws_db_instance.azkaban_database.address
    db_port                    = aws_db_instance.azkaban_database.port
    db_name                    = jsondecode(data.aws_secretsmanager_secret_version.workflow_manager.secret_binary).db_name
    db_username                = jsondecode(data.aws_secretsmanager_secret_version.workflow_manager.secret_binary).db_username
    db_password                = jsondecode(data.aws_secretsmanager_secret_version.workflow_manager.secret_binary).db_password
    azkaban_executor_port      = jsondecode(data.aws_secretsmanager_secret_version.workflow_manager.secret_binary).ports.azkaban_executor_port
    azkaban_webserver_hostname = "azkaban-webserver.${local.service_discovery_fqdn}"
    azkaban_webserver_port     = jsondecode(data.aws_secretsmanager_secret_version.workflow_manager.secret_binary).ports.azkaban_webserver_port
  }
}

data template_file "azkaban_executor_log4j" {
  template = file("${path.module}/config/azkaban/exec-server/log4j.properties")
}

data template_file "azkaban_executor_start" {
  template = file("${path.module}/config/azkaban/exec-server/start-exec.sh")
}

data template_file "azkaban_executor_internal" {
  template = file("${path.module}/config/azkaban/exec-server/internal-start-executor.sh")
}

resource "aws_s3_bucket_object" "azkaban_executor_users" {
  bucket     = data.terraform_remote_state.common.outputs.config_bucket.id
  key        = "${local.name}/azkaban/exec-server/azkaban-users.xml"
  content    = data.template_file.azkaban_executor_users.rendered
  kms_key_id = data.terraform_remote_state.common.outputs.config_bucket_cmk.arn
}

resource "aws_s3_bucket_object" "azkaban_executor_properties" {
  bucket     = data.terraform_remote_state.common.outputs.config_bucket.id
  key        = "${local.name}/azkaban/exec-server/azkaban.properties"
  content    = data.template_file.azkaban_executor_properties.rendered
  kms_key_id = data.terraform_remote_state.common.outputs.config_bucket_cmk.arn
}

resource "aws_s3_bucket_object" "azkaban_executor_log4j" {
  bucket     = data.terraform_remote_state.common.outputs.config_bucket.id
  key        = "${local.name}/azkaban/exec-server/log4j.properties"
  content    = data.template_file.azkaban_executor_log4j.rendered
  kms_key_id = data.terraform_remote_state.common.outputs.config_bucket_cmk.arn
}

resource "aws_s3_bucket_object" "azkaban_executor_start" {
  bucket     = data.terraform_remote_state.common.outputs.config_bucket.id
  key        = "${local.name}/azkaban/exec-server/start-exec.sh"
  content    = data.template_file.azkaban_executor_start.rendered
  kms_key_id = data.terraform_remote_state.common.outputs.config_bucket_cmk.arn
}

resource "aws_s3_bucket_object" "azkaban_executor_internal" {
  bucket     = data.terraform_remote_state.common.outputs.config_bucket.id
  key        = "${local.name}/azkaban/exec-server/internal-start-executor.sh"
  content    = data.template_file.azkaban_executor_internal.rendered
  kms_key_id = data.terraform_remote_state.common.outputs.config_bucket_cmk.arn
}
