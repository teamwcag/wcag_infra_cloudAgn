variable "name_prefix" { type = string }
variable "cidr_block" { type = string }
variable "subnet_bits" { type = number }

output "network_id" { value = "${var.name_prefix}-network" }
output "public_subnet_ids" { value = ["${var.name_prefix}-public-0", "${var.name_prefix}-public-1", "${var.name_prefix}-public-2"] }
output "private_subnet_ids" { value = ["${var.name_prefix}-private-0", "${var.name_prefix}-private-1", "${var.name_prefix}-private-2"] }
output "data_subnet_ids" { value = ["${var.name_prefix}-data-0", "${var.name_prefix}-data-1", "${var.name_prefix}-data-2"] }
output "egress_ips" { value = [] }

