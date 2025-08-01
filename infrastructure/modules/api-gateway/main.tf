terraform {
  required_version = ">= 1.3"
}

# ------------------------------------------------------------
# API Gateway module
# ------------------------------------------------------------
# Exposes REST endpoints secured by Lambda authorizers that verify
# Decentralized Identifiers (DIDs) and BBS+ selective disclosure
# proofs. The resources here are placeholders and should be expanded
# with full API definitions, stages, and integrations.
# ------------------------------------------------------------

# REST API skeleton
resource "aws_api_gateway_rest_api" "this" {
  name        = var.api_name
  description = "ContextID API"
}

# CloudWatch role for API Gateway logging
resource "aws_iam_role" "api_gw" {
  name               = "apigw-cloudwatch-role"
  assume_role_policy = data.aws_iam_policy_document.apigw_assume.json
}

data "aws_iam_policy_document" "apigw_assume" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["apigateway.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role_policy_attachment" "apigw_logs" {
  role       = aws_iam_role.api_gw.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}

resource "aws_api_gateway_account" "this" {
  cloudwatch_role_arn = aws_iam_role.api_gw.arn
}

resource "aws_cloudwatch_log_group" "api" {
  name              = "/aws/apigateway/${var.api_name}"
  retention_in_days = 30
}

# Lambda authorizer for DID/BBS+ verification
resource "aws_api_gateway_authorizer" "did" {
  name                             = "did-authorizer"
  rest_api_id                      = aws_api_gateway_rest_api.this.id
  authorizer_uri                   = var.authorizer_invoke_arn
  authorizer_result_ttl_in_seconds = 0
  type                             = "REQUEST"
  identity_source                  = "method.request.header.Authorization"
}

# Allow API Gateway to invoke the authorizer
resource "aws_lambda_permission" "authorizer" {
  statement_id  = "AllowAPIGatewayAuthorizer"
  action        = "lambda:InvokeFunction"
  function_name = var.authorizer_invoke_arn
  principal     = "apigateway.amazonaws.com"
}

# Example resource and method invoking a backend Lambda proxy
resource "aws_api_gateway_resource" "resolve" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_rest_api.this.root_resource_id
  path_part   = "resolve"
}

resource "aws_api_gateway_method" "resolve_get" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_resource.resolve.id
  http_method   = "GET"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.did.id
}

resource "aws_api_gateway_integration" "resolve_get" {
  rest_api_id             = aws_api_gateway_rest_api.this.id
  resource_id             = aws_api_gateway_resource.resolve.id
  http_method             = aws_api_gateway_method.resolve_get.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.proxy_lambda_invoke_arn
}

resource "aws_lambda_permission" "proxy" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.proxy_lambda_invoke_arn
  principal     = "apigateway.amazonaws.com"
}

# Deployment of the API
resource "aws_api_gateway_deployment" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id

  depends_on = [
    aws_api_gateway_integration.resolve_get,
    aws_api_gateway_authorizer.did
  ]
}

# Stage exposing the deployment with logging and tracing
resource "aws_api_gateway_stage" "this" {
  rest_api_id          = aws_api_gateway_rest_api.this.id
  deployment_id        = aws_api_gateway_deployment.this.id
  stage_name           = var.stage_name
  xray_tracing_enabled = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api.arn
    format          = "$context.requestId $context.identity.sourceIp $context.httpMethod $context.resourcePath $context.status"
  }
}
