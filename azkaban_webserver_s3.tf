data "archive_file" "impact_measures" {
  type        = "zip"
  source_dir  = "${path.module}/../impact-measures"
  output_path = "${path.module}/config/azkaban/impact-measures.zip"
}

data template_file "azkaban_webserver_users" {
  template = file("${path.module}/config/azkaban/web-server/azkaban-users.xml")
  vars = {
    admin_username = jsondecode(data.aws_secretsmanager_secret_version.workflow_manager.secret_binary).azkaban_username
    admin_password = jsondecode(data.aws_secretsmanager_secret_version.workflow_manager.secret_binary).azkaban_password
  }
}

data template_file "azkaban_webserver_properties" {
  template = file("${path.module}/config/azkaban/web-server/azkaban.properties")
  vars = {
    db_host                = aws_db_instance.azkaban_database.address
    db_port                = aws_db_instance.azkaban_database.port
    db_name                = jsondecode(data.aws_secretsmanager_secret_version.workflow_manager.secret_binary).db_name
    db_username            = jsondecode(data.aws_secretsmanager_secret_version.workflow_manager.secret_binary).db_username
    db_password            = jsondecode(data.aws_secretsmanager_secret_version.workflow_manager.secret_binary).db_password
    azkaban_webserver_port = jsondecode(data.aws_secretsmanager_secret_version.workflow_manager.secret_binary).ports.azkaban_webserver_port
  }
}

data template_file "azkaban_webserver_log4j" {
  template = file("${path.module}/config/azkaban/web-server/log4j.properties")
}

data template_file "azkaban_webserver_start" {
  template = file("${path.module}/config/azkaban/web-server/start-web.sh")
  vars = {
    db_host     = aws_db_instance.azkaban_database.address
    db_name     = jsondecode(data.aws_secretsmanager_secret_version.workflow_manager.secret_binary).db_name
    db_username = jsondecode(data.aws_secretsmanager_secret_version.workflow_manager.secret_binary).db_username
    db_password = jsondecode(data.aws_secretsmanager_secret_version.workflow_manager.secret_binary).db_password
  }
}

data template_file "azkaban_webserver_commonprivate" {
  template = file("${path.module}/config/azkaban/web-server/commonprivate.properties")
}

data template_file "azkaban_webserver_internal" {
  template = file("${path.module}/config/azkaban/web-server/internal-start-web.sh")
}

resource "aws_s3_bucket_object" "azkaban_webserver_users" {
  bucket     = data.terraform_remote_state.common.outputs.config_bucket.id
  key        = "${local.name}/azkaban/web-server/azkaban-users.xml"
  content    = data.template_file.azkaban_webserver_users.rendered
  kms_key_id = data.terraform_remote_state.common.outputs.config_bucket_cmk.arn
}

resource "aws_s3_bucket_object" "azkaban_webserver_properties" {
  bucket     = data.terraform_remote_state.common.outputs.config_bucket.id
  key        = "${local.name}/azkaban/web-server/azkaban.properties"
  content    = data.template_file.azkaban_webserver_properties.rendered
  kms_key_id = data.terraform_remote_state.common.outputs.config_bucket_cmk.arn
}

resource "aws_s3_bucket_object" "azkaban_webserver_log4j" {
  bucket     = data.terraform_remote_state.common.outputs.config_bucket.id
  key        = "${local.name}/azkaban/web-server/log4j.properties"
  content    = data.template_file.azkaban_webserver_log4j.rendered
  kms_key_id = data.terraform_remote_state.common.outputs.config_bucket_cmk.arn
}

resource "aws_s3_bucket_object" "azkaban_webserver_start" {
  bucket     = data.terraform_remote_state.common.outputs.config_bucket.id
  key        = "${local.name}/azkaban/web-server/start-web.sh"
  content    = data.template_file.azkaban_webserver_start.rendered
  kms_key_id = data.terraform_remote_state.common.outputs.config_bucket_cmk.arn
}

resource "aws_s3_bucket_object" "azkaban_webserver_commonprivate" {
  bucket     = data.terraform_remote_state.common.outputs.config_bucket.id
  key        = "${local.name}/azkaban/web-server/commonprivate.properties"
  content    = data.template_file.azkaban_webserver_commonprivate.rendered
  kms_key_id = data.terraform_remote_state.common.outputs.config_bucket_cmk.arn
}

resource "aws_s3_bucket_object" "azkaban_webserver_internal" {
  bucket     = data.terraform_remote_state.common.outputs.config_bucket.id
  key        = "${local.name}/azkaban/web-server/internal-start-web.sh"
  content    = data.template_file.azkaban_webserver_internal.rendered
  kms_key_id = data.terraform_remote_state.common.outputs.config_bucket_cmk.arn
}

resource "aws_s3_bucket_object" "impact_measures_zip" {
  bucket     = data.terraform_remote_state.common.outputs.config_bucket.id
  key        = "${local.name}/azkaban/impact-measures.zip"
  source     = data.archive_file.impact_measures.output_path
  kms_key_id = data.terraform_remote_state.common.outputs.config_bucket_cmk.arn
}
