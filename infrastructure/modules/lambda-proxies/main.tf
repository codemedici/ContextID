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

# IAM role assumed by Lambda functions
resource "aws_iam_role" "lambda" {
  name               = "lambda-proxy-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json

  # TODO: attach policies granting least-privilege access to APIs
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

  # TODO: add environment variables, layers, and logging configuration
}
=======
// Placeholder Terraform module for lambda-proxies
terraform {
  required_version = ">= 1.0"
}

# TODO: Define resources for the lambda-proxies module