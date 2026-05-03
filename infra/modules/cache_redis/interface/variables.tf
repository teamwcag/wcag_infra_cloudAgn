variable "cloud" { type = string }
variable "name_prefix" { type = string }
variable "vpc_id" { type = string }
variable "subnet_ids" { type = list(string) }

variable "allowed_security_group_ids" {
  type        = list(string)
  description = "Security groups allowed to access Redis"
  default     = []
}

variable "port" {
  type        = number
  description = "Redis port"
  default     = 6379
}

variable "engine_version" {
  type        = string
  description = "Redis engine version"
  default     = "7.1"
}

variable "node_type" {
  type        = string
  description = "Redis node instance type"
  default     = "cache.t3.small"
}

variable "replica_count" {
  type        = number
  description = "Number of replicas for the primary node (0 = no replicas)"
  default     = 0
}

variable "multi_az" {
  type        = bool
  description = "Enable Multi-AZ for Redis"
  default     = false
}
