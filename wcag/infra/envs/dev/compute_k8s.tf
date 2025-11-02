module "compute_k8s" {
  source                  = "../../modules/compute_k8s/interface"
  cloud                   = var.cloud
  name_prefix             = var.name_prefix
  api_public_cidrs        = ["205.178.5.43/32"]
  endpoint_public_access  = true
  endpoint_private_access = false
  vpc_id                  = module.networking.vpc_id
  private_subnet_ids      = module.networking.private_subnets

  node_count    = 2
  node_min      = 1
  node_max      = 3
  node_instance = "t3.large"


  access_entries = {
    bastion-admin = {
      principal_arn = aws_iam_role.bastion_role.arn

      # Give full cluster admin via EKS Access Policy
      policy_associations = {
        admin = {
          policy_arn   = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = { type = "cluster" }
        }
      }
    }
  }
}

output "k8s_cluster_name" { value = module.compute_k8s.cluster_name }
output "kubeconfig" {
  value     = module.compute_k8s.kubeconfig
  sensitive = true
}
