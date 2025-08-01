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
