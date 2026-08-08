locals {
  tags = merge(var.tags, { Module = "iam" })
}

data "aws_iam_policy_document" "assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "instance" {
  name_prefix        = "${var.name}-instance-"
  assume_role_policy = data.aws_iam_policy_document.assume.json

  tags = merge(local.tags, { Name = "${var.name}-instance" })
}

resource "aws_iam_instance_profile" "instance" {
  name_prefix = "${var.name}-instance-"
  role        = aws_iam_role.instance.name

  tags = local.tags
}

# AWS-managed policies rather than hand-rolled copies: they are maintained as the
# services change, and reviewers recognise them immediately.
resource "aws_iam_role_policy_attachment" "ssm" {
  count = var.enable_ssm ? 1 : 0

  role       = aws_iam_role.instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "cloudwatch_agent" {
  count = var.enable_cloudwatch_agent ? 1 : 0

  role       = aws_iam_role.instance.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# ── Scoped S3 read ───────────────────────────────────────────────────────────

data "aws_iam_policy_document" "s3_read" {
  count = length(var.readable_s3_bucket_arns) > 0 ? 1 : 0

  # ListBucket is a bucket-level action; GetObject is an object-level one. They
  # need separate statements with different resource shapes — collapsing them is
  # the most common way these policies end up silently broken or over-broad.
  statement {
    sid       = "ListNamedBuckets"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = var.readable_s3_bucket_arns
  }

  statement {
    sid       = "ReadObjectsInNamedBuckets"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = [for arn in var.readable_s3_bucket_arns : "${arn}/*"]
  }
}

resource "aws_iam_policy" "s3_read" {
  count = length(var.readable_s3_bucket_arns) > 0 ? 1 : 0

  name_prefix = "${var.name}-s3-read-"
  description = "Read-only access to a named set of S3 buckets."
  policy      = data.aws_iam_policy_document.s3_read[0].json

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "s3_read" {
  count = length(var.readable_s3_bucket_arns) > 0 ? 1 : 0

  role       = aws_iam_role.instance.name
  policy_arn = aws_iam_policy.s3_read[0].arn
}
