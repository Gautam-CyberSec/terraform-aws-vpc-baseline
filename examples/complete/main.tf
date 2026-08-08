/**
 * Complete example — the production-shaped configuration.
 *
 * Three AZs, NAT gateway per AZ so a zone failure does not take egress with it,
 * a year of flow log retention, and an instance role scoped to read one bucket.
 *
 * This one costs real money. Three NAT gateways runs on the order of USD 120/month
 * in ap-south-1 before any data processing charges — check current pricing before
 * applying. Run `terraform destroy` when you are done.
 */

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0, < 7.0"
    }
  }
}

module "baseline" {
  source = "../../"

  name        = "martialops"
  environment = "prod"
  region      = "ap-south-1"

  cidr_block              = "10.20.0.0/16"
  availability_zone_count = 3

  # One NAT per AZ: no cross-zone dependency for egress.
  enable_nat_gateway = true
  single_nat_gateway = false

  enable_flow_logs        = true
  flow_log_retention_days = 365

  readable_s3_bucket_arns = [
    "arn:aws:s3:::example-app-assets",
  ]

  tags = {
    Owner      = "platform"
    CostCenter = "engineering"
  }
}

output "vpc_id" {
  value = module.baseline.vpc_id
}

output "nat_public_ips" {
  description = "Allow-list these upstream if a third party filters by source IP."
  value       = module.baseline.nat_public_ips
}

output "instance_profile_name" {
  value = module.baseline.instance_profile_name
}
