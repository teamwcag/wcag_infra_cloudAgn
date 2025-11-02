variable "name_prefix"        { type = string }
variable "vpc_id"             { type = string }
variable "private_subnet_ids" { type = list(string) }
variable "node_count"         { type = number }
variable "node_min"           { type = number }
variable "node_max"           { type = number }
variable "node_instance"      { type = string }