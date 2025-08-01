# ------------------------------------------------------------
# Input variables for the API Gateway module
# ------------------------------------------------------------

variable "api_name" {
  description = "Name of the API Gateway REST API"
  type        = string
  default     = "contextid-api"
}

variable "stage_name" {
  description = "Deployment stage name"
  type        = string
  default     = "dev"
}

variable "authorizer_invoke_arn" {
  description = "Invoke ARN of the Lambda function used as an authorizer"
  type        = string
  default     = "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:123456789012:function:authorizer/invocations"
}

variable "proxy_lambda_invoke_arn" {
  description = "Invoke ARN of the backend Lambda proxy"
  type        = string
  default     = "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:123456789012:function:proxy/invocations"
}
