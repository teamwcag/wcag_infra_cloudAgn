module "aws" {
  source = "../_impl/aws"
  count  = var.cloud == "aws" ? 1 : 0

  name_prefix                = var.name_prefix
  vpc_id                     = var.vpc_id
  subnet_ids                 = var.subnet_ids
  allowed_security_group_ids = var.allowed_security_group_ids
  db_name                    = var.db_name
  username                   = var.username
  password                   = var.password
  port                       = var.port
  engine_version             = var.engine_version
  instance_class             = var.instance_class
  allocated_storage          = var.allocated_storage
  max_allocated_storage      = var.max_allocated_storage
  multi_az                   = var.multi_az
  deletion_protection        = var.deletion_protection
  backup_retention_period    = var.backup_retention_period
}
