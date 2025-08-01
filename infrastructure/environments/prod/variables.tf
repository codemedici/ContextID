# ------------------------------------------------------------
# Input variables for the PROD environment
# Defaults reflect production-ready scaling and security
# ------------------------------------------------------------

variable "aws_region" {
  description = "AWS region for prod deployments"
  type        = string
  default     = "us-east-1"
}

# Network settings
variable "vpc_cidr" {
  description = "CIDR block for the prod VPC"
  type        = string
  default     = "10.20.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.20.0.0/24", "10.20.1.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.20.2.0/24", "10.20.3.0/24"]
}

variable "isolated_subnet_cidrs" {
  description = "CIDR blocks for isolated subnets"
  type        = list(string)
  default     = ["10.20.4.0/24", "10.20.5.0/24"]
}

variable "tags" {
  description = "Common tags applied to prod resources"
  type        = map(string)
  default = {
    Environment = "prod"
    Project     = "ContextID"
  }
}

# ECS settings
variable "cluster_name" {
  description = "ECS cluster name"
  type        = string
  default     = "prod-llm-cluster"
}

variable "execution_role_arn" {
  description = "IAM role for ECS task execution"
  type        = string
  default     = "arn:aws:iam::123456789012:role/prod-ecs-execution"
}

variable "task_role_arn" {
  description = "IAM role assumed by ECS tasks"
  type        = string
  default     = "arn:aws:iam::123456789012:role/prod-ecs-task"
}

variable "privileged_llm_image" {
  description = "Container image for the privileged LLM"
  type        = string
  default     = "123456789012.dkr.ecr.us-east-1.amazonaws.com/privileged-llm:prod"
}

variable "quarantined_llm_image" {
  description = "Container image for the quarantined LLM"
  type        = string
  default     = "123456789012.dkr.ecr.us-east-1.amazonaws.com/quarantined-llm:prod"
}

# Database settings
variable "db_identifier" {
  description = "Identifier for the prod PostgreSQL instance"
  type        = string
  default     = "contextid-prod-db"
}

variable "db_username" {
  description = "Database admin username"
  type        = string
  default     = "prodadmin"
}

variable "db_password" {
  description = "Database admin password (use Secrets Manager in production)"
  type        = string
  default     = "prod-change-me"
}

variable "db_subnet_group_name" {
  description = "Subnet group name for the RDS instance"
  type        = string
  default     = "prod-db-subnet-group"
}

variable "db_kms_key_arn" {
  description = "KMS key ARN for encrypting the database"
  type        = string
  default     = "arn:aws:kms:us-east-1:123456789012:key/prod-example"
}

# OpenSearch settings
variable "os_domain_name" {
  description = "Name of the OpenSearch domain"
  type        = string
  default     = "contextid-prod-search"
}

variable "os_kms_key_arn" {
  description = "KMS key ARN for encrypting the OpenSearch domain"
  type        = string
  default     = "arn:aws:kms:us-east-1:123456789012:key/prod-example"
}

# Lambda proxy settings
variable "function_name" {
  description = "Name of the Lambda proxy function"
  type        = string
  default     = "prod-external-api-proxy"
}

# API Gateway settings
variable "api_name" {
  description = "Name of the API Gateway REST API"
  type        = string
  default     = "contextid-api-prod"
}

variable "stage_name" {
  description = "Deployment stage name"
  type        = string
  default     = "prod"
}

variable "authorizer_invoke_arn" {
  description = "Invoke ARN of the Lambda authorizer"
  type        = string
  default     = "arn:aws:lambda:us-east-1:123456789012:function:prod-authorizer"
}
