variable "cloud" { type = string }
variable "name_prefix" {
  type    = string
  default = "remed-dev"
}
variable "aws_region" {
  type    = string
  default = "us-east-2"
}
variable "azure_subscription_id" {
  type    = string
  default = null
}
variable "gcp_project" {
  type    = string
  default = null
}
variable "gcp_region" {
  type    = string
  default = null
}
