# To remove unnecessary costs while testing, removing this key
#resource "aws_kms_key" "ecs" {
#  description         = "${var.stack_name} ECS cluster key"
#  enable_key_rotation = true
#}

resource "aws_ecs_cluster" "this" {
  name = var.stack_name

  #  configuration {
  #    execute_command_configuration {
  #      kms_key_id = aws_kms_key.ecs.arn
  #    }
  #  }
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "${var.stack_name}-app-group"
  retention_in_days = var.cloudwatch_log_group_retention_in_days

  tags = var.tags
}

resource "aws_cloudwatch_log_stream" "this" {
  log_group_name = aws_cloudwatch_log_group.this.name
  name           = "${var.stack_name}-app-stream"
}

resource "aws_ecs_task_definition" "this" {
  container_definitions = jsonencode([
    {
      name      = "${var.stack_name}-app"
      image     = "${var.container_image}:latest"
      essential = true
      cpu       = var.cpu
      memory    = var.memory
      secrets   = var.container_secrets

      portMappings = [
        {
          protocol      = "tcp"
          containerPort = var.container_port
          hostPort      = var.container_port
        }, {
          protocol      = "tcp"
          containerPort = var.db_port
          hostPort      = var.db_port
        }
      ]

      logConfiguration : {
        logDriver : "awslogs",
        options : {
          awslogs-group : aws_cloudwatch_log_group.this.name,
          awslogs-region : var.aws_region,
          awslogs-stream-prefix : aws_cloudwatch_log_stream.this.name
        }
      }
    }
  ])
  cpu                      = var.cpu
  memory                   = var.memory
  family                   = var.stack_name
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  tags = var.tags
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "ecs-task-execution"
  assume_role_policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        Action : "sts:AssumeRole",
        Principal : {
          Service : "ecs-tasks.amazonaws.com"
        },
        Effect : "Allow",
        Sid : ""
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role" "ecs_task_role" {
  name = "${var.stack_name}-ecsTaskRole"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "logs" {
  name        = "${var.stack_name}-task-policy-logs"
  description = "Policy that allows access to Cloudwatch logs"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ],
        "Resource" : [
          "arn:aws:logs:*:*:*"
        ]
      }
    ]
  })
}

#resource "aws_iam_policy" "secrets" {
#  name        = "${var.stack_name}-task-policy-secrets"
#  description = "Policy that allows access to the secrets we created"
#
#  policy = jsonencode({
#    "Version": "2012-10-17",
#    "Statement": [
#      {
#        "Sid": "AccessSecrets",
#        "Effect": "Allow",
#        "Action": [
#          "secretsmanager:GetSecretValue"
#        ],
#        "Resource": var.container_secrets_arns
#      }
#    ]
#  })
#}

resource "aws_iam_role_policy_attachment" "ecs-task-execution-role-policy-attachment" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "ecs-task-role-policy-logs-attachment" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.logs.arn
}

resource "aws_ecs_service" "this" {
  name                               = "${var.stack_name}-service"
  cluster                            = aws_ecs_cluster.this.id
  task_definition                    = aws_ecs_task_definition.this.arn
  desired_count                      = var.desired_count
  deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent
  deployment_maximum_percent         = var.deployment_maximum_percent
  health_check_grace_period_seconds  = 60
  launch_type                        = "FARGATE"
  scheduling_strategy                = "REPLICA"

  network_configuration {
    security_groups  = var.ecs_service_security_groups
    subnets          = var.subnets.*.id
    assign_public_ip = false
  }

  load_balancer {
    container_name   = "${var.stack_name}-app"
    container_port   = var.container_port
    target_group_arn = var.aws_alb_target_group_arn
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [task_definition, desired_count]
  }
}

resource "aws_appautoscaling_target" "ecs_target" {
  max_capacity       = var.max_capacity
  min_capacity       = var.min_capacity
  resource_id        = "service/${aws_ecs_cluster.this.name}/${aws_ecs_service.this.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}


resource "aws_appautoscaling_policy" "ecs_policy_memory" {
  name               = "memory-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }

    target_value       = 80
    scale_in_cooldown  = 300
    scale_out_cooldown = 300
  }
}

resource "aws_appautoscaling_policy" "ecs_policy_cpu" {
  name               = "cpu-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value       = 60
    scale_in_cooldown  = 300
    scale_out_cooldown = 300
  }
}