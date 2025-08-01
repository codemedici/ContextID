# ------------------------------------------------------------
# Input variables for the ECS module
# ------------------------------------------------------------

variable "cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
  default     = "llm-cluster"
}

variable "service_name" {
  description = "ECS service name"
  type        = string
  default     = "llm-service"
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

variable "subnet_ids" {
  description = "Subnets for the ECS service"
  type        = list(string)
  default     = []
}

variable "security_group_ids" {
  description = "Security groups for the ECS service"
  type        = list(string)
  default     = []
}

variable "desired_count" {
  description = "Number of tasks to run"
  type        = number
  default     = 1
}

variable "min_capacity" {
  description = "Minimum tasks for autoscaling"
  type        = number
  default     = 1
}

variable "max_capacity" {
  description = "Maximum tasks for autoscaling"
  type        = number
  default     = 3
}

variable "log_retention_in_days" {
  description = "CloudWatch log retention"
  type        = number
  default     = 30
}
