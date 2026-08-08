provider "aws" {
  region = var.region

  # Applied by the provider to every resource that supports tagging, so the
  # modules only have to add what is specific to them.
  default_tags {
    tags = merge(var.tags, {
      Project     = var.name
      Environment = var.environment
      ManagedBy   = "terraform"
      Repository  = "terraform-aws-vpc-baseline"
    })
  }
}

module "network" {
  source = "./modules/network"

  name                    = "${var.name}-${var.environment}"
  cidr_block              = var.cidr_block
  availability_zone_count = var.availability_zone_count

  enable_nat_gateway = var.enable_nat_gateway
  single_nat_gateway = var.single_nat_gateway

  enable_flow_logs        = var.enable_flow_logs
  flow_log_retention_days = var.flow_log_retention_days
}

module "iam" {
  source = "./modules/iam"

  name                    = "${var.name}-${var.environment}"
  readable_s3_bucket_arns = var.readable_s3_bucket_arns
}
