terraform {
  required_version = ">= 1.3"
}

# ------------------------------------------------------------
# Lambda Proxies module
# ------------------------------------------------------------
# Defines Lambda functions used as secure API proxies for interacting
# with external services. Functions run inside the VPC to leverage
# security controls and auditing. Customize the IAM role, runtime,
# and network configuration before deployment.
# ------------------------------------------------------------

data "aws_region" "current" {}

# IAM role assumed by Lambda functions
resource "aws_iam_role" "lambda" {
  name               = "lambda-proxy-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

# Basic execution role for writing logs
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "aws_iam_policy_document" "lambda_assume" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

# Example Lambda function acting as an API proxy
# CloudWatch log group for the function
resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = var.log_retention_in_days
}

# Example Lambda function acting as an API proxy
resource "aws_lambda_function" "proxy" {
  function_name = var.function_name
  role          = aws_iam_role.lambda.arn
  handler       = var.handler
  runtime       = var.runtime
  filename      = var.package_filename # TODO: provide deployment package
  timeout       = var.timeout
  memory_size   = var.memory_size

  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = var.security_group_ids
  }

  environment {
    variables = var.environment_variables
  }

  tracing_config {
    mode = "Active"
  }

  depends_on = [aws_iam_role_policy_attachment.lambda_logs]
}
