output "cluster_name" { value = module.eks.cluster_name }
output "kubeconfig" {
  value     = local.kubeconfig
  sensitive = true
}
output "node_security_group_ids" { value = module.eks.node_security_group_id != null ? [module.eks.node_security_group_id] : [] }
output "oidc_provider_arn" { value = module.eks.oidc_provider_arn }
