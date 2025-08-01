# ------------------------------------------------------------
# Output values for the API Gateway module
# ------------------------------------------------------------

output "rest_api_id" {
  description = "ID of the REST API"
  value       = aws_api_gateway_rest_api.this.id
}

output "authorizer_id" {
  description = "ID of the Lambda authorizer"
  value       = aws_api_gateway_authorizer.did.id
}

output "invoke_url" {
  description = "Base invoke URL for the API stage"
  value       = aws_api_gateway_stage.this.invoke_url
}

output "api_log_group_name" {
  description = "CloudWatch log group for API Gateway access logs"
  value       = aws_cloudwatch_log_group.api.name
}
