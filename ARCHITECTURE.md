# Architecture

Design decisions behind this baseline, including the ones that were rejected.

## The shape

A VPC with a symmetric pair of subnet tiers in every availability zone: one
public tier that can reach the internet directly through an internet gateway,
and one private tier that cannot be reached from outside at all.

That split is the whole point. Anything holding data — a database, an
application server, a queue worker — belongs in the private tier. Only things
that must terminate inbound traffic, such as a load balancer or a NAT gateway,
belong in the public one.

## Subnet allocation

Subnets are carved with `cidrsubnet(cidr_block, newbits, index)`. With the
default `/16` and `newbits = 4`, every subnet is a `/20`.

The index assignment matters more than the size:

```
public  → indices 0 .. n-1
private → indices n .. 2n-1
```

Public blocks take the first *n* slots, private blocks the next *n*. Adding a
third availability zone later appends a new public subnet at index 2 and a new
private one at index 5 — it does not disturb anything already deployed.

The obvious alternative, interleaving `public, private, public, private`, reads
more naturally in a diagram and is a trap: adding an AZ shifts every private
subnet's index, so Terraform destroys and recreates all of them. On a live
network that is an outage.

## Routing

One public route table, shared. Every public subnet has the same requirement —
a default route to the internet gateway — so per-AZ tables would be duplication
without benefit.

Private route tables depend on NAT:

| Configuration | Private route tables | Rationale |
|---|---|---|
| NAT disabled | 1 shared | No default route to differentiate them |
| `single_nat_gateway = true` | 1 shared | All subnets egress through the same gateway |
| `single_nat_gateway = false` | 1 per AZ | Each needs a route to its own zone's gateway |

The per-AZ case is the production answer. A single NAT gateway is a single point
of failure: lose that zone and every private subnet loses egress, including the
ones in healthy zones. It also incurs cross-AZ data transfer charges. It stays
the default only because it is cheaper for someone trying this out.

## NAT is opt-in

A NAT gateway bills hourly from creation, not from first use, and is not covered
by the free tier. Defaulting it on would mean anyone who ran `terraform apply` to
see what happened would find a charge on their bill.

So `enable_nat_gateway = false`, and private subnets have no outbound path until
you ask for one. This is also the honest default for a learning repository: the
cheap configuration is the one you get by accident.

## Flow logs

Enabled by default, sent to CloudWatch Logs, retained 30 days.

The IAM policy is scoped to the specific log group ARN and its stream children.
Most published examples use `Resource: "*"`, which grants the flow-log role write
access to every log group in the account. Scoping costs one line and removes a
lateral movement path.

## The default security group

Every VPC gets one, it allows unrestricted traffic between its own members, and
Terraform cannot delete it. Leaving it alone means any resource created without
an explicit security group silently joins a full mesh.

`aws_default_security_group` is an *adoption* resource — declaring it takes
ownership of the existing group. Declared with no ingress or egress blocks, it
strips every rule. The group still exists, but membership now grants nothing.
It is tagged `-default-do-not-use` so the intent is visible in the console.

## Identity

One EC2 instance role, with:

- `AmazonSSMManagedInstanceCore` — Session Manager access, so port 22 can stay
  closed. No bastion host, no key distribution, no shared credentials, and every
  session logged in CloudTrail.
- `CloudWatchAgentServerPolicy` — metrics and log shipping.
- An optional customer-managed policy granting read access to named S3 buckets.

AWS-managed policies are used where they fit rather than being copied into local
definitions: they are maintained as the services change, and a reviewer
recognises them instantly.

The S3 policy is two statements, not one, because `s3:ListBucket` acts on the
bucket ARN and `s3:GetObject` acts on `bucket/*`. Merging them yields a policy
that either fails to list or grants far more than intended.

## What is deliberately absent

- **Compute.** No EC2 instances, ASGs or load balancers. This is the floor other
  stacks build on; bundling compute would make it un-reusable.
- **VPC endpoints.** Correct for production — S3 and DynamoDB traffic should not
  traverse NAT — but they add resources and cost that most users of a baseline do
  not need on day one. On the roadmap.
- **Network ACLs.** Security groups are stateful and sufficient at this layer.
  NACLs are worthwhile as defence in depth, not as a starting point.
- **Remote state.** Backends cannot be parameterised by variables, so hardcoding
  one would break every consumer. See [docs/REMOTE-STATE.md](docs/REMOTE-STATE.md).
