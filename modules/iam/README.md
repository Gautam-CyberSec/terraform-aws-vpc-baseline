# modules/iam

EC2 instance role and profile: SSM Session Manager access, CloudWatch agent
permissions, and an optional S3 read policy scoped to named bucket ARNs.

```hcl
module "iam" {
  source = "github.com/Gautam-CyberSec/terraform-aws-vpc-baseline//modules/iam"

  name                    = "myapp-prod"
  readable_s3_bucket_arns = ["arn:aws:s3:::myapp-assets"]
}
```

`readable_s3_bucket_arns` rejects wildcards: an entry must name exactly one
bucket. `s3:ListBucket` and `s3:GetObject` are emitted as separate statements
because they act on different resource shapes.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.6.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.0, < 7.0 |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_name"></a> [name](#input\_name) | Name prefix for the role and instance profile. | `string` | n/a | yes |
| <a name="input_enable_cloudwatch_agent"></a> [enable\_cloudwatch\_agent](#input\_enable\_cloudwatch\_agent) | Attach CloudWatchAgentServerPolicy so the instance can ship metrics and logs. | `bool` | `true` | no |
| <a name="input_enable_ssm"></a> [enable\_ssm](#input\_enable\_ssm) | Attach AmazonSSMManagedInstanceCore so instances are reachable through<br/>Session Manager. This is what lets you close port 22 entirely: no bastion, no<br/>key distribution, and every session is logged in CloudTrail. | `bool` | `true` | no |
| <a name="input_readable_s3_bucket_arns"></a> [readable\_s3\_bucket\_arns](#input\_readable\_s3\_bucket\_arns) | Bucket ARNs this role may read. Grants s3:GetObject on the contents and<br/>s3:ListBucket on the bucket itself — nothing else, and never "*".<br/><br/>Leave empty to skip S3 access entirely. | `list(string)` | `[]` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags merged onto every resource this module creates. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_instance_profile_arn"></a> [instance\_profile\_arn](#output\_instance\_profile\_arn) | ARN of the instance profile. |
| <a name="output_instance_profile_name"></a> [instance\_profile\_name](#output\_instance\_profile\_name) | Instance profile name to pass to aws\_instance.iam\_instance\_profile. |
| <a name="output_role_arn"></a> [role\_arn](#output\_role\_arn) | ARN of the EC2 instance role. |
| <a name="output_role_name"></a> [role\_name](#output\_role\_name) | Name of the EC2 instance role. |
| <a name="output_s3_read_policy_arn"></a> [s3\_read\_policy\_arn](#output\_s3\_read\_policy\_arn) | ARN of the scoped S3 read policy. Null when no buckets were supplied. |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_iam_instance_profile.instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_policy.s3_read](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.cloudwatch_agent](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.s3_read](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.ssm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_policy_document.assume](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.s3_read](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
<!-- END_TF_DOCS -->
