resource "aws_iam_role" "lambda_zip_uploader" {
  name               = "azkaban_zip_uploader_lambda"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_policy.json
  tags               = local.common_tags
}

resource "aws_iam_role_policy_attachment" "lambda_zip_uploader_vpc_access" {
  role       = aws_iam_role.lambda_zip_uploader.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role_policy" "lambda_zip_uploader" {
  role   = aws_iam_role.lambda_zip_uploader.name
  policy = data.aws_iam_policy_document.lambda_zip_uploader_document.json
}

data "aws_iam_policy_document" "lambda_zip_uploader_document" {
  statement {
    sid    = "AllowGetAzkabanSecrets"
    effect = "Allow"
    actions = [
      "secretsmanager:DescribeSecret",
      "secretsmanager:GetSecretValue",
      "secretsmanager:ListSecretVersionIds"
    ]
    resources = [
      data.aws_secretsmanager_secret.workflow_manager.arn
    ]
  }

  statement {
    sid       = "AllowRdsDataExecute"
    effect    = "Allow"
    actions   = [
      "s3:GetObject",
      "s3:GetObjectAcl"
    ]
    resources = [
      "${data.terraform_remote_state.common.outputs.config_bucket.arn}/workflow-manager/azkaban_uploads/*"
    ]
  }

  statement {
    sid       = "FindConfigBucket"
    effect    = "Allow"
    actions   = [
      "s3:ListBucket"
    ]
    resources = [
      data.terraform_remote_state.common.outputs.config_bucket.arn
    ]
  }

  statement {
    sid     = "UseKmsToReadBucket"
    effect  = "Allow"
    actions = [
      "kms:Decrypt",
    ]
    resources = [
      data.terraform_remote_state.common.outputs.config_bucket_cmk.arn
    ]
  }
}
