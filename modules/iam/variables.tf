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

  # The bucket name is matched against real S3 naming rules rather than just
  # checking the ARN prefix. A prefix-only check accepts "arn:aws:s3:::*", which
  # would silently grant read on every bucket in the account — the exact outcome
  # this variable exists to prevent.
  validation {
    condition = alltrue([
      for a in var.readable_s3_bucket_arns :
      can(regex("^arn:aws[a-z-]*:s3:::[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", a))
    ])
    error_message = "Each entry must be a fully qualified S3 bucket ARN naming one bucket, for example arn:aws:s3:::my-bucket. Wildcards and object paths are not accepted."
  }
}

variable "tags" {
  description = "Tags merged onto every resource this module creates."
  type        = map(string)
  default     = {}
}
