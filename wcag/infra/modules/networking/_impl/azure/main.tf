# accept interface inputs (even if unused in the stub)
variable "name_prefix" { type = string }
variable "cidr_block"  { type = string }
variable "subnet_bits" { type = number }

# TODO: replace with real Azure impl. For now, outputs keep plan working.
output "vnet_id"            { value = "stub" }
output "public_subnet_ids"  { value = [] }
output "private_subnet_ids" { value = [] }
output "data_subnet_ids"    { value = [] }
output "egress_public_ips"  { value = [] }

