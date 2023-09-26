resource "aws_iam_policy" "analytical_env_support_azkaban_getsecrets" {
  name        = "AzkabanGetSecrets"
  description = "Allow AnalyticalEnvSupport to get Azkaban secrets"
  policy      = data.aws_iam_policy_document.analytical_env_support_azkaban_getsecrets.json
}

data "aws_iam_policy_document" "analytical_env_support_azkaban_getsecrets" {
  statement {
    effect = "Allow"

    actions = [
      "secretsmanager:DescribeSecret",
      "secretsmanager:GetSecretValue",
      "secretsmanager:ListSecretVersionIds"
    ]

    resources = [
      data.aws_secretsmanager_secret.workflow_manager.arn,
    ]
  }
}

resource "aws_iam_role_policy_attachment" "aws_analytical_env_support_role_azkaban_getsecrets" {
  role       = "AnalyticalEnvSupport"
  policy_arn = aws_iam_policy.analytical_env_support_azkaban_getsecrets.arn
}
