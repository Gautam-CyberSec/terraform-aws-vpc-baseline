# Changelog

All notable changes to this project are documented here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Planned
- VPC endpoints for S3 and DynamoDB
- Optional IPv6 dual-stack support
- Network ACL layer as defence in depth
- Terratest coverage for subnet allocation

## [1.0.0] — 2026-08-09

Initial release.

### Added
- `modules/network` — VPC, public and private subnets across 1–4 availability
  zones, internet gateway, route tables, optional NAT gateways (single or
  per-AZ), and VPC flow logs to CloudWatch.
- `modules/iam` — EC2 instance role and profile with SSM Session Manager access,
  CloudWatch agent permissions, and an optional S3 read policy scoped to named
  bucket ARNs.
- Root module composing both, with provider-level default tags.
- `examples/minimal` — two AZs, no NAT, near-zero standing cost.
- `examples/complete` — three AZs, NAT per AZ, one-year log retention.
- GitHub Actions workflow running `fmt`, `validate` and `tflint`.
- `docs/REMOTE-STATE.md` covering the S3 and DynamoDB backend.

### Security
- Trivy misconfiguration and secret scanning in CI, failing on HIGH/CRITICAL.
- Default security group adopted and stripped of all rules.
- Flow log IAM policy scoped to a single log group rather than `Resource: "*"`.
- `map_public_ip_on_launch` off by default.
- S3 bucket ARNs validated to reject wildcards.
- NAT gateways disabled by default so no cost is incurred unintentionally.

[Unreleased]: https://github.com/Gautam-CyberSec/terraform-aws-vpc-baseline/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/Gautam-CyberSec/terraform-aws-vpc-baseline/releases/tag/v1.0.0
