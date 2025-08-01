# ------------------------------------------------------------
# Output values for the DEV environment
# ------------------------------------------------------------

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.network.vpc_id
}

output "ecs_cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = module.ecs.cluster_arn
}

output "db_endpoint" {
  description = "Endpoint of the PostgreSQL instance"
  value       = module.rds_opensearch.db_endpoint
}

output "opensearch_endpoint" {
  description = "Endpoint of the OpenSearch domain"
  value       = module.rds_opensearch.opensearch_endpoint
}

output "lambda_function_arn" {
  description = "ARN of the Lambda proxy function"
  value       = module.lambda_proxies.lambda_function_arn
}

output "api_invoke_url" {
  description = "Invoke URL for the API Gateway stage"
  value       = module.api_gateway.invoke_url
}
