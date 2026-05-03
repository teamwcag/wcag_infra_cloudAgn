terraform {
  required_version = ">= 1.8.0"
  required_providers {
    aws        = { source = "hashicorp/aws", version = "~> 5.0" }
    helm       = { source = "hashicorp/helm", version = "~> 2.14" }
    kubernetes = { source = "hashicorp/kubernetes", version = "~> 2.30" }
    azurerm    = { source = "hashicorp/azurerm", version = "~> 4.0" }
    google     = { source = "hashicorp/google", version = "~> 5.0" }
  }
  backend "s3" {
    bucket  = "remed-tfstate-dev"
    key     = "networking/terraform.tfstate"
    region  = "us-east-2"
    encrypt = true
    # dynamodb_table = "remed-tf-locks"   # old, will warn but still works
    use_lockfile = true # new style, preferred
  }

}
provider "aws" { region = var.aws_region }
#provider "azurerm" { features {} subscription_id = var.azure_subscription_id }
#provider "google"  { project = var.gcp_project region = var.gcp_region }

data "aws_eks_cluster" "this" {
  name = module.compute_k8s.cluster_name
}

data "aws_eks_cluster_auth" "this" {
  name = module.compute_k8s.cluster_name
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.this.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.this.token
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.this.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}
