output "service_arn" {
  value = aws_ecs_service.this.id
}

output "task_role_arn" {
  value = aws_iam_role.ecs_task_role.arn
}

output "task_execution_role_arn" {
  value = aws_iam_role.ecs_task_execution_role.arn
}
