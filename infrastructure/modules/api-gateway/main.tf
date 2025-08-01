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

# Lambda authorizer for DID/BBS+ verification
resource "aws_api_gateway_authorizer" "did" {
  name                             = "did-authorizer"
  rest_api_id                      = aws_api_gateway_rest_api.this.id
  authorizer_uri                   = var.authorizer_invoke_arn
  authorizer_result_ttl_in_seconds = 0
  type                             = "REQUEST"
  identity_source                  = "method.request.header.Authorization"
}

# Deployment of the API
resource "aws_api_gateway_deployment" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id

  depends_on = [aws_api_gateway_authorizer.did]
}

# Stage exposing the deployment
resource "aws_api_gateway_stage" "this" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  deployment_id = aws_api_gateway_deployment.this.id
  stage_name    = var.stage_name
}
