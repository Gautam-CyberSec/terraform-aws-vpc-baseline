data "aws_availability_zones" "available" {
  state = "available"

  # Opt-in zones (Local Zones, Wavelength) behave differently and are not valid
  # targets for a general-purpose subnet layout.
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, var.availability_zone_count)

  # Public subnets take the first N blocks, private the next N, so adding an AZ
  # later appends rather than renumbering everything already deployed.
  public_cidrs  = [for i in range(var.availability_zone_count) : cidrsubnet(var.cidr_block, var.subnet_newbits, i)]
  private_cidrs = [for i in range(var.availability_zone_count) : cidrsubnet(var.cidr_block, var.subnet_newbits, i + var.availability_zone_count)]

  nat_count = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : var.availability_zone_count) : 0

  # Without NAT there is nothing to differentiate the private route tables, so one
  # shared table keeps the plan small. With per-AZ NAT each table needs its own
  # default route.
  private_route_table_count = var.enable_nat_gateway && !var.single_nat_gateway ? var.availability_zone_count : 1

  tags = merge(var.tags, {
    Module = "network"
  })
}

# ── VPC ──────────────────────────────────────────────────────────────────────

resource "aws_vpc" "this" {
  cidr_block           = var.cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(local.tags, { Name = var.name })
}

# The default security group allows all traffic between its members. Terraform
# cannot delete it, so the safe move is to adopt it and strip every rule; anything
# that lands on it by accident then has no connectivity rather than full mesh.
resource "aws_default_security_group" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(local.tags, { Name = "${var.name}-default-do-not-use" })
}

# ── Subnets ──────────────────────────────────────────────────────────────────

resource "aws_subnet" "public" {
  count = var.availability_zone_count

  vpc_id                  = aws_vpc.this.id
  cidr_block              = local.public_cidrs[count.index]
  availability_zone       = local.azs[count.index]
  map_public_ip_on_launch = var.map_public_ip_on_launch

  tags = merge(local.tags, {
    Name = "${var.name}-public-${local.azs[count.index]}"
    Tier = "public"
  })
}

resource "aws_subnet" "private" {
  count = var.availability_zone_count

  vpc_id            = aws_vpc.this.id
  cidr_block        = local.private_cidrs[count.index]
  availability_zone = local.azs[count.index]

  tags = merge(local.tags, {
    Name = "${var.name}-private-${local.azs[count.index]}"
    Tier = "private"
  })
}

# ── Internet gateway and public routing ──────────────────────────────────────

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(local.tags, { Name = "${var.name}-igw" })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  tags = merge(local.tags, { Name = "${var.name}-public" })
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public" {
  count = var.availability_zone_count

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# ── NAT gateways (optional — see enable_nat_gateway) ─────────────────────────

resource "aws_eip" "nat" {
  count = local.nat_count

  domain = "vpc"

  tags = merge(local.tags, { Name = "${var.name}-nat-${count.index}" })

  depends_on = [aws_internet_gateway.this]
}

resource "aws_nat_gateway" "this" {
  count = local.nat_count

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(local.tags, { Name = "${var.name}-nat-${count.index}" })

  depends_on = [aws_internet_gateway.this]
}

# ── Private routing ──────────────────────────────────────────────────────────

resource "aws_route_table" "private" {
  count = local.private_route_table_count

  vpc_id = aws_vpc.this.id

  tags = merge(local.tags, {
    Name = local.private_route_table_count == 1 ? "${var.name}-private" : "${var.name}-private-${local.azs[count.index]}"
  })
}

resource "aws_route" "private_nat" {
  count = var.enable_nat_gateway ? local.private_route_table_count : 0

  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[var.single_nat_gateway ? 0 : count.index].id
}

resource "aws_route_table_association" "private" {
  count = var.availability_zone_count

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[local.private_route_table_count == 1 ? 0 : count.index].id
}

# ── Flow logs ────────────────────────────────────────────────────────────────

resource "aws_cloudwatch_log_group" "flow" {
  count = var.enable_flow_logs ? 1 : 0

  name              = "/aws/vpc/${var.name}"
  retention_in_days = var.flow_log_retention_days

  tags = merge(local.tags, { Name = "${var.name}-flow-logs" })
}

data "aws_iam_policy_document" "flow_assume" {
  count = var.enable_flow_logs ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "flow_write" {
  count = var.enable_flow_logs ? 1 : 0

  # Scoped to this VPC's log group rather than "*", which is what the AWS
  # walkthrough hands you.
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams",
    ]
    resources = [
      aws_cloudwatch_log_group.flow[0].arn,
      "${aws_cloudwatch_log_group.flow[0].arn}:*",
    ]
  }
}

resource "aws_iam_role" "flow" {
  count = var.enable_flow_logs ? 1 : 0

  name_prefix        = "${var.name}-flow-"
  assume_role_policy = data.aws_iam_policy_document.flow_assume[0].json

  tags = merge(local.tags, { Name = "${var.name}-flow-logs" })
}

resource "aws_iam_role_policy" "flow" {
  count = var.enable_flow_logs ? 1 : 0

  name_prefix = "${var.name}-flow-"
  role        = aws_iam_role.flow[0].id
  policy      = data.aws_iam_policy_document.flow_write[0].json
}

resource "aws_flow_log" "this" {
  count = var.enable_flow_logs ? 1 : 0

  vpc_id                   = aws_vpc.this.id
  traffic_type             = "ALL"
  iam_role_arn             = aws_iam_role.flow[0].arn
  log_destination          = aws_cloudwatch_log_group.flow[0].arn
  log_destination_type     = "cloud-watch-logs"
  max_aggregation_interval = 60

  tags = merge(local.tags, { Name = "${var.name}-flow-logs" })
}
