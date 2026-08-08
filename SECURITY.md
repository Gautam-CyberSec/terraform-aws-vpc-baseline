# Security policy

## Reporting a vulnerability

Email [gautamdem@gmail.com](mailto:gautamdem@gmail.com). Please do not open a
public issue.

Include the configuration that triggers the problem and what an attacker gains.
I will acknowledge within 72 hours.

## Scope

This repository contains Terraform configuration only — no running service and no
credentials. Relevant findings are things like a resource that is more permissive
than its documentation claims, an IAM policy broader than described, or a default
that exposes something unintentionally.

Findings in AWS itself belong to the
[AWS Vulnerability Reporting](https://aws.amazon.com/security/vulnerability-reporting/)
programme.

## What this configuration does to reduce risk

| Control | Where |
|---|---|
| Default security group stripped of all rules | `modules/network/main.tf` |
| Flow log IAM scoped to one log group, not `*` | `modules/network/main.tf` |
| `map_public_ip_on_launch` off by default | `modules/network/variables.tf` |
| S3 policy limited to named bucket ARNs, wildcards rejected | `modules/iam/variables.tf` |
| SSM Session Manager instead of SSH key material | `modules/iam/main.tf` |
| NAT gateways off by default | `variables.tf` |
| State and plan files gitignored | `.gitignore` |

## Handling state

`terraform.tfstate` holds resource attributes in plain text, including values
Terraform treats as sensitive. Never commit it. For shared use, follow
[docs/REMOTE-STATE.md](docs/REMOTE-STATE.md) — encrypted S3 with public access
blocked, plus DynamoDB locking.
