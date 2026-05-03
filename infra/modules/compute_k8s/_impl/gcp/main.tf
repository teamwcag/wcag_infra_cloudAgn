variable "name_prefix" { type = string }
variable "vpc_id" { type = string }
variable "private_subnet_ids" { type = list(string) }
variable "node_count" { type = number }
variable "node_min" { type = number }
variable "node_max" { type = number }
variable "node_instance" { type = string }

# TODO: google_container_cluster (GKE / Autopilot) with Workload Identity.
output "cluster_name" { value = null }
output "kubeconfig" {
  value     = null
  sensitive = true
}
output "node_security_group_ids" { value = [] }
