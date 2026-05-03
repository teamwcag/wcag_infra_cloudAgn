module "aws" {
  source = "../_impl/aws"
  count  = var.cloud == "aws" ? 1 : 0

  name_prefix                = var.name_prefix
  vpc_id                     = var.vpc_id
  subnet_ids                 = var.subnet_ids
  allowed_security_group_ids = var.allowed_security_group_ids
  port                       = var.port
  engine_version             = var.engine_version
  node_type                  = var.node_type
  replica_count              = var.replica_count
  multi_az                   = var.multi_az
}
