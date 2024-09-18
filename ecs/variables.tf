variable "aws_account_id" {
  type = number
}

variable "aws_region" {
  type = string
}

variable "stack_name" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "desired_count" {
  type = number
  description = "Desired number of tasks at creation"
}

variable "cpu" {
  type = number
  description = "CPU value: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html"
}

variable "memory" {
  type = number
  description = "Memory value: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html"
}

variable "min_capacity" {
  type = number
  description = "Min number of tasks"
}

variable "max_capacity" {
  type = number
  description = "Max number of tasks"
}

variable "deployment_minimum_healthy_percent" {
  type = number
  description = "Lower limit (as a percentage of the service's desiredCount) of the number of running tasks that must remain running and healthy in a service during a deployment"
}

variable "deployment_maximum_percent" {
  type = number
  description = "Upper limit (as a percentage of the service's desiredCount) of the number of running tasks that can be running in a service during a deployment"
  default = 200
}

variable "container_port" {
  type = number
}

variable "db_port" {
  type = number
}

variable "container_image" {
  description = "Docker image to be launched"
}

variable "subnets" {
  description = "List of subnet IDs"
}

variable "ecs_service_security_groups" {
  description = "Comma separated list of security groups"
}

variable "aws_alb_target_group_arn" {
  description = "ARN of the alb target group"
}

variable "container_secrets_arns" {
  description = "ARN for secrets"
}

variable "container_secrets" {
  description = "The container secret environment variables"
  type        = list(string)
}

variable "cloudwatch_log_group_retention_in_days" {
  type = number
  default = 90
}