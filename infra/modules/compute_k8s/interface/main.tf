
module "aws" {
  source = "../_impl/aws"
  count  = var.cloud == "aws" ? 1 : 0

  # pass-throughs you already had …
  name_prefix        = var.name_prefix
  vpc_id             = var.vpc_id
  private_subnet_ids = var.private_subnet_ids
  cluster_version    = var.cluster_version
  node_count         = var.node_count
  node_min           = var.node_min
  node_max           = var.node_max
  node_instance      = var.node_instance

  # NEW pass-throughs
  api_public_cidrs        = var.api_public_cidrs
  endpoint_public_access  = var.endpoint_public_access
  endpoint_private_access = var.endpoint_private_access
  docs_bucket_arn         = var.docs_bucket_arn
}

module "azure" {
  source = "../_impl/azure"
  count  = var.cloud == "azure" ? 1 : 0

  name_prefix        = var.name_prefix
  vpc_id             = var.vpc_id
  private_subnet_ids = var.private_subnet_ids
  node_count         = var.node_count
  node_min           = var.node_min
  node_max           = var.node_max
  node_instance      = var.node_instance
}

module "gcp" {
  source = "../_impl/gcp"
  count  = var.cloud == "gcp" ? 1 : 0

  name_prefix        = var.name_prefix
  vpc_id             = var.vpc_id
  private_subnet_ids = var.private_subnet_ids
  node_count         = var.node_count
  node_min           = var.node_min
  node_max           = var.node_max
  node_instance      = var.node_instance
}
