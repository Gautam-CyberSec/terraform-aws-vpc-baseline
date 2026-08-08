/**
 * Minimal example — the cheapest thing that is still a real VPC.
 *
 * Two AZs, public and private subnets, internet gateway, flow logs. No NAT, so
 * private subnets have no outbound path and the running cost is essentially the
 * flow log storage alone.
 *
 *   terraform init
 *   terraform plan
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

  name        = "demo"
  environment = "dev"
  region      = "ap-south-1"
}

output "vpc_id" {
  value = module.baseline.vpc_id
}

output "private_subnet_ids" {
  value = module.baseline.private_subnet_ids
}
