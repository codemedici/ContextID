terraform {
  required_version = ">= 1.3"
}

# ------------------------------------------------------------
# Network module
# ------------------------------------------------------------
# Provisions a production-grade VPC with segmented public, private,
# and isolated subnets. Public subnets route to an Internet Gateway,
# private subnets egress via a managed NAT Gateway, and isolated
# subnets have no outbound connectivity. A baseline security group
# explicitly denies inbound access and allows outbound traffic.
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

# Internet gateway for egress from public subnets
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "secure-igw"
  })
}

# Public subnets for load balancers or NAT gateways
resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name = "public-${count.index}"
  })
}

# Private subnets for ECS tasks and databases
resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = merge(var.tags, {
    Name = "private-${count.index}"
  })
}

# Isolated subnets with no internet route, e.g. for sensitive data stores
resource "aws_subnet" "isolated" {
  count             = length(var.isolated_subnet_cidrs)
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.isolated_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = merge(var.tags, {
    Name = "isolated-${count.index}"
  })
}

# Elastic IP for the NAT gateway (created only if enabled)
resource "aws_eip" "nat" {
  count  = var.enable_nat_gateway ? 1 : 0
  domain = "vpc"

  tags = merge(var.tags, {
    Name = "nat-eip"
  })
}

# NAT gateway placed in the first public subnet
resource "aws_nat_gateway" "this" {
  count         = var.enable_nat_gateway ? 1 : 0
  subnet_id     = aws_subnet.public[0].id
  allocation_id = aws_eip.nat[0].id

  tags = merge(var.tags, {
    Name = "secure-nat"
  })
}

# Public route table routing internet-bound traffic to the IGW
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "public-rt"
  })
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Private route table using NAT for outbound internet access
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "private-rt"
  })
}

resource "aws_route" "private_nat" {
  count                  = var.enable_nat_gateway ? 1 : 0
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[0].id
}

resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# Isolated route table with no internet route
resource "aws_route_table" "isolated" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "isolated-rt"
  })
}

resource "aws_route_table_association" "isolated" {
  count          = length(aws_subnet.isolated)
  subnet_id      = aws_subnet.isolated[count.index].id
  route_table_id = aws_route_table.isolated.id
}

# Baseline security group explicitly denying ingress and allowing egress
resource "aws_security_group" "default" {
  name        = "baseline-sg"
  description = "No inbound; allow all outbound"
  vpc_id      = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "baseline-sg"
  })
}

# Explicit outbound rule
resource "aws_security_group_rule" "egress_all" {
  type              = "egress"
  security_group_id = aws_security_group.default.id
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

