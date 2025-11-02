terraform {
  required_version = ">= 1.8.0"
  required_providers {
    aws     = { source = "hashicorp/aws", version = "~> 5.0" }
    azurerm = { source = "hashicorp/azurerm", version = "~> 4.0" }
    google  = { source = "hashicorp/google", version = "~> 5.0" }
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
