variable "name_prefix" {}
variable "cidr_block" {}
variable "subnet_bits" {}
variable "az_count" { type = number }
variable "azs" { type = list(string) }
variable "single_nat_gateway" { type = bool }
variable "enable_data_subnets" { type = bool }
variable "enable_vpc_endpoints" { type = bool }
variable "enabled_vpc_endpoints" { type = list(string) }
variable "endpoint_ingress_cidrs" { type = list(string) }
variable "endpoint_security_group_ids" { type = list(string) }

data "aws_availability_zones" "az" { state = "available" }
data "aws_region" "current" {}

resource "aws_vpc" "vpc" {
  cidr_block           = var.cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags                 = { Name = "${var.name_prefix}-vpc" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags   = { Name = "${var.name_prefix}-igw" }
}
/*
locals {
  azs           = slice(data.aws_availability_zones.az.names, 0, 3)
  public_cidrs  = [for i in range(0, 3) : cidrsubnet(var.cidr_block, (var.subnet_bits - 16), i)]
  private_cidrs = [for i in range(0, 3) : cidrsubnet(var.cidr_block, (var.subnet_bits - 16), i + 16)]
  data_cidrs    = [for i in range(0, 3) : cidrsubnet(var.cidr_block, (var.subnet_bits - 16), i + 32)]
  indices       = { for i in range(3) : tostring(i) => i }
}*/

locals {
  azs      = length(var.azs) > 0 ? var.azs : slice(data.aws_availability_zones.az.names, 0, var.az_count)
  az_count = length(local.azs)

  # /16 → /20 means 4 new bits → 16 total subnets (0..15).
  # Allocate ranges:
  #   public  : 0..(az_count-1)
  #   private : 4..(4+az_count-1)
  #   data    : 8..(8+az_count-1)
  public_cidrs  = [for i in range(local.az_count) : cidrsubnet(var.cidr_block, (var.subnet_bits - 16), i)]
  private_cidrs = [for i in range(local.az_count) : cidrsubnet(var.cidr_block, (var.subnet_bits - 16), 4 + i)]
  data_cidrs    = [for i in range(local.az_count) : cidrsubnet(var.cidr_block, (var.subnet_bits - 16), 8 + i)]

  # helper map for for_each
  indices = { for i in range(local.az_count) : tostring(i) => i }

  nat_indices            = var.single_nat_gateway ? { "0" = 0 } : local.indices
  endpoint_ingress_cidrs = length(var.endpoint_ingress_cidrs) > 0 ? var.endpoint_ingress_cidrs : [var.cidr_block]

  endpoint_service_map = {
    "s3"          = { type = "Gateway", service = "s3", private_dns_enabled = false }
    "ecr.api"     = { type = "Interface", service = "ecr.api", private_dns_enabled = true }
    "ecr.dkr"     = { type = "Interface", service = "ecr.dkr", private_dns_enabled = true }
    "logs"        = { type = "Interface", service = "logs", private_dns_enabled = true }
    "monitoring"  = { type = "Interface", service = "monitoring", private_dns_enabled = true }
    "sts"         = { type = "Interface", service = "sts", private_dns_enabled = true }
    "kms"         = { type = "Interface", service = "kms", private_dns_enabled = true }
    "ec2"         = { type = "Interface", service = "ec2", private_dns_enabled = true }
    "autoscaling" = { type = "Interface", service = "autoscaling", private_dns_enabled = true }
  }

  enabled_endpoint_keys = var.enable_vpc_endpoints ? var.enabled_vpc_endpoints : []
  endpoint_defs = {
    for k, v in local.endpoint_service_map : k => v
    if contains(local.enabled_endpoint_keys, k)
  }
  interface_endpoints = { for k, v in local.endpoint_defs : k => v if v.type == "Interface" }
  gateway_endpoints   = { for k, v in local.endpoint_defs : k => v if v.type == "Gateway" }
}


resource "aws_subnet" "public" {
  for_each                = local.indices
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = local.public_cidrs[each.value]
  availability_zone       = local.azs[each.value]
  map_public_ip_on_launch = true
  tags                    = { Name = "${var.name_prefix}-pub-${each.value}" }
}

resource "aws_subnet" "private" {
  for_each          = local.indices
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = local.private_cidrs[each.value]
  availability_zone = local.azs[each.value]
  tags              = { Name = "${var.name_prefix}-pri-${each.value}" }
}

resource "aws_subnet" "data" {
  for_each          = var.enable_data_subnets ? local.indices : {}
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = local.data_cidrs[each.value]
  availability_zone = local.azs[each.value]
  tags              = { Name = "${var.name_prefix}-data-${each.value}" }
}

resource "aws_eip" "nat" {
  for_each = local.nat_indices
  domain   = "vpc" # replaces vpc = true
  tags     = { Name = "${var.name_prefix}-nat-eip-${each.key}" }
}

resource "aws_nat_gateway" "nat" {
  for_each      = local.nat_indices
  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = aws_subnet.public[each.key].id
  depends_on    = [aws_internet_gateway.igw]
  tags          = { Name = "${var.name_prefix}-nat-${each.key}" }
}


resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "${var.name_prefix}-rt-public" }
}
resource "aws_route_table_association" "public_assoc" {
  for_each       = local.indices
  subnet_id      = aws_subnet.public[each.key].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  for_each = var.single_nat_gateway ? { "0" = 0 } : local.indices
  vpc_id   = aws_vpc.vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat[each.key].id
  }
  tags = {
    Name = var.single_nat_gateway ? "${var.name_prefix}-rt-private" : "${var.name_prefix}-rt-private-${each.key}"
  }
}
resource "aws_route_table_association" "private_assoc" {
  for_each       = local.indices
  subnet_id      = aws_subnet.private[each.key].id
  route_table_id = var.single_nat_gateway ? aws_route_table.private["0"].id : aws_route_table.private[each.key].id
}

