# ------------------------------------------------------------
# Input variables for the Lambda Proxies module
# ------------------------------------------------------------

variable "function_name" {
  description = "Name of the Lambda function"
  type        = string
  default     = "external-api-proxy"
}

variable "handler" {
  description = "Handler for the Lambda function"
  type        = string
  default     = "lambda_function.lambda_handler"
}

variable "runtime" {
  description = "Runtime for the Lambda function"
  type        = string
  default     = "python3.12"
}

variable "package_filename" {
  description = "Path to the deployment package ZIP"
  type        = string
  default     = "lambda.zip"
}

variable "timeout" {
  description = "Function timeout in seconds"
  type        = number
  default     = 30
}

variable "memory_size" {
  description = "Function memory in MB"
  type        = number
  default     = 128
}

variable "subnet_ids" {
  description = "Subnets for Lambda VPC configuration"
  type        = list(string)
  default     = []
}

variable "security_group_ids" {
  description = "Security groups for Lambda VPC configuration"
  type        = list(string)
  default     = []
}
