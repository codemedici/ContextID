# ------------------------------------------------------------
# Output values for the network module
# ------------------------------------------------------------

output "vpc_id" {
  description = "Identifier of the created VPC"
  value       = aws_vpc.this.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = aws_subnet.private[*].id
}

output "isolated_subnet_ids" {
  description = "IDs of the isolated subnets"
  value       = aws_subnet.isolated[*].id
}

output "default_security_group_id" {
  description = "ID of the baseline security group"
  value       = aws_security_group.default.id
}

output "nat_gateway_id" {
  description = "ID of the NAT gateway if created"
  value       = try(aws_nat_gateway.this[0].id, null)
}

output "public_route_table_id" {
  description = "Route table ID for public subnets"
  value       = aws_route_table.public.id
}

output "private_route_table_id" {
  description = "Route table ID for private subnets"
  value       = aws_route_table.private.id
}