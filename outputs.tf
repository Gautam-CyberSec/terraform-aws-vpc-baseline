output "vpc_id" {
  description = "ID of the VPC."
  value       = module.network.vpc_id
}

output "vpc_cidr_block" {
  description = "IPv4 CIDR block of the VPC."
  value       = module.network.vpc_cidr_block
}

output "public_subnet_ids" {
  description = "Public subnet IDs."
  value       = module.network.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs."
  value       = module.network.private_subnet_ids
}

output "availability_zones" {
  description = "AZs the subnets were placed in."
  value       = module.network.availability_zones
}

output "nat_public_ips" {
  description = "Egress addresses of the NAT gateways. Empty when NAT is disabled."
  value       = module.network.nat_public_ips
}

output "flow_log_group_name" {
  description = "CloudWatch Logs group receiving flow logs."
  value       = module.network.flow_log_group_name
}

output "instance_profile_name" {
  description = "Instance profile to attach to EC2 instances in this VPC."
  value       = module.iam.instance_profile_name
}

output "instance_role_arn" {
  description = "ARN of the EC2 instance role."
  value       = module.iam.role_arn
}
