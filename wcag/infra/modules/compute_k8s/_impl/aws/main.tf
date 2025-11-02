terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
}

data "aws_region" "current" {}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.8"
  # Optional: explicit (it’s the module default)
  authentication_mode = "API_AND_CONFIG_MAP"

  access_entries = var.access_entries

  cluster_name                    = "${var.name_prefix}-eks"
  cluster_version                 = "1.29"
  enable_irsa                     = true
  vpc_id                          = var.vpc_id
  subnet_ids                      = var.private_subnet_ids
  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = false

  eks_managed_node_groups = {
    default = {
      desired_size   = var.node_count
      min_size       = var.node_min
      max_size       = var.node_max
      instance_types = [var.node_instance]
      subnet_ids     = var.private_subnet_ids
    }
  }

  cluster_addons = {
    coredns                = { most_recent = true }
    kube-proxy             = { most_recent = true }
    vpc-cni                = { most_recent = true }
    eks-pod-identity-agent = { most_recent = true }
  }

  tags = { Name = "${var.name_prefix}-eks" }
}

# ... existing resources ...

resource "aws_eks_cluster" "this" {
  name     = "${var.name_prefix}-eks"
  role_arn = aws_iam_role.cluster.arn

   bootstrap_self_managed_addons = false

  vpc_config {
    subnet_ids          = var.private_subnet_ids
    security_group_ids  = [aws_security_group.cluster.id]
    endpoint_public_access  = var.endpoint_public_access
    endpoint_private_access = var.endpoint_private_access
    public_access_cidrs     = var.api_public_cidrs
  }


  # … the rest (k8s version, logging, tags, etc.)
}



locals {
  kubeconfig = yamlencode({
    apiVersion = "v1"
    clusters = [{
      name = module.eks.cluster_name
      cluster = {
        server                       = module.eks.cluster_endpoint
        "certificate-authority-data" = module.eks.cluster_certificate_authority_data
      }
    }]
    contexts = [{
      name = module.eks.cluster_name
      context = {
        cluster = module.eks.cluster_name
        user    = module.eks.cluster_name
      }
    }]
    current-context = module.eks.cluster_name
    kind            = "Config"
    users = [{
      name = module.eks.cluster_name
      user = {
        exec = {
          apiVersion = "client.authentication.k8s.io/v1beta1"
          command    = "aws"
          args = [
            "eks", "get-token",
            "--cluster-name", module.eks.cluster_name,
            "--region", data.aws_region.current.name
          ]
        }
      }
    }]
  })
}
