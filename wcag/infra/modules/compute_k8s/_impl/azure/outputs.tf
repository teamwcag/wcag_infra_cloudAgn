# TODO: azurerm_kubernetes_cluster with Workload Identity, Azure CNI in private subnets.
output "cluster_name"            { value = null }
output "kubeconfig"              { 
    value = null
    sensitive = true 
    }
output "node_security_group_ids" { value = [] }
