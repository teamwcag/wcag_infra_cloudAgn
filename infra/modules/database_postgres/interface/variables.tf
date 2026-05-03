variable "cloud" { type = string }
variable "name_prefix" { type = string }
variable "vpc_id" { type = string }
variable "subnet_ids" { type = list(string) }

variable "allowed_security_group_ids" {
  type        = list(string)
  description = "Security groups allowed to access Postgres"
  default     = []
}

variable "db_name" {
  type        = string
  description = "Initial database name"
  default     = "wcag_document"
}

variable "username" {
  type        = string
  description = "Master username"
  default     = "wcag"
}

variable "password" {
  type        = string
  description = "Master password"
  sensitive   = true
}

variable "port" {
  type        = number
  description = "Postgres port"
  default     = 5432
}

variable "engine_version" {
  type        = string
  description = "Postgres engine version"
  default     = "16"
}

variable "instance_class" {
  type        = string
  description = "RDS instance class"
  default     = "db.t4g.small"
}

variable "allocated_storage" {
  type        = number
  description = "Initial allocated storage in GB"
  default     = 20
}

variable "max_allocated_storage" {
  type        = number
  description = "Autoscaling max storage in GB"
  default     = 100
}

variable "multi_az" {
  type        = bool
  description = "Enable Multi-AZ"
  default     = false
}

variable "deletion_protection" {
  type        = bool
  description = "Enable deletion protection"
  default     = false
}

variable "backup_retention_period" {
  type        = number
  description = "Backup retention in days"
  default     = 1
}
