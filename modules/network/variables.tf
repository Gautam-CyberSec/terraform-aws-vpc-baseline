variable "name" {
  description = "Name prefix applied to every resource in this module."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,30}[a-z0-9]$", var.name))
    error_message = "Name must be 3-32 lowercase alphanumeric characters or hyphens, and cannot start or end with a hyphen."
  }
}

variable "cidr_block" {
  description = "IPv4 CIDR block for the VPC. A /16 leaves room for the /20 subnets this module carves out."
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.cidr_block, 0))
    error_message = "cidr_block must be a valid IPv4 CIDR, for example 10.0.0.0/16."
  }
}

variable "availability_zone_count" {
  description = "How many AZs to spread subnets across. Two is the minimum for most AWS load balancers."
  type        = number
  default     = 2

  validation {
    condition     = var.availability_zone_count >= 1 && var.availability_zone_count <= 4
    error_message = "availability_zone_count must be between 1 and 4."
  }
}

variable "subnet_newbits" {
  description = <<-EOT
    Bits added to the VPC prefix when carving subnets. With the default /16 VPC
    and newbits = 4, each subnet is a /20 (4091 usable addresses). Raise this for
    smaller subnets; the module allocates 2 x availability_zone_count of them.
  EOT
  type        = number
  default     = 4

  validation {
    condition     = var.subnet_newbits >= 1 && var.subnet_newbits <= 12
    error_message = "subnet_newbits must be between 1 and 12."
  }
}

variable "enable_nat_gateway" {
  description = <<-EOT
    Create NAT gateways so private subnets can reach the internet outbound.

    Disabled by default on purpose: a NAT gateway bills hourly plus per GB the
    moment it exists, whether or not anything routes through it. Turn this on
    when you actually need egress from private subnets, and read the cost note in
    the README first.
  EOT
  type        = bool
  default     = false
}

variable "single_nat_gateway" {
  description = <<-EOT
    Route every private subnet through one NAT gateway instead of one per AZ.
    Cheaper, but the NAT becomes a single point of failure and cross-AZ data
    charges apply. Production should normally use one per AZ.
  EOT
  type        = bool
  default     = true
}

variable "map_public_ip_on_launch" {
  description = <<-EOT
    Auto-assign public IPs to instances launched in public subnets. Left off so
    exposure is an explicit decision per instance rather than a subnet default.
  EOT
  type        = bool
  default     = false
}

variable "enable_flow_logs" {
  description = "Send VPC flow logs to CloudWatch Logs. Useful for traffic forensics and for showing that the network is observable."
  type        = bool
  default     = true
}

variable "flow_log_retention_days" {
  description = "Retention for the flow log group. AWS only accepts specific values."
  type        = number
  default     = 30

  validation {
    condition = contains(
      [1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653],
      var.flow_log_retention_days
    )
    error_message = "flow_log_retention_days must be one of the retention periods CloudWatch Logs accepts (1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653)."
  }
}

variable "tags" {
  description = "Tags merged onto every resource this module creates."
  type        = map(string)
  default     = {}
}
