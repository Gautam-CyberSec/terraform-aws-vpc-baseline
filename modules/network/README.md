# modules/network

VPC, subnets across availability zones, internet gateway, routing, optional NAT
gateways, and VPC flow logs to CloudWatch.

Consume this directly when you want the network without the IAM role:

```hcl
module "network" {
  source = "github.com/Gautam-CyberSec/terraform-aws-vpc-baseline//modules/network"

  name                    = "myapp-prod"
  availability_zone_count = 3
  enable_nat_gateway      = true
  single_nat_gateway      = false
}
```

Design reasoning — subnet index allocation, route table strategy, why NAT is
opt-in — is in [ARCHITECTURE.md](../../ARCHITECTURE.md).

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.6.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.0, < 7.0 |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_name"></a> [name](#input\_name) | Name prefix applied to every resource in this module. | `string` | n/a | yes |
| <a name="input_availability_zone_count"></a> [availability\_zone\_count](#input\_availability\_zone\_count) | How many AZs to spread subnets across. Two is the minimum for most AWS load balancers. | `number` | `2` | no |
| <a name="input_cidr_block"></a> [cidr\_block](#input\_cidr\_block) | IPv4 CIDR block for the VPC. A /16 leaves room for the /20 subnets this module carves out. | `string` | `"10.0.0.0/16"` | no |
| <a name="input_enable_flow_logs"></a> [enable\_flow\_logs](#input\_enable\_flow\_logs) | Send VPC flow logs to CloudWatch Logs. Useful for traffic forensics and for showing that the network is observable. | `bool` | `true` | no |
| <a name="input_enable_nat_gateway"></a> [enable\_nat\_gateway](#input\_enable\_nat\_gateway) | Create NAT gateways so private subnets can reach the internet outbound.<br/><br/>Disabled by default on purpose: a NAT gateway bills hourly plus per GB the<br/>moment it exists, whether or not anything routes through it. Turn this on<br/>when you actually need egress from private subnets, and read the cost note in<br/>the README first. | `bool` | `false` | no |
| <a name="input_flow_log_retention_days"></a> [flow\_log\_retention\_days](#input\_flow\_log\_retention\_days) | Retention for the flow log group. AWS only accepts specific values. | `number` | `30` | no |
| <a name="input_map_public_ip_on_launch"></a> [map\_public\_ip\_on\_launch](#input\_map\_public\_ip\_on\_launch) | Auto-assign public IPs to instances launched in public subnets. Left off so<br/>exposure is an explicit decision per instance rather than a subnet default. | `bool` | `false` | no |
| <a name="input_single_nat_gateway"></a> [single\_nat\_gateway](#input\_single\_nat\_gateway) | Route every private subnet through one NAT gateway instead of one per AZ.<br/>Cheaper, but the NAT becomes a single point of failure and cross-AZ data<br/>charges apply. Production should normally use one per AZ. | `bool` | `true` | no |
| <a name="input_subnet_newbits"></a> [subnet\_newbits](#input\_subnet\_newbits) | Bits added to the VPC prefix when carving subnets. With the default /16 VPC<br/>and newbits = 4, each subnet is a /20 (4091 usable addresses). Raise this for<br/>smaller subnets; the module allocates 2 x availability\_zone\_count of them. | `number` | `4` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags merged onto every resource this module creates. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_availability_zones"></a> [availability\_zones](#output\_availability\_zones) | Availability zones the subnets were placed in. |
| <a name="output_default_security_group_id"></a> [default\_security\_group\_id](#output\_default\_security\_group\_id) | The VPC's default security group, adopted and stripped of all rules. |
| <a name="output_flow_log_group_name"></a> [flow\_log\_group\_name](#output\_flow\_log\_group\_name) | CloudWatch Logs group receiving VPC flow logs. Null when flow logs are disabled. |
| <a name="output_internet_gateway_id"></a> [internet\_gateway\_id](#output\_internet\_gateway\_id) | ID of the internet gateway. |
| <a name="output_nat_gateway_ids"></a> [nat\_gateway\_ids](#output\_nat\_gateway\_ids) | NAT gateway IDs. Empty when enable\_nat\_gateway is false. |
| <a name="output_nat_public_ips"></a> [nat\_public\_ips](#output\_nat\_public\_ips) | Elastic IPs fronting the NAT gateways — the addresses your private subnets egress from. Empty when NAT is disabled. |
| <a name="output_private_route_table_ids"></a> [private\_route\_table\_ids](#output\_private\_route\_table\_ids) | Private route table IDs. |
| <a name="output_private_subnet_ids"></a> [private\_subnet\_ids](#output\_private\_subnet\_ids) | Private subnet IDs, ordered to match availability\_zones. |
| <a name="output_public_route_table_id"></a> [public\_route\_table\_id](#output\_public\_route\_table\_id) | ID of the shared public route table. |
| <a name="output_public_subnet_ids"></a> [public\_subnet\_ids](#output\_public\_subnet\_ids) | Public subnet IDs, ordered to match availability\_zones. |
| <a name="output_vpc_cidr_block"></a> [vpc\_cidr\_block](#output\_vpc\_cidr\_block) | IPv4 CIDR block of the VPC. |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | ID of the VPC. |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_cloudwatch_log_group.flow](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_default_security_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/default_security_group) | resource |
| [aws_eip.nat](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip) | resource |
| [aws_flow_log.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/flow_log) | resource |
| [aws_iam_role.flow](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.flow](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_internet_gateway.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway) | resource |
| [aws_nat_gateway.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/nat_gateway) | resource |
| [aws_route.private_nat](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route.public_internet](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route_table.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table_association.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_route_table_association.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_subnet.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_vpc.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc) | resource |
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) | data source |
| [aws_iam_policy_document.flow_assume](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.flow_write](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
<!-- END_TF_DOCS -->
