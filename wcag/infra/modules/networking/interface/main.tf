module "aws" {
  source      = "../_impl/aws"
  count       = var.cloud == "aws" ? 1 : 0
  name_prefix = var.name_prefix
  cidr_block  = var.cidr_block
  subnet_bits = var.subnet_bits
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
