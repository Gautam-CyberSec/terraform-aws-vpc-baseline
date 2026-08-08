# Remote state

Terraform state records every resource attribute in plain text, including values
marked sensitive. Local state is acceptable while you are the only person
applying and the environment is disposable. Beyond that it becomes both a
security problem and a collaboration one: two people applying against separate
local state files will fight over the same infrastructure.

This repository ships **without** a backend block, because backend configuration
cannot be parameterised by variables — hardcoding a bucket name would break every
consumer of the module.

## Setting it up

Create the bucket and lock table once, outside this configuration. State storage
should not be managed by the state it stores.

```bash
REGION=ap-south-1
BUCKET=tfstate-$(aws sts get-caller-identity --query Account --output text)

aws s3api create-bucket \
  --bucket "$BUCKET" \
  --region "$REGION" \
  --create-bucket-configuration LocationConstraint="$REGION"

# Versioning turns a bad apply into a recoverable one.
aws s3api put-bucket-versioning \
  --bucket "$BUCKET" \
  --versioning-configuration Status=Enabled

aws s3api put-bucket-encryption \
  --bucket "$BUCKET" \
  --server-side-encryption-configuration \
  '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'

# State is never public.
aws s3api put-public-access-block \
  --bucket "$BUCKET" \
  --public-access-block-configuration \
  "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

aws dynamodb create-table \
  --table-name terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region "$REGION"
```

Then add to `versions.tf`:

```hcl
terraform {
  backend "s3" {
    bucket         = "tfstate-123456789012"
    key            = "vpc-baseline/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
```

And migrate:

```bash
terraform init -migrate-state
```

## Notes

- The DynamoDB table prevents two concurrent applies from corrupting state. It is
  pay-per-request, so it costs essentially nothing at this volume.
- Use a distinct `key` per environment. Sharing one key across dev and prod means
  one state file describing two environments, which ends badly.
- Never commit `.tfstate` or `.tfplan`. Both are gitignored here; a saved plan can
  embed sensitive values just as state can.
