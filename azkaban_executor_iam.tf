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

resource "aws_iam_role_policy_attachment" "azkaban_executor_logs_attachment" {
  role       = aws_iam_role.azkaban_executor.name
  policy_arn = aws_iam_policy.azkaban_executor_logs.arn
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

resource "aws_iam_policy" "azkaban_executor_logs" {
  name        = "AzkabanExecutorLogsPolicy"
  description = "Allow Azkaban executor to interact with CloudWatch logs api"
  policy      = data.aws_iam_policy_document.azkaban_executor_logs.json
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
      data.terraform_remote_state.common.outputs.config_bucket.arn,
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:GetObject",
    ]

    resources = [
      "${data.terraform_remote_state.common.outputs.config_bucket.arn}/${local.name}/azkaban/*",
      "${data.terraform_remote_state.common.outputs.config_bucket.arn}/${local.name}/azkaban_external/*",
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "kms:Decrypt",
    ]

    resources = [
      data.terraform_remote_state.common.outputs.config_bucket_cmk.arn,
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
      "elasticmapreduce:ModifyCluster",
      "elasticmapreduce:CancelSteps",
      "elasticmapreduce:ListInstances",
      "elasticmapreduce:DescribeStep",
    ]

    resources = [
      "*",
    ]
  }
}

data "aws_iam_policy_document" "azkaban_executor_logs" {
  statement {
    effect = "Allow"

    actions = [
      "logs:GetLogEvents",
      "logs:DescribeLogStreams",
    ]

    resources = [
      "*",
    ]
  }
}

resource "aws_iam_role" "aws_analytical_env_cognito_read_only_role" {
  provider           = aws.management
  name               = "azkaban-executor-read-only-cognito-${local.environment}"
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
  name        = "AzkabanExecutorCognitoReadOnlyPolicy${title(local.environment)}"
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

resource "aws_iam_policy" "azkaban_executor_read_secret" {
  name        = "AzkabanExecutorReadSecretPolicy"
  description = "Allow Azkaban executor to read from secrets manager"
  policy      = data.aws_iam_policy_document.azkaban_executor_read_secret.json
}

resource "aws_iam_role_policy_attachment" "azkaban_executor_read_secret_attachment" {
  policy_arn = aws_iam_policy.azkaban_executor_read_secret.arn
  role       = aws_iam_role.azkaban_executor.name
}

data "aws_iam_policy_document" "azkaban_executor_read_secret" {
  statement {
    effect = "Allow"

    actions = [
      "secretsmanager:DescribeSecret",
      "secretsmanager:GetSecretValue",
      "secretsmanager:ListSecretVersionIds"
    ]

    resources = [
      data.aws_secretsmanager_secret.workflow_secret.arn,
      aws_secretsmanager_secret.azkaban_executor_password.arn,
      data.aws_secretsmanager_secret.azkaban_external.arn,
      aws_secretsmanager_secret.azkaban_external_executor_password.arn
    ]
  }
}

data "aws_iam_policy_document" "azkaban_executor_execute_launcher" {
  statement {
    effect = "Allow"

    actions = [
      "lambda:InvokeFunction",
    ]

    resources = [
      data.terraform_remote_state.aws_analytical_env_app.outputs.emr_launcher_lambda.arn,
      data.terraform_remote_state.aws_clive.outputs.aws_clive_emr_launcher_lambda.arn,
      data.terraform_remote_state.dataworks_aws_mongo_latest.outputs.mongo_latest_emr_launcher_lambda.arn,
      data.terraform_remote_state.aws_pdm_dataset_generation.outputs.pdm_emr_launcher_lambda.arn,
    ]
  }
}

resource "aws_iam_role_policy" "azkaban_executor_execute_launcher_policy" {
  name = "azkaban_executor_execute_launcher_policy"
  role = aws_iam_role.azkaban_executor.id

  policy = data.aws_iam_policy_document.azkaban_executor_execute_launcher.json
}

data "aws_iam_policy_document" "azkaban_executor_read_dynamo_db" {
  statement {
    effect = "Allow"

    actions = [
      "dynamodb:GetItem",
      "dynamodb:Scan",
      "dynamodb:GetRecords",
      "dynamodb:Query",
      "dynamodb:UpdateItem",
      "dynamodb:PutItem",
    ]

    resources = [
      data.terraform_remote_state.aws_internal_compute.outputs.uc_export_crown_dynamodb_table.arn,
      data.terraform_remote_state.aws_internal_compute.outputs.data_pipeline_metadata_dynamo.arn,
    ]
  }
}

resource "aws_iam_role_policy" "azkaban_executor_read_dynamo_db_policy" {
  name = "azkaban_executor_read_dynamo_db_policy"
  role = aws_iam_role.azkaban_executor.id

  policy = data.aws_iam_policy_document.azkaban_executor_read_dynamo_db.json
}

data "aws_iam_policy_document" "azkaban_executor_post_sns" {
  statement {
    effect = "Allow"

    actions = [
      "sns:Publish",
    ]

    resources = [
      data.terraform_remote_state.security-tools.outputs.sns_topic_london_monitoring.arn,
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "sns:ListTopics",
    ]

    resources = [
      "*"
    ]
  }
}

resource "aws_iam_role_policy" "azkaban_executor_post_sns_policy" {
  name = "azkaban_executor_post_sns_policy"
  role = aws_iam_role.azkaban_executor.id

  policy = data.aws_iam_policy_document.azkaban_executor_post_sns.json
}
