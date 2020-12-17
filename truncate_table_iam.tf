data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    sid    = "LambdaAssumeRolePolicy"
    effect = "Allow"
    actions = [
      "sts:AssumeRole",
    ]
    principals {
      identifiers = [
        "lambda.amazonaws.com",
      ]
      type = "Service"
    }
  }
}

resource "aws_iam_role" "truncate_table" {
  name               = "azkaban_lambda_truncate_table"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
  tags               = local.common_tags
}

resource "aws_iam_role_policy_attachment" "lambda_truncate_table_basic" {
  role       = aws_iam_role.truncate_table.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "aws_iam_policy_document" "lambda_truncate_table" {
  statement {
    sid    = "AllowGetCredentials"
    effect = "Allow"
    actions = [
      "secretsmanager:DescribeSecret",
      "secretsmanager:GetSecretValue",
      "secretsmanager:ListSecretVersionIds"
    ]
    resources = [
      aws_secretsmanager_secret.azkaban_executor_password.arn,
    ]
  }

  statement {
    sid       = "AllowRdsDataExecute"
    effect    = "Allow"
    actions   = ["rds-data:ExecuteStatement"]
    resources = [aws_rds_cluster.azkaban_database.arn]
  }
}

resource "aws_iam_role_policy" "lambda_truncate_table" {
  role   = aws_iam_role.truncate_table.name
  policy = data.aws_iam_policy_document.lambda_truncate_table.json
}
