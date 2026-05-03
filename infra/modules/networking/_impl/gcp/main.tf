variable "name_prefix" { type = string }
variable "cidr_block" { type = string }
variable "subnet_bits" { type = number }

output "network_id" { value = "stub" }
output "public_subnet_names" { value = [] }
output "private_subnet_names" { value = [] }
output "data_subnet_names" { value = [] }
output "nat_external_ips" { value = [] }

