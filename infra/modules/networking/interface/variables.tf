variable "cloud" { type = string } # "aws" | "azure" | "gcp" | "selfhosted"
variable "name_prefix" { type = string }
variable "cidr_block" {
  type    = string
  default = "10.10.0.0/16"
} # ← This closing brace was missing

variable "subnet_bits" {
  type    = number
  default = 20
  # /20s from the /16
}

variable "az_count" {
  type        = number
  default     = 3
  description = "Number of AZs to use when azs list is not provided"
}

variable "azs" {
  type        = list(string)
  default     = []
  description = "Optional explicit AZ list (e.g., [\"us-east-2a\",\"us-east-2b\"])"
}

variable "single_nat_gateway" {
  type        = bool
  default     = false
  description = "If true, create a single NAT gateway for all private subnets"
}

variable "enable_data_subnets" {
  type        = bool
  default     = true
  description = "If false, skip data subnets and related route tables"
}

variable "enable_vpc_endpoints" {
  type        = bool
  default     = true
  description = "Enable VPC endpoints in the VPC"
}

variable "enabled_vpc_endpoints" {
  type        = list(string)
  default     = ["s3", "ecr.api", "ecr.dkr"]
  description = "List of AWS endpoint short names to enable (e.g., s3, ecr.api, ecr.dkr, logs, monitoring, sts, kms, ec2, autoscaling)"
}

variable "endpoint_ingress_cidrs" {
  type        = list(string)
  default     = []
  description = "CIDR blocks allowed to reach interface endpoints on 443 (defaults to VPC CIDR)"
}

variable "endpoint_security_group_ids" {
  type        = list(string)
  default     = []
  description = "Security groups allowed to reach interface endpoints on 443"
}
