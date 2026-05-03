variable "project" {
  type        = string
  description = "wcag"
}

variable "environment" {
  type        = string
  description = "Environment name, e.g. dev/stage/prod"
}

variable "region" {
  type        = string
  description = "AWS region"
  default     = "us-east-2"
}

variable "versioning_enabled" {
  type    = bool
  default = true
}

variable "lifecycle_days_current" {
  type    = number
  default = 30
}

variable "lifecycle_days_expire" {
  type    = number
  default = 365
}
