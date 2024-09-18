resource "aws_iam_user" "github_action_app" {
  name = "github-action-app"
}

resource "aws_iam_policy" "github-action-app" {
  name = "github-action-app-policy"
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "GetAuthorizationToken",
        "Effect": "Allow",
        "Action": [
          "ecr:GetAuthorizationToken"
        ],
        "Resource": "*"
      },
      {
        "Sid": "AllowPushPull",
        "Effect": "Allow",
        "Action": [
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:CompleteLayerUpload",
          "ecr:GetDownloadUrlForLayer",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart"
        ],
        "Resource": var.repository_arn
      },
      {
        "Sid":"RegisterTaskDefinition",
        "Effect":"Allow",
        "Action":[
          "ecs:RegisterTaskDefinition"
        ],
        "Resource":"*"
      },
      {
        "Sid":"PassRolesInTaskDefinition",
        "Effect":"Allow",
        "Action":[
          "iam:PassRole"
        ],
        "Resource":[
          var.ecs_task_role_arn,
          var.ecs_task_execution_role_arn
        ]
      },
      {
        "Sid":"DeployService",
        "Effect":"Allow",
        "Action":[
          "ecs:UpdateService",
          "ecs:DescribeServices"
        ],
        "Resource":[
          var.ecs_service_arn
        ]
      }
    ]
  })
}

resource "aws_iam_user_policy_attachment" "github-action-app" {
  policy_arn = aws_iam_policy.github-action-app.arn
  user       = aws_iam_user.github_action_app.name
}