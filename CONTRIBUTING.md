# Contributing

Thanks for taking a look. Issues and pull requests are both welcome.

## Before opening a pull request

Run what CI runs. All three are static — none of them touch an AWS account:

```bash
terraform fmt -recursive
terraform init -backend=false
terraform validate
tflint --recursive
```

If you changed anything under `modules/`, validate the examples too:

```bash
cd examples/minimal   && terraform init -backend=false && terraform validate
cd ../complete        && terraform init -backend=false && terraform validate
```

## Conventions

- **Variables carry descriptions**, and validation rules where a bad value would
  fail confusingly at apply time rather than at plan time.
- **Comments explain why, not what.** `# create a subnet` above a subnet resource
  is noise; the reasoning behind an index scheme is not.
- **New resources that cost money default to off**, the same way
  `enable_nat_gateway` does, and say so in their description.
- **IAM policies name their resources.** A `Resource: "*"` will not be merged
  without a clear reason in the pull request.
- **No credentials, account IDs, real bucket names, or internal hostnames** in
  any committed file, including examples.

## Commit messages

Imperative mood, one logical change per commit:

```
Add VPC endpoint support for S3

Keeps S3 traffic off the NAT gateway, which removes both the
per-GB processing charge and a dependency on egress being up.
```

## Reporting a security issue

Please do not open a public issue for anything security-sensitive. Email
[gautamdem@gmail.com](mailto:gautamdem@gmail.com) instead.
