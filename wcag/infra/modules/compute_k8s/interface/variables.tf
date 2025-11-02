variable "cloud"              { type = string }   # "aws" | "azure" | "gcp"
variable "name_prefix"        { type = string }
variable "vpc_id"             { type = string }
variable "private_subnet_ids" { type = list(string) }

variable "node_count"   { 
    type = number
    default = 2 
    }
variable "node_min"     { 
    type = number
    default = 1 
    }
variable "node_max"     { 
    type = number 
    default = 4 
    }
variable "node_instance"{ 
    type = string
    default = "t3.large" 
    }
variable "access_entries" {
  type    = map(any)
  default = {}
}
# NEW
variable "api_public_cidrs" {
  description = "CIDRs allowed to reach the EKS public API endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"] # override in envs/dev/compute_k8s.tf
}

# (optional toggles if you want them configurable from env)
variable "endpoint_public_access" {
  description = "Expose EKS API publicly"
  type        = bool
  default     = true
}
variable "endpoint_private_access" {
  description = "Expose EKS API privately"
  type        = bool
  default     = false
}

