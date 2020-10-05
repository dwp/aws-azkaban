data "aws_caller_identity" "current" {}

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

resource "aws_iam_role_policy_attachment" "azkaban_executor_emr_attachment" {
  role       = aws_iam_role.azkaban_executor.name
  policy_arn = aws_iam_policy.azkaban_executor_emr.arn
}

resource "aws_iam_role_policy_attachment" "azkaban_executor_assume_cognito_role_attachment" {
  role       = aws_iam_role.azkaban_executor.name
  policy_arn = aws_iam_policy.azkaban_executor_assume_cognito_role.arn
}

resource "aws_iam_policy" "azkaban_executor_read_config" {
  name        = "AzkabanExecutorReadConfigPolicy"
  description = "Allow Azkaban executor to read from config bucket"
  policy      = data.aws_iam_policy_document.azkaban_executor_read_config.json
}

resource "aws_iam_policy" "azkaban_executor_emr" {
  name        = "AzkabanExecutorEMRPolicy"
  description = "Allow Azkaban executor to interact with EMR api"
  policy      = data.aws_iam_policy_document.azkaban_executor_emr.json
}

resource "aws_iam_policy" "azkaban_executor_assume_cognito_role" {
  name        = "AzkabanExecutorCognitoPolicy"
  description = "Allow Azkaban executor to interact with cognito api"
  policy      = data.aws_iam_policy_document.azkaban_executor_assume_cognito_role.json
}

data "aws_iam_policy_document" "azkaban_executor_assume_cognito_role" {
  statement {
    sid    = "AllowAzkabanExecutorAssumeReadOnlyCognitoRole"
    effect = "Allow"
    actions = [
      "sts:AssumeRole"
    ]
    resources = [aws_iam_role.aws_analytical_env_cognito_read_only_role.arn]
  }
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

data "aws_iam_policy_document" "azkaban_executor_emr" {
  statement {
    effect = "Allow"

    actions = [
      "elasticmapreduce:AddJobFlowSteps",
      "elasticmapreduce:ListClusters",
      "elasticmapreduce:ListSteps",
      "elasticmapreduce:DescribeCluster",
    ]

    resources = [
      "*",
    ]
  }
}

provider "aws" {
  alias = "management"

  region  = "eu-west-2"
  version = ">= 2.66.0"

  assume_role {
    role_arn = "arn:aws:iam::${local.account[local.management_account[local.environment]]}:role/${var.assume_role}"
  }
}

resource "aws_iam_role" "aws_analytical_env_cognito_read_only_role" {
  provider           = aws.management
  name               = "azkaban-executor-read-only-cognito"
  assume_role_policy = data.aws_iam_policy_document.assume_role_cross_acount.json

  tags = merge(local.common_tags, {
    Name = "azkaban-executor-read-cognito"
  })
}

data "aws_iam_policy_document" "assume_role_cross_acount" {
  statement {
    sid     = "AllowAzkabanExecutorCrossAccountAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      identifiers = [data.aws_caller_identity.current.account_id]
      type        = "AWS"
    }
  }
}

resource "aws_iam_policy" "aws_analytical_env_cognito_read_only" {
  provider    = aws.management
  name        = "AzkabanExecutorCognitoReadOnlyPolicy"
  description = "Allow Azkaban executor to interact with cognito api"
  policy      = data.aws_iam_policy_document.aws_analytical_env_cognito_read_only.json
}

resource "aws_iam_role_policy_attachment" "aws_analytical_env_cognito_read_only_attachment" {
  provider   = aws.management
  policy_arn = aws_iam_policy.aws_analytical_env_cognito_read_only.arn
  role       = aws_iam_role.aws_analytical_env_cognito_read_only_role.name
}

data "aws_iam_policy_document" "aws_analytical_env_cognito_read_only" {
  statement {
    effect = "Allow"

    actions = [
      "cognito-idp:ListGroups",
      "cognito-idp:GetGroup",
      "cognito-idp:ListUsers",
      "cognito-idp:ListUsersInGroup",
    ]

    resources = [
      data.terraform_remote_state.aws_analytical_environment_cognito.outputs.cognito.user_pool_arn
    ]
  }
}
