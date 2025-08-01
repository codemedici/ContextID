# ------------------------------------------------------------
# Input variables for the DEV environment
# Adjust these defaults to suit sandbox requirements
# ------------------------------------------------------------

# AWS region
variable "aws_region" {
  description = "AWS region for dev deployments"
  type        = string
  default     = "us-east-1"
}

# Network settings
variable "vpc_cidr" {
  description = "CIDR block for the dev VPC"
  type        = string
  default     = "10.10.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.10.0.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.10.1.0/24"]
}

variable "isolated_subnet_cidrs" {
  description = "CIDR blocks for isolated subnets"
  type        = list(string)
  default     = ["10.10.2.0/24"]
}

variable "tags" {
  description = "Common tags applied to resources"
  type        = map(string)
  default = {
    Environment = "dev"
    Project     = "ContextID"
  }
}

# ECS settings
variable "cluster_name" {
  description = "ECS cluster name"
  type        = string
  default     = "dev-llm-cluster"
}

variable "privileged_llm_image" {
  description = "Container image for the privileged LLM"
  type        = string
  default     = "123456789012.dkr.ecr.us-east-1.amazonaws.com/privileged-llm:dev"
}

variable "quarantined_llm_image" {
  description = "Container image for the quarantined LLM"
  type        = string
  default     = "123456789012.dkr.ecr.us-east-1.amazonaws.com/quarantined-llm:dev"
}

variable "desired_count" {
  description = "Number of ECS tasks to run"
  type        = number
  default     = 1
}

variable "min_capacity" {
  description = "Minimum number of tasks for autoscaling"
  type        = number
  default     = 1
}

variable "max_capacity" {
  description = "Maximum number of tasks for autoscaling"
  type        = number
  default     = 2
}

# Database settings
variable "db_identifier" {
  description = "Identifier for the dev PostgreSQL instance"
  type        = string
  default     = "contextid-dev-db"
}

variable "db_username" {
  description = "Database admin username (use secrets in production)"
  type        = string
  default     = "devadmin"
}

variable "db_password" {
  description = "Database admin password (use Secrets Manager in production)"
  type        = string
  default     = "dev-change-me"
}

variable "db_subnet_group_name" {
  description = "Subnet group name for the RDS instance"
  type        = string
  default     = "dev-db-subnet-group"
}

variable "db_kms_key_arn" {
  description = "KMS key ARN for encrypting the database"
  type        = string
  default     = "arn:aws:kms:us-east-1:123456789012:key/dev-example"
}

# OpenSearch settings
variable "os_domain_name" {
  description = "Name of the OpenSearch domain"
  type        = string
  default     = "contextid-dev-search"
}

variable "os_kms_key_arn" {
  description = "KMS key ARN for encrypting the OpenSearch domain"
  type        = string
  default     = "arn:aws:kms:us-east-1:123456789012:key/dev-example"
}

# Lambda proxy settings
variable "function_name" {
  description = "Name of the Lambda proxy function"
  type        = string
  default     = "dev-external-api-proxy"
}

# API Gateway settings
variable "api_name" {
  description = "Name of the API Gateway REST API"
  type        = string
  default     = "contextid-api-dev"
}

variable "stage_name" {
  description = "Deployment stage name"
  type        = string
  default     = "dev"
}

variable "authorizer_invoke_arn" {
  description = "Invoke ARN of the Lambda authorizer"
  type        = string
  default     = "arn:aws:lambda:us-east-1:123456789012:function:dev-authorizer"
}
