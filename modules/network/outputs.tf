output "vpc_id" {
  description = "ID of the VPC."
  value       = aws_vpc.this.id
}

output "vpc_cidr_block" {
  description = "IPv4 CIDR block of the VPC."
  value       = aws_vpc.this.cidr_block
}

output "public_subnet_ids" {
  description = "Public subnet IDs, ordered to match availability_zones."
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Private subnet IDs, ordered to match availability_zones."
  value       = aws_subnet.private[*].id
}

output "availability_zones" {
  description = "Availability zones the subnets were placed in."
  value       = local.azs
}

output "internet_gateway_id" {
  description = "ID of the internet gateway."
  value       = aws_internet_gateway.this.id
}

output "nat_gateway_ids" {
  description = "NAT gateway IDs. Empty when enable_nat_gateway is false."
  value       = aws_nat_gateway.this[*].id
}

output "nat_public_ips" {
  description = "Elastic IPs fronting the NAT gateways — the addresses your private subnets egress from. Empty when NAT is disabled."
  value       = aws_eip.nat[*].public_ip
}

output "public_route_table_id" {
  description = "ID of the shared public route table."
  value       = aws_route_table.public.id
}

output "private_route_table_ids" {
  description = "Private route table IDs."
  value       = aws_route_table.private[*].id
}

output "default_security_group_id" {
  description = "The VPC's default security group, adopted and stripped of all rules."
  value       = aws_default_security_group.this.id
}

output "flow_log_group_name" {
  description = "CloudWatch Logs group receiving VPC flow logs. Null when flow logs are disabled."
  value       = var.enable_flow_logs ? aws_cloudwatch_log_group.flow[0].name : null
}
