output "ecs_task_definition_arn" {
  description = "The ARN of the ECS task definition"
  value       = aws_ecs_task_definition.this.arn
}

output "ecs_task_role_arn" {
  description = "The ARN of the ECS Task IAM Role"
  value       = aws_iam_role.ecs_task_execution.arn
}

output "task_definition_arn" {
  value = aws_ecs_task_definition.this.arn
}
