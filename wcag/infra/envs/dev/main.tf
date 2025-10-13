module "networking" {
  source      = "../../modules/networking/interface"
  cloud       = var.cloud
  name_prefix = var.name_prefix
  cidr_block  = "10.10.0.0/16"
  subnet_bits = 20
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
