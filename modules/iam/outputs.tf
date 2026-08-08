output "role_name" {
  description = "Name of the EC2 instance role."
  value       = aws_iam_role.instance.name
}

output "role_arn" {
  description = "ARN of the EC2 instance role."
  value       = aws_iam_role.instance.arn
}

output "instance_profile_name" {
  description = "Instance profile name to pass to aws_instance.iam_instance_profile."
  value       = aws_iam_instance_profile.instance.name
}

output "instance_profile_arn" {
  description = "ARN of the instance profile."
  value       = aws_iam_instance_profile.instance.arn
}

output "s3_read_policy_arn" {
  description = "ARN of the scoped S3 read policy. Null when no buckets were supplied."
  value       = length(var.readable_s3_bucket_arns) > 0 ? aws_iam_policy.s3_read[0].arn : null
}
