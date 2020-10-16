data template_file "dummy" {
  template = file("${path.module}/config/azkaban/dummy.sh")
}

data template_file "example_job_flow" {
  template = file("${path.module}/config/azkaban/example_job/example_job.flow")
}

data template_file "example_job_project" {
  template = file("${path.module}/config/azkaban/example_job/example_job.project")
}

data template_file "workflow_submit_step" {
  template = file("${path.module}/config/azkaban/example_job/submit_step.sh")
  vars = {
    config_bucket = data.terraform_remote_state.common.outputs.config_bucket.id
  }
}

data "archive_file" "example_job" {
  type        = "zip"
  output_path = "${path.module}/config/azkaban/example-workflow.zip"

  source {
    content  = data.template_file.example_job_flow.rendered
    filename = "example_job.flow"
  }

  source {
    content  = data.template_file.example_job_project.rendered
    filename = "example_job.project"
  }

  source {
    content  = data.template_file.workflow_submit_step.rendered
    filename = "submit_step.sh"
  }
}

resource "aws_s3_bucket_object" "dummy" {
  bucket     = data.terraform_remote_state.common.outputs.config_bucket.id
  key        = "${local.name}/azkaban/dummy.sh"
  content    = data.template_file.dummy.rendered
  kms_key_id = data.terraform_remote_state.common.outputs.config_bucket_cmk.arn
}

resource "aws_s3_bucket_object" "example_workflow_zip" {
  bucket     = data.terraform_remote_state.common.outputs.config_bucket.id
  key        = "${local.name}/azkaban/example-workflow.zip"
  source     = data.archive_file.example_job.output_path
  kms_key_id = data.terraform_remote_state.common.outputs.config_bucket_cmk.arn
}
