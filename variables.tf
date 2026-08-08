variable "name" {
  description = "Name prefix for every resource. Keep it short — it is combined with AZ suffixes."
  type        = string
  default     = "baseline"
}

variable "region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "ap-south-1"
}

variable "environment" {
  description = "Environment label, applied as a tag to everything."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "cidr_block" {
  description = "IPv4 CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zone_count" {
  description = "Number of AZs to spread public and private subnets across."
  type        = number
  default     = 2
}

variable "enable_nat_gateway" {
  description = <<-EOT
    Create NAT gateways for private-subnet egress.

    Off by default because a NAT gateway starts billing the moment it exists,
    whether or not traffic flows through it, and it is not in the free tier. In
    ap-south-1 that is roughly USD 40/month per gateway plus a per-GB processing
    charge — verify current rates on the AWS pricing page before enabling.
  EOT
  type        = bool
  default     = false
}

variable "single_nat_gateway" {
  description = "Share one NAT gateway across all private subnets instead of one per AZ. Cheaper, less available."
  type        = bool
  default     = true
}

variable "enable_flow_logs" {
  description = "Ship VPC flow logs to CloudWatch Logs."
  type        = bool
  default     = true
}

variable "flow_log_retention_days" {
  description = "How long to keep flow logs."
  type        = number
  default     = 30
}

variable "readable_s3_bucket_arns" {
  description = "Bucket ARNs the instance role may read. Empty means no S3 access at all."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Extra tags merged onto every resource."
  type        = map(string)
  default     = {}
}
