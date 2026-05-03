variable "name_prefix" { type = string }
variable "vpc_id" { type = string }
variable "private_subnet_ids" { type = list(string) }
variable "cluster_version" { type = string }
variable "node_count" { type = number }
variable "node_min" { type = number }
variable "node_max" { type = number }
variable "node_instance" { type = string }
variable "access_entries" {
  type    = map(any)
  default = {}
}
variable "api_public_cidrs" {
  type = list(string)
}
variable "endpoint_public_access" {
  type = bool
}
variable "endpoint_private_access" {
  type = bool
}
variable "docs_bucket_arn" {
  type = string
}
