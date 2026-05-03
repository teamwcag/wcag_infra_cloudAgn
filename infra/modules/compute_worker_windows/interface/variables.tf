variable "cloud" { type = string }
variable "name_prefix" { type = string }
variable "vpc_id" { type = string }
variable "private_subnet_ids" { type = list(string) }

variable "subnet_id" {
  type        = string
  description = "Optional specific subnet to place the worker in"
  default     = null
}

variable "instance_type" {
  type        = string
  description = "Windows worker instance type"
  default     = "t3.large"
}

variable "docs_bucket_arn" {
  type        = string
  description = "S3 bucket ARN for document storage"
}

variable "secrets_arns" {
  type        = list(string)
  description = "Optional list of Secrets Manager ARNs for the worker to read"
  default     = []
}

variable "additional_security_group_ids" {
  type        = list(string)
  description = "Additional security groups to attach to the worker"
  default     = []
}

variable "user_data" {
  type        = string
  description = "Optional user data for Windows bootstrap"
  default     = null
}
