terraform {
  required_version = ">= 1.3"
}

# ------------------------------------------------------------
# Network module
# ------------------------------------------------------------
# This module defines the core networking constructs used across
# the secure LLM architecture. Resources declared here are
# placeholders and should be customized with proper CIDR blocks,
# tagging strategy, and security rules before production use.
# ------------------------------------------------------------

# VPC hosting all application components
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(var.tags, {
    Name = "secure-vpc"
  })
}

# Public subnets for load balancers or NAT gateways
resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name = "public-${count.index}"
  })
}

# Private subnets for ECS tasks and databases
resource "aws_subnet" "private" {
  count      = length(var.private_subnet_cidrs)
  vpc_id     = aws_vpc.this.id
  cidr_block = var.private_subnet_cidrs[count.index]

  tags = merge(var.tags, {
    Name = "private-${count.index}"
  })
}

# Isolated subnets with no internet route, e.g. for sensitive data stores
resource "aws_subnet" "isolated" {
  count      = length(var.isolated_subnet_cidrs)
  vpc_id     = aws_vpc.this.id
  cidr_block = var.isolated_subnet_cidrs[count.index]

  tags = merge(var.tags, {
    Name = "isolated-${count.index}"
  })
}

# Default security group allowing no inbound access
resource "aws_security_group" "default" {
  name        = "default-sg"
  description = "Baseline deny-all security group"
  vpc_id      = aws_vpc.this.id

  # TODO: add explicit ingress and egress rules as required
}
=======
// Placeholder Terraform module for network
terraform {
  required_version = ">= 1.0"
}

# TODO: Define resources for the network module
