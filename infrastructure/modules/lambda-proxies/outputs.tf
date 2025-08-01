# ------------------------------------------------------------
# Output values for the Lambda Proxies module
# ------------------------------------------------------------

output "lambda_function_arn" {
  description = "ARN of the Lambda proxy function"
  value       = aws_lambda_function.proxy.arn
}

output "lambda_role_arn" {
  description = "ARN of the IAM role assumed by the Lambda function"
  value       = aws_iam_role.lambda.arn
}
=======
// Output values for the lambda-proxies module
# TODO: Define module outputs
