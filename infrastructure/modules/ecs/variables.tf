# ------------------------------------------------------------
# Input variables for the ECS module
# ------------------------------------------------------------

variable "cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
  default     = "llm-cluster"
}

variable "task_cpu" {
  description = "CPU units for the task definition"
  type        = number
  default     = 1024
}

variable "task_memory" {
  description = "Memory (MiB) for the task definition"
  type        = number
  default     = 2048
}

variable "execution_role_arn" {
  description = "IAM role ARN used by ECS to pull images and publish logs"
  type        = string
  default     = "arn:aws:iam::123456789012:role/ecsTaskExecutionRole" # Example
}

variable "task_role_arn" {
  description = "IAM role ARN assumed by the running task"
  type        = string
  default     = "arn:aws:iam::123456789012:role/ecsTaskRole" # Example
}

variable "privileged_llm_image" {
  description = "Container image for the privileged LLM"
  type        = string
  default     = "123456789012.dkr.ecr.us-east-1.amazonaws.com/privileged-llm:latest"
}

variable "quarantined_llm_image" {
  description = "Container image for the quarantined LLM"
  type        = string
  default     = "123456789012.dkr.ecr.us-east-1.amazonaws.com/quarantined-llm:latest"
}
