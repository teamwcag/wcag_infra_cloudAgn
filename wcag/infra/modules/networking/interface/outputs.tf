output "vpc_id" {
  value = coalesce(
    try(module.aws[0].vpc_id, null),
    try(module.azure[0].vnet_id, null),
    try(module.gcp[0].network_id, null),
    try(module.selfhosted[0].network_id, null)
  )
}
output "public_subnets" {
  value = coalesce(
    try(module.aws[0].public_subnet_ids, null),
    try(module.azure[0].public_subnet_ids, null),
    try(module.gcp[0].public_subnet_names, null),
    try(module.selfhosted[0].public_subnet_ids, null)
  )
}
output "private_subnets" {
  value = coalesce(
    try(module.aws[0].private_subnet_ids, null),
    try(module.azure[0].private_subnet_ids, null),
    try(module.gcp[0].private_subnet_names, null),
    try(module.selfhosted[0].private_subnet_ids, null)
  )
}
output "data_subnets" {
  value = coalesce(
    try(module.aws[0].data_subnet_ids, null),
    try(module.azure[0].data_subnet_ids, null),
    try(module.gcp[0].data_subnet_names, null),
    try(module.selfhosted[0].data_subnet_ids, null)
  )
}
output "egress_nat_ips" {
  value = coalesce(
    try(module.aws[0].nat_eips, null),
    try(module.azure[0].egress_public_ips, null),
    try(module.gcp[0].nat_external_ips, null),
    try(module.selfhosted[0].egress_ips, null)
  )
}
