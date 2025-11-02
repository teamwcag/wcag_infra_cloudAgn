variable "name_prefix" { type = string }
variable "vpc_id" { type = string }
variable "private_subnet_ids" { type = list(string) }
variable "node_count" { type = number }
variable "node_min" { type = number }
variable "node_max" { type = number }
variable "node_instance" { type = string }
variable "aws_auth_roles" {
  type    = list(any)
  default = []
}
variable "access_entries" {
  description = "EKS access entries (v20+): map of principals and their k8s groups/policies"
  type        = map(any)
  default     = {}
}
# add this if not present
variable "api_public_cidrs" {
  type        = list(string)
  description = "CIDRs allowed to reach the EKS public API endpoint"
  default     = ["0.0.0.0/0"]
}

variable "endpoint_public_access" {
  type        = bool
  description = "Expose EKS API publicly"
  default     = true
}

variable "endpoint_private_access" {
  type        = bool
  description = "Expose EKS API privately"
  default     = false
}

