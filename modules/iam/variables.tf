variable "name" {
  description = "Name prefix for the role and instance profile."
  type        = string
}

variable "enable_ssm" {
  description = <<-EOT
    Attach AmazonSSMManagedInstanceCore so instances are reachable through
    Session Manager. This is what lets you close port 22 entirely: no bastion, no
    key distribution, and every session is logged in CloudTrail.
  EOT
  type        = bool
  default     = true
}

variable "enable_cloudwatch_agent" {
  description = "Attach CloudWatchAgentServerPolicy so the instance can ship metrics and logs."
  type        = bool
  default     = true
}

variable "readable_s3_bucket_arns" {
  description = <<-EOT
    Bucket ARNs this role may read. Grants s3:GetObject on the contents and
    s3:ListBucket on the bucket itself — nothing else, and never "*".

    Leave empty to skip S3 access entirely.
  EOT
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for a in var.readable_s3_bucket_arns : can(regex("^arn:aws[a-z-]*:s3:::", a))])
    error_message = "Each entry must be an S3 bucket ARN, for example arn:aws:s3:::my-bucket."
  }
}

variable "tags" {
  description = "Tags merged onto every resource this module creates."
  type        = map(string)
  default     = {}
}
