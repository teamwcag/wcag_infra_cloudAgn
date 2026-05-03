variable "name_prefix" { type = string }
variable "vpc_id" { type = string }
variable "subnet_ids" { type = list(string) }
variable "allowed_security_group_ids" { type = list(string) }
variable "port" { type = number }
variable "engine_version" { type = string }
variable "node_type" { type = string }
variable "replica_count" { type = number }
variable "multi_az" {
  type = bool
  validation {
    condition     = !(var.multi_az && var.replica_count == 0)
    error_message = "multi_az=true requires replica_count >= 1"
  }
}

variable "tags" {
  type        = map(string)
  description = "Extra tags for Redis resources"
  default     = {}
}
