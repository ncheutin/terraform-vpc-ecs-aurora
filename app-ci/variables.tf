variable "repository_arn" {
  type = string
  description = "ECR repository ARN"
}

variable "ecs_service_arn" {
  type = string
}

variable "ecs_task_role_arn" {
  type = string
}

variable "ecs_task_execution_role_arn" {
  type = string
}