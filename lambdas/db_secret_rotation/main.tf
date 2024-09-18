data "aws_region" "current" {}
data "aws_partition" "current" {}
data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "secrets_manager_db_rotation_single_user_role_policy" {
  statement {
    actions = [
      "ec2:CreateNetworkInterface",
      "ec2:DeleteNetworkInterface",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DetachNetworkInterface",
    ]
    resources = ["*",]
  }
  statement {
    actions = [
      "secretsmanager:DescribeSecret",
      "secretsmanager:GetSecretValue",
      "secretsmanager:PutSecretValue",
      "secretsmanager:UpdateSecretVersionStage",
    ]
    resources = [
      var.secret_arn,
    ]
  }
  statement {
    actions = ["secretsmanager:GetRandomPassword"]
    resources = ["*",]
  }
}

resource "aws_iam_policy" "secrets_manager_db_rotation_single_user_role_policy" {
  name   = "${var.name}-sm-db-rotation-single-user-role-policy"
  path   = "/"
  policy = data.aws_iam_policy_document.secrets_manager_db_rotation_single_user_role_policy.json
  tags = var.tags
}

resource "aws_lambda_permission" "allow_secret_manager_call_lambda" {
  function_name = aws_lambda_function.rotate_code_db.function_name
  statement_id  = "AllowExecutionSecretManager"
  action        = "lambda:InvokeFunction"
  principal     = "secretsmanager.amazonaws.com"
}

resource "aws_iam_policy_attachment" "secrets_manager_db_rotation_single_user_role_policy" {
  name       = "${var.name}-sm-db-rotation-single-user-role-policy"
  roles = [aws_iam_role.lambda_rotation.name]
  policy_arn = aws_iam_policy.secrets_manager_db_rotation_single_user_role_policy.arn
}

resource "aws_iam_role" "lambda_rotation" {
  name               = "${var.name}-lambda-rotation"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  tags = var.tags
}

resource "aws_iam_policy" "lambda_logging" {
  name        = "${var.name}-lambda-logging"
  path        = "/"
  description = "IAM policy for logging from a lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_rotation.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}

resource "aws_security_group" "rotation_lambda_sg" {
  vpc_id = var.vpc_id
  name   = "${var.name}-db-rotation-lambda-sg"

  egress {
    from_port = 0
    protocol  = "-1"
    to_port   = 0
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  tags = var.tags
}

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${path.module}/script/db_secret_rotation.py"
  output_path = "${path.module}/script/lambda_function_payload.zip"
}

resource "aws_lambda_function" "rotate_code_db" {
  filename         = "${path.module}/script/lambda_function_payload.zip"
  function_name    = "${var.name}-db-rotation-lambda"
  role             = aws_iam_role.lambda_rotation.arn
  handler          = "lambda_function.lambda_handler"
  source_code_hash = data.archive_file.lambda.output_base64sha256
  runtime          = "python3.9"
  vpc_config {
    subnet_ids = var.subnet_ids
    security_group_ids = [aws_security_group.rotation_lambda_sg.id]
  }
  timeout     = 30
  description = "Conducts an AWS SecretsManager secret rotation for DB using single user rotation scheme"
  environment {
    variables = {
      SECRETS_MANAGER_ENDPOINT = "https://secretsmanager.${data.aws_region.current.name}.amazonaws.com"
    }
  }
  tags = var.tags
}

resource "aws_secretsmanager_secret_rotation" "this" {
  secret_id           = var.secret_id
  rotation_lambda_arn = aws_lambda_function.rotate_code_db.arn

  rotation_rules {
    automatically_after_days = var.rotation_frequency_in_days
  }
}
