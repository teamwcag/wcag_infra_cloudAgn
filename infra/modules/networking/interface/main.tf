module "aws" {
  source      = "../_impl/aws"
  count       = var.cloud == "aws" ? 1 : 0
  name_prefix = var.name_prefix
  cidr_block  = var.cidr_block
  subnet_bits = var.subnet_bits
  az_count    = var.az_count
  azs         = var.azs

  single_nat_gateway  = var.single_nat_gateway
  enable_data_subnets = var.enable_data_subnets

  enable_vpc_endpoints        = var.enable_vpc_endpoints
  enabled_vpc_endpoints       = var.enabled_vpc_endpoints
  endpoint_ingress_cidrs      = var.endpoint_ingress_cidrs
  endpoint_security_group_ids = var.endpoint_security_group_ids
}

module "azure" {
  source      = "../_impl/azure"
  count       = var.cloud == "azure" ? 1 : 0
  name_prefix = var.name_prefix
  cidr_block  = var.cidr_block
  subnet_bits = var.subnet_bits
}
module "gcp" {
  source      = "../_impl/gcp"
  count       = var.cloud == "gcp" ? 1 : 0
  name_prefix = var.name_prefix
  cidr_block  = var.cidr_block
  subnet_bits = var.subnet_bits
}
module "selfhosted" {
  source      = "../_impl/selfhosted"
  count       = var.cloud == "selfhosted" ? 1 : 0
  name_prefix = var.name_prefix
  cidr_block  = var.cidr_block
  subnet_bits = var.subnet_bits
}
