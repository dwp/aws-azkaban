resource "aws_iam_role" "azkaban_executor" {
  name               = "azkaban-executor"
  assume_role_policy = data.aws_iam_policy_document.azkaban_executor_assume_role.json
  tags               = merge(local.common_tags, { Name = "azkaban-executor" })
}

data "aws_iam_policy_document" "azkaban_executor_assume_role" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "azkaban_executor_read_config_attachment" {
  role       = aws_iam_role.azkaban_executor.name
  policy_arn = aws_iam_policy.azkaban_executor_read_config.arn
}

resource "aws_iam_policy" "azkaban_executor_read_config" {
  name        = "AzkabanExecutorReadConfigPolicy"
  description = "Allow Azkaban webserver to read from config bucket"
  policy      = data.aws_iam_policy_document.azkaban_executor_read_config.json
}

data "aws_iam_policy_document" "azkaban_executor_read_config" {
  statement {
    effect = "Allow"

    actions = [
      "s3:ListBucket",
    ]

    resources = [
      "${data.terraform_remote_state.common.outputs.config_bucket.arn}",
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:GetObject",
    ]

    resources = [
      "${data.terraform_remote_state.common.outputs.config_bucket.arn}/${local.name}/azkaban/*",
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "kms:Decrypt",
    ]

    resources = [
      "${data.terraform_remote_state.common.outputs.config_bucket_cmk.arn}",
    ]
  }
}
