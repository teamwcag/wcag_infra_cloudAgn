output "cluster_name" {
  value = coalesce(
    try(module.aws[0].cluster_name, null),
    try(module.azure[0].cluster_name, null),
    try(module.gcp[0].cluster_name, null)
  )
}

output "kubeconfig" {
  value     = coalesce(
    try(module.aws[0].kubeconfig, null),
    try(module.azure[0].kubeconfig, null),
    try(module.gcp[0].kubeconfig, null)
  )
  sensitive = true
}

output "node_security_group_ids" {
  value = coalesce(
    try(module.aws[0].node_security_group_ids, null),
    try(module.azure[0].node_security_group_ids, null),
    try(module.gcp[0].node_security_group_ids, null)
  )
}
