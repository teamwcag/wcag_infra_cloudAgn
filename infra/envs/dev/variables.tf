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

variable "redis_subnet_tier" {
  type        = string
  default     = "data"
  description = "Subnet tier for Redis: \"data\" or \"private\""
}

variable "az_count" {
  type    = number
  default = 3
}

variable "azs" {
  type    = list(string)
  default = []
}

variable "single_nat_gateway" {
  type    = bool
  default = false
}

variable "enable_data_subnets" {
  type    = bool
  default = true
}

variable "enable_vpc_endpoints" {
  type    = bool
  default = true
}

variable "enabled_vpc_endpoints" {
  type    = list(string)
  default = ["s3", "ecr.api", "ecr.dkr"]
}

variable "redis_node_type" {
  type    = string
  default = "cache.t3.small"
}
variable "redis_engine_version" {
  type    = string
  default = "7.1"
}
variable "redis_replica_count" {
  type    = number
  default = 0
}
variable "redis_multi_az" {
  type    = bool
  default = false
}
variable "redis_port" {
  type    = number
  default = 6379
}
variable "postgres_subnet_tier" {
  type        = string
  default     = "data"
  description = "Subnet tier for Postgres: \"data\" or \"private\""
}
variable "postgres_db_name" {
  type    = string
  default = "wcag_document"
}
variable "postgres_username" {
  type    = string
  default = "wcag"
}
variable "postgres_password" {
  type      = string
  sensitive = true
}
variable "postgres_port" {
  type    = number
  default = 5432
}
variable "postgres_engine_version" {
  type    = string
  default = "16"
}
variable "postgres_instance_class" {
  type    = string
  default = "db.t4g.small"
}
variable "postgres_allocated_storage" {
  type    = number
  default = 20
}
variable "postgres_max_allocated_storage" {
  type    = number
  default = 100
}
variable "postgres_multi_az" {
  type    = bool
  default = false
}
variable "postgres_deletion_protection" {
  type    = bool
  default = false
}
variable "postgres_backup_retention_period" {
  type    = number
  default = 1
}
variable "worker_instance_type" {
  type    = string
  default = "t3.large"
}
variable "worker_secret_arns" {
  type    = list(string)
  default = []
}

variable "app_hostname" {
  type    = string
  default = "app.wcagremedy.com"
}

variable "app_https_enabled" {
  type    = bool
  default = false
}

variable "app_acm_certificate_arn" {
  type    = string
  default = ""
}

variable "app_acm_certificate_create" {
  type    = bool
  default = false
}

variable "app_acm_ssl_policy" {
  type    = string
  default = "ELBSecurityPolicy-TLS13-1-2-2021-06"
}

variable "document_service_image_repository" {
  type    = string
  default = "docker.io/wcagabhinav/document-service"
}

variable "document_service_image_tag" {
  type    = string
  default = "1.0.14"
}

variable "frontend_image_repository" {
  type    = string
  default = "docker.io/wcagabhinav/wcag-remediator-frontend"
}

variable "frontend_image_tag" {
  type    = string
  default = "0.0.1"
}

variable "token_service_image_repository" {
  type    = string
  default = "docker.io/wcagabhinav/token-service"
}

variable "token_service_image_tag" {
  type    = string
  default = "0.0.1"
}

variable "document_service_callback_base_url" {
  type    = string
  default = "http://acbf826e5f3354543bf424abc63cef27-1924773936.us-east-2.elb.amazonaws.com"
}
