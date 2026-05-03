module "networking" {
  source      = "../../modules/networking/interface"
  cloud       = var.cloud
  name_prefix = var.name_prefix
  cidr_block  = "10.10.0.0/16"
  subnet_bits = 20
  azs         = var.azs
  az_count    = var.az_count

  single_nat_gateway  = var.single_nat_gateway
  enable_data_subnets = var.enable_data_subnets

  enable_vpc_endpoints        = var.enable_vpc_endpoints
  enabled_vpc_endpoints       = var.enabled_vpc_endpoints
  endpoint_security_group_ids = [aws_security_group.bastion_sg.id]
}
output "net_summary" {
  value = {
    vpc_or_vnet     = module.networking.vpc_id
    public_subnets  = module.networking.public_subnets
    private_subnets = module.networking.private_subnets
    data_subnets    = module.networking.data_subnets
    egress_nat_ips  = module.networking.egress_nat_ips
  }
}
module "storage_docs" {
  source = "../../modules/storage_docs/_impl/aws"

  project     = "wcag"
  environment = "dev"
  region      = var.aws_region
}

module "compute_worker_windows" {
  source             = "../../modules/compute_worker_windows/interface"
  cloud              = var.cloud
  name_prefix        = var.name_prefix
  vpc_id             = module.networking.vpc_id
  private_subnet_ids = module.networking.private_subnets
  instance_type      = var.worker_instance_type
  docs_bucket_arn    = module.storage_docs.bucket_arn
  secrets_arns       = var.worker_secret_arns
}

locals {
  redis_allowed_sg_ids = concat(
    try(module.compute_k8s.node_security_group_ids, []),
    [module.compute_worker_windows.security_group_id]
  )

  postgres_allowed_sg_ids = concat(
    try(module.compute_k8s.node_security_group_ids, []),
    [module.compute_worker_windows.security_group_id]
  )
}

module "cache_redis" {
  source                     = "../../modules/cache_redis/interface"
  cloud                      = var.cloud
  name_prefix                = var.name_prefix
  vpc_id                     = module.networking.vpc_id
  subnet_ids                 = var.redis_subnet_tier == "data" ? module.networking.data_subnets : module.networking.private_subnets
  allowed_security_group_ids = local.redis_allowed_sg_ids
  port                       = var.redis_port
  engine_version             = var.redis_engine_version
  node_type                  = var.redis_node_type
  replica_count              = var.redis_replica_count
  multi_az                   = var.redis_multi_az
}

module "database_postgres" {
  source                     = "../../modules/database_postgres/interface"
  cloud                      = var.cloud
  name_prefix                = var.name_prefix
  vpc_id                     = module.networking.vpc_id
  subnet_ids                 = var.postgres_subnet_tier == "data" ? module.networking.data_subnets : module.networking.private_subnets
  allowed_security_group_ids = local.postgres_allowed_sg_ids
  db_name                    = var.postgres_db_name
  username                   = var.postgres_username
  password                   = var.postgres_password
  port                       = var.postgres_port
  engine_version             = var.postgres_engine_version
  instance_class             = var.postgres_instance_class
  allocated_storage          = var.postgres_allocated_storage
  max_allocated_storage      = var.postgres_max_allocated_storage
  multi_az                   = var.postgres_multi_az
  deletion_protection        = var.postgres_deletion_protection
  backup_retention_period    = var.postgres_backup_retention_period
}

output "docs_bucket_name" { value = module.storage_docs.bucket_name }
output "redis_endpoint" { value = module.cache_redis.endpoint }
output "redis_port" { value = module.cache_redis.port }
output "redis_security_group_id" { value = module.cache_redis.security_group_id }
output "postgres_endpoint" { value = module.database_postgres.endpoint }
output "postgres_port" { value = module.database_postgres.port }
output "postgres_db_name" { value = module.database_postgres.db_name }
output "postgres_username" {
  value     = module.database_postgres.username
  sensitive = true
}
output "postgres_security_group_id" { value = module.database_postgres.security_group_id }
output "worker_instance_id" { value = module.compute_worker_windows.instance_id }
output "worker_security_group_id" { value = module.compute_worker_windows.security_group_id }