resource "aws_route_table" "data" {
  for_each = var.enable_data_subnets ? (var.single_nat_gateway ? { "0" = 0 } : local.indices) : {}
  vpc_id   = aws_vpc.vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat[each.key].id
  }
  tags = {
    Name = var.single_nat_gateway ? "${var.name_prefix}-rt-data" : "${var.name_prefix}-rt-data-${each.key}"
  }
}

resource "aws_route_table_association" "data_assoc" {
  for_each       = var.enable_data_subnets ? local.indices : {}
  subnet_id      = aws_subnet.data[each.key].id
  route_table_id = var.single_nat_gateway ? aws_route_table.data["0"].id : aws_route_table.data[each.key].id
}

locals {
  public_route_table_ids   = [aws_route_table.public.id]
  private_route_table_ids  = [for k in sort(keys(aws_route_table.private)) : aws_route_table.private[k].id]
  data_route_table_ids     = var.enable_data_subnets ? [for k in sort(keys(aws_route_table.data)) : aws_route_table.data[k].id] : []
  endpoint_route_table_ids = concat(local.private_route_table_ids, local.data_route_table_ids)
  has_interface_endpoints  = length(local.interface_endpoints) > 0
}

resource "aws_security_group" "endpoints" {
  count       = local.has_interface_endpoints ? 1 : 0
  name        = "${var.name_prefix}-vpce-sg"
  description = "Interface endpoint security group"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = local.endpoint_ingress_cidrs
  }

  dynamic "ingress" {
    for_each = var.endpoint_security_group_ids
    content {
      from_port       = 443
      to_port         = 443
      protocol        = "tcp"
      security_groups = [ingress.value]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.name_prefix}-vpce-sg" }
}

resource "aws_vpc_endpoint" "gateway" {
  for_each          = local.gateway_endpoints
  vpc_id            = aws_vpc.vpc.id
  vpc_endpoint_type = each.value.type
  service_name      = "com.amazonaws.${data.aws_region.current.name}.${each.value.service}"
  route_table_ids   = local.endpoint_route_table_ids

  tags = { Name = "${var.name_prefix}-vpce-${each.key}" }
}

resource "aws_vpc_endpoint" "interface" {
  for_each            = local.interface_endpoints
  vpc_id              = aws_vpc.vpc.id
  vpc_endpoint_type   = each.value.type
  service_name        = "com.amazonaws.${data.aws_region.current.name}.${each.value.service}"
  private_dns_enabled = each.value.private_dns_enabled
  subnet_ids          = [for k in sort(keys(aws_subnet.private)) : aws_subnet.private[k].id]
  security_group_ids  = local.has_interface_endpoints ? [aws_security_group.endpoints[0].id] : []

  tags = { Name = "${var.name_prefix}-vpce-${each.key}" }
}

output "vpc_id" { value = aws_vpc.vpc.id }
output "public_subnet_ids" { value = [for k in sort(keys(aws_subnet.public)) : aws_subnet.public[k].id] }
output "private_subnet_ids" { value = [for k in sort(keys(aws_subnet.private)) : aws_subnet.private[k].id] }
output "data_subnet_ids" { value = var.enable_data_subnets ? [for k in sort(keys(aws_subnet.data)) : aws_subnet.data[k].id] : [] }
output "nat_eips" { value = [for k in sort(keys(aws_eip.nat)) : aws_eip.nat[k].public_ip] }
output "public_route_table_ids" { value = local.public_route_table_ids }
output "private_route_table_ids" { value = local.private_route_table_ids }
output "data_route_table_ids" { value = local.data_route_table_ids }
