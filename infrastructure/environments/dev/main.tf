# ------------------------------------------------------------
# Root Terraform configuration for the DEV environment
# Invokes reusable modules with sandbox-friendly settings
# ------------------------------------------------------------

terraform {
  required_version = ">= 1.3"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Network layer
module "network" {
  source = "../../modules/network"

  vpc_cidr              = var.vpc_cidr
  public_subnet_cidrs   = var.public_subnet_cidrs
  private_subnet_cidrs  = var.private_subnet_cidrs
  isolated_subnet_cidrs = var.isolated_subnet_cidrs
  tags                  = var.tags
}

# ECS cluster hosting dual LLM containers
module "ecs" {
  source                = "../../modules/ecs"
  cluster_name          = var.cluster_name
  privileged_llm_image  = var.privileged_llm_image
  quarantined_llm_image = var.quarantined_llm_image
  subnet_ids            = module.network.private_subnet_ids
  security_group_ids    = [module.network.default_security_group_id]
  desired_count         = var.desired_count
  min_capacity          = var.min_capacity
  max_capacity          = var.max_capacity
}

# PostgreSQL database and OpenSearch domain
module "rds_opensearch" {
  source = "../../modules/rds-opensearch"

  db_identifier         = var.db_identifier
  db_username           = var.db_username
  db_password           = var.db_password
  db_subnet_group_name  = var.db_subnet_group_name
  db_subnet_ids         = module.network.private_subnet_ids
  db_security_group_ids = [module.network.default_security_group_id]
  db_kms_key_arn        = var.db_kms_key_arn

  os_domain_name        = var.os_domain_name
  os_kms_key_arn        = var.os_kms_key_arn
  os_subnet_ids         = module.network.private_subnet_ids
  os_security_group_ids = [module.network.default_security_group_id]
}

# Lambda function used as a secure API proxy
module "lambda_proxies" {
  source = "../../modules/lambda-proxies"

  function_name      = var.function_name
  subnet_ids         = module.network.isolated_subnet_ids
  security_group_ids = [module.network.default_security_group_id]
}

# API Gateway exposing ContextID APIs with DID authorizer
module "api_gateway" {
  source = "../../modules/api-gateway"

  api_name                = var.api_name
  stage_name              = var.stage_name
  authorizer_invoke_arn   = var.authorizer_invoke_arn
  proxy_lambda_invoke_arn = module.lambda_proxies.lambda_function_arn
}
