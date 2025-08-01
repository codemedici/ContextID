# ------------------------------------------------------------
# Input variables for the RDS & OpenSearch module
# ------------------------------------------------------------

# RDS settings
variable "db_identifier" {
  description = "Identifier for the PostgreSQL instance"
  type        = string
  default     = "contextid-db"
}

variable "db_engine_version" {
  description = "PostgreSQL engine version"
  type        = string
  default     = "15.5"
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.medium"
}

variable "db_allocated_storage" {
  description = "Storage size in GB"
  type        = number
  default     = 20
}

variable "db_username" {
  description = "Master username"
  type        = string
  default     = "admin"
}

variable "db_password" {
  description = "Master password (use Secrets Manager in production)"
  type        = string
  default     = "change-me"
}

variable "db_subnet_group_name" {
  description = "Subnet group for the DB instance"
  type        = string
  default     = "example-subnet-group"
}

variable "db_security_group_ids" {
  description = "Security groups for the DB instance"
  type        = list(string)
  default     = []
}

variable "db_kms_key_arn" {
  description = "KMS key ARN for encrypting the DB"
  type        = string
  default     = "arn:aws:kms:us-east-1:123456789012:key/example"
}

# OpenSearch settings
variable "os_domain_name" {
  description = "Name of the OpenSearch domain"
  type        = string
  default     = "contextid-search"
}

variable "os_engine_version" {
  description = "OpenSearch engine version"
  type        = string
  default     = "OpenSearch_2.13"
}

variable "os_instance_type" {
  description = "Instance type for OpenSearch nodes"
  type        = string
  default     = "t3.small.search"
}

variable "os_instance_count" {
  description = "Number of OpenSearch nodes"
  type        = number
  default     = 1
}

variable "os_volume_size" {
  description = "Volume size in GB for OpenSearch"
  type        = number
  default     = 10
}

variable "os_kms_key_arn" {
  description = "KMS key ARN for encrypting the OpenSearch domain"
  type        = string
  default     = "arn:aws:kms:us-east-1:123456789012:key/example"
}
=======
// Input variables for the rds-opensearch module
# TODO: Declare module variables
