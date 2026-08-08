# terraform-aws-vpc-baseline

A production-shaped AWS network baseline in Terraform — VPC, public and private
subnets across multiple availability zones, internet gateway, optional NAT,
flow logs, and a least-privilege EC2 instance role.

[![Terraform](https://img.shields.io/badge/terraform-%E2%89%A5%201.6-7B42BC?style=flat-square&logo=terraform&logoColor=white)](https://developer.hashicorp.com/terraform)
[![AWS Provider](https://img.shields.io/badge/aws%20provider-%E2%89%A5%205.0-FF9900?style=flat-square&logo=amazonwebservices&logoColor=white)](https://registry.terraform.io/providers/hashicorp/aws/latest)
[![Validate](https://github.com/Gautam-CyberSec/terraform-aws-vpc-baseline/actions/workflows/terraform.yml/badge.svg)](https://github.com/Gautam-CyberSec/terraform-aws-vpc-baseline/actions/workflows/terraform.yml)
[![License](https://img.shields.io/badge/license-MIT-blue?style=flat-square)](LICENSE)

---

## Why this exists

I built this network by hand first — clicking through the VPC console, drawing
subnets on paper, getting route tables wrong, and finding out the hard way that a
private subnet without a NAT gateway cannot reach the package mirror.

That knowledge was trapped in a console. This repository is the same network
expressed as code: reviewable, diffable, reproducible in a fresh account in about
ninety seconds, and destroyable in one command when the bill starts to matter.

It is deliberately a *baseline*, not a framework. It does one thing — the network
and identity floor that almost every other AWS project starts from.

## Features

- **Multi-AZ by default** — public and private subnets across 1–4 availability
  zones, sized from a single `newbits` knob.
- **NAT is opt-in.** Off by default, because a NAT gateway bills from the moment
  it exists whether or not traffic flows. One-per-AZ or a single shared gateway.
- **Flow logs to CloudWatch**, with an IAM policy scoped to that one log group
  rather than the `"*"` the AWS walkthrough gives you.
- **The default security group is neutralised.** Terraform cannot delete it, so
  this module adopts it and strips every rule — anything landing on it by
  accident gets no connectivity instead of a full mesh.
- **No public IPs by default.** `map_public_ip_on_launch` is off, so exposure is
  a per-instance decision rather than a subnet-wide default.
- **SSM instead of SSH.** The instance role carries
  `AmazonSSMManagedInstanceCore`, so you can close port 22 entirely — no bastion,
  no key distribution, and every session recorded in CloudTrail.
- **S3 access is named, never wildcarded.** Pass bucket ARNs; the policy grants
  `ListBucket` on the buckets and `GetObject` on their contents, in the two
  separate statements those actions actually require.
- **Validated in CI** — `fmt`, `init`, `validate` and `tflint` on every push.

## Architecture

```mermaid
flowchart TB
    igw["Internet Gateway"]

    subgraph vpc["VPC · 10.0.0.0/16"]
        direction TB

        subgraph az_a["Availability Zone A"]
            pub_a["Public subnet<br/>10.0.0.0/20"]
            priv_a["Private subnet<br/>10.0.32.0/20"]
        end

        subgraph az_b["Availability Zone B"]
            pub_b["Public subnet<br/>10.0.16.0/20"]
            priv_b["Private subnet<br/>10.0.48.0/20"]
        end

        nat(["NAT Gateway<br/>optional · off by default"])
        rt_pub["Public route table<br/>0.0.0.0/0 → IGW"]
        rt_priv["Private route table<br/>0.0.0.0/0 → NAT, when enabled"]
    end

    flow["CloudWatch Logs<br/>/aws/vpc/name"]

    igw <--> rt_pub
    rt_pub --- pub_a
    rt_pub --- pub_b
    pub_a -.hosts.-> nat
    nat --> rt_priv
    rt_priv --- priv_a
    rt_priv --- priv_b
    vpc -.flow logs.-> flow
```

Subnets are allocated so that public blocks take the first *N* slots and private
blocks the next *N*. Adding an availability zone later appends new subnets rather
than renumbering the ones already deployed — a rebuild you only want to discover
once.

Full reasoning, including what was rejected, is in [ARCHITECTURE.md](ARCHITECTURE.md).

## Repository layout

```
.
├── main.tf                  # provider + module composition
├── variables.tf             # root inputs
├── outputs.tf               # root outputs
├── versions.tf              # version constraints
├── modules/
│   ├── network/             # VPC, subnets, routing, NAT, flow logs
│   └── iam/                 # instance role, profile, scoped S3 policy
├── examples/
│   ├── minimal/             # 2 AZs, no NAT — near-zero cost
│   └── complete/            # 3 AZs, NAT per AZ, 1-year log retention
├── docs/
│   └── REMOTE-STATE.md      # S3 + DynamoDB backend, ready to uncomment
└── .github/workflows/       # fmt · validate · tflint
```

## Getting started

**Requirements** — Terraform ≥ 1.6, AWS credentials with permission to create VPC
and IAM resources.

```bash
git clone https://github.com/Gautam-CyberSec/terraform-aws-vpc-baseline.git
cd terraform-aws-vpc-baseline
terraform init
```

Review what would be created before creating it:

```bash
terraform plan -var="name=demo" -var="environment=dev"
```

Apply:

```bash
terraform apply -var="name=demo" -var="environment=dev"
```

Tear down — do this as soon as you are finished, especially with NAT enabled:

```bash
terraform destroy -var="name=demo" -var="environment=dev"
```

### Using it as a module

```hcl
module "network" {
  source = "github.com/Gautam-CyberSec/terraform-aws-vpc-baseline"

  name        = "myapp"
  environment = "prod"
  region      = "ap-south-1"

  availability_zone_count = 3
  enable_nat_gateway      = true
  single_nat_gateway      = false
}
```

## Configuration

| Variable | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | `"baseline"` | Name prefix for every resource |
| `region` | `string` | `"ap-south-1"` | Region to deploy into |
| `environment` | `string` | `"dev"` | One of `dev`, `staging`, `prod` |
| `cidr_block` | `string` | `"10.0.0.0/16"` | VPC CIDR |
| `availability_zone_count` | `number` | `2` | AZs to span, 1–4 |
| `enable_nat_gateway` | `bool` | `false` | Create NAT gateways — **costs money** |
| `single_nat_gateway` | `bool` | `true` | Share one NAT instead of one per AZ |
| `enable_flow_logs` | `bool` | `true` | Ship flow logs to CloudWatch |
| `flow_log_retention_days` | `number` | `30` | Log retention |
| `readable_s3_bucket_arns` | `list(string)` | `[]` | Buckets the instance role may read |
| `tags` | `map(string)` | `{}` | Extra tags merged onto everything |

### Outputs

`vpc_id` · `vpc_cidr_block` · `public_subnet_ids` · `private_subnet_ids` ·
`availability_zones` · `nat_public_ips` · `flow_log_group_name` ·
`instance_profile_name` · `instance_role_arn`

## Cost

With the defaults — no NAT — the standing cost is close to nothing. VPCs,
subnets, route tables and internet gateways are free; you pay for flow log
storage, which is pennies at 30-day retention on a quiet network.

Enabling NAT changes that. In `ap-south-1` a NAT gateway runs on the order of
**USD 40/month each**, plus a per-GB processing charge, billed whether or not
anything uses it. The `complete` example creates three. Check the
[current pricing](https://aws.amazon.com/vpc/pricing/) before applying, and
`terraform destroy` when you are done experimenting.

## Security considerations

- **State files contain secrets.** `.tfstate` holds resource attributes in plain
  text. It is gitignored here; for anything shared, use the S3 + DynamoDB backend
  in [docs/REMOTE-STATE.md](docs/REMOTE-STATE.md) with encryption enabled.
- **The default security group is stripped**, not left at its permissive default.
- **Flow log IAM is scoped to one log group**, not `Resource: "*"`.
- **S3 permissions are enumerated by bucket ARN.** Wildcards are rejected by a
  variable validation rule.
- **No SSH key material anywhere.** Access is via SSM Session Manager.
- **No hardcoded account IDs, secrets, or environment values.** The repository
  contains no credentials of any kind.

## Lessons learned

- Splitting subnet CIDRs by *index range* rather than interleaving means adding an
  AZ appends instead of renumbering. Interleaving looks tidier and forces a
  rebuild of everything.
- `s3:ListBucket` is a bucket-level action and `s3:GetObject` is object-level.
  Putting both in one statement produces a policy that is either broken or far
  broader than intended — the single most common IAM mistake I made by hand.
- `aws_default_security_group` is an adoption resource, not a creation one.
  Declaring it takes ownership of something that already exists.
- Defaults are a security control. `enable_nat_gateway = false` and
  `map_public_ip_on_launch = false` mean the careless path is also the cheap and
  closed one.

## Roadmap

- [ ] VPC endpoints for S3 and DynamoDB, to keep that traffic off the NAT
- [ ] Optional IPv6 dual-stack
- [ ] Network ACL layer as defence in depth behind security groups
- [ ] `terraform-docs` pre-commit hook to generate the variable tables
- [ ] Terratest coverage for the subnet allocation logic

## Contributing

Issues and pull requests are welcome — see [CONTRIBUTING.md](CONTRIBUTING.md).
CI runs `terraform fmt -check`, `terraform validate` and `tflint` on every push,
so run those locally first.

## License

[MIT](LICENSE) — © Gautam

## Author

**Gautam** — Cloud & Backend Engineer

[Portfolio](https://Gautam-cloud.com) ·
[LinkedIn](https://linkedin.com/in/gautam-cybersec) ·
[gautamdem@gmail.com](mailto:gautamdem@gmail.com)
