# ------------------------------------------------------------
# Output values for the RDS & OpenSearch module
# ------------------------------------------------------------

output "db_endpoint" {
  description = "Connection endpoint for the PostgreSQL instance"
  value       = aws_db_instance.postgres.endpoint
}

output "opensearch_endpoint" {
  description = "URL of the OpenSearch domain"
  value       = aws_opensearch_domain.search.endpoint
}

output "data_access_role_arn" {
  description = "IAM role ARN for accessing data stores"
  value       = aws_iam_role.data_access.arn
}
