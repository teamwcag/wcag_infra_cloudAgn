variable "name_prefix" {}
variable "cidr_block" {}
variable "subnet_bits" {}

data "aws_availability_zones" "az" { state = "available" }

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
  azs = slice(data.aws_availability_zones.az.names, 0, 3)

  # /16 → /20 means 4 new bits → 16 total subnets (0..15).
  # Allocate ranges:
  #   public  : 0..2
  #   private : 4..6
  #   data    : 8..10
  public_cidrs  = [for i in range(3) : cidrsubnet(var.cidr_block, (var.subnet_bits - 16), i)]
  private_cidrs = [for i in range(3) : cidrsubnet(var.cidr_block, (var.subnet_bits - 16), 4 + i)]
  data_cidrs    = [for i in range(3) : cidrsubnet(var.cidr_block, (var.subnet_bits - 16), 8 + i)]

  # helper map for for_each
  indices = { for i in range(3) : tostring(i) => i }
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
  for_each          = local.indices
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = local.data_cidrs[each.value]
  availability_zone = local.azs[each.value]
  tags              = { Name = "${var.name_prefix}-data-${each.value}" }
}

resource "aws_eip" "nat" {
  count  = 1
  domain = "vpc" # replaces vpc = true
  tags   = { Name = "${var.name_prefix}-nat-eip" }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public["0"].id
  depends_on    = [aws_internet_gateway.igw]
  tags          = { Name = "${var.name_prefix}-nat" }
}


resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}
resource "aws_route_table_association" "public_assoc" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
}
resource "aws_route_table_association" "private_assoc" {
  for_each       = aws_subnet.private
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table" "data" {
  vpc_id = aws_vpc.vpc.id
}

resource "aws_route_table_association" "data_assoc" {
  for_each       = aws_subnet.data
  subnet_id      = each.value.id
  route_table_id = aws_route_table.data.id
}

output "vpc_id" { value = aws_vpc.vpc.id }
output "public_subnet_ids" { value = [for s in aws_subnet.public : s.id] }
output "private_subnet_ids" { value = [for s in aws_subnet.private : s.id] }
output "data_subnet_ids" { value = [for s in aws_subnet.data : s.id] }
output "nat_eips" { value = [aws_eip.nat[0].public_ip] }
