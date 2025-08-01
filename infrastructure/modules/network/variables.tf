# ------------------------------------------------------------
# Input variables for the network module
# ------------------------------------------------------------

# CIDR block for the VPC
variable "vpc_cidr" {
  description = "CIDR block for the main VPC"
  type        = string
  default     = "10.0.0.0/16" # Example value; adjust as needed
}

# Lists of CIDR blocks for each subnet type
variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.0.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.1.0/24"]
}

variable "isolated_subnet_cidrs" {
  description = "CIDR blocks for isolated subnets"
  type        = list(string)
  default     = ["10.0.2.0/24"]
}

# Availability zones corresponding to each subnet index
variable "availability_zones" {
  description = "Availability zones for subnets"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

# Whether to provision a managed NAT gateway for private subnets
variable "enable_nat_gateway" {
  description = "Create a NAT gateway for private subnet egress"
  type        = bool
  default     = true
}

# Optional tags applied to all resources
variable "tags" {
  description = "Map of tags to assign to resources"
  type        = map(string)
  default     = {}
}
