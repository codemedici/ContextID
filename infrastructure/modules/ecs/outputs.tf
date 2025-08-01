# ------------------------------------------------------------
# Output values for the ECS module
# ------------------------------------------------------------

output "cluster_id" {
  description = "ID of the ECS cluster"
  value       = aws_ecs_cluster.this.id
}

output "cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = aws_ecs_cluster.this.arn
}

output "task_definition_arn" {
  description = "ARN of the dual-LLM task definition"
  value       = aws_ecs_task_definition.dual_llm.arn
}

output "service_name" {
  description = "Name of the ECS service"
  value       = aws_ecs_service.this.name
}

output "execution_role_arn" {
  description = "ARN of the task execution role"
  value       = aws_iam_role.execution.arn
}

output "task_role_arn" {
  description = "ARN of the task role"
  value       = aws_iam_role.task.arn
}

output "log_group_name" {
  description = "CloudWatch log group for ECS tasks"
  value       = aws_cloudwatch_log_group.this.name
}
