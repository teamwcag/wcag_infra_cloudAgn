variable "cloud" { type = string } # "aws" | "azure" | "gcp" | "selfhosted"
variable "name_prefix" { type = string }
variable "cidr_block" {
  type = string
  default = "10.10.0.0/16"
}  # ← This closing brace was missing

variable "subnet_bits" {
  type = number
  default = 20
  # /20s from the /16
}
