output "endpoint" {
  value = coalesce(
    try(module.aws[0].endpoint, null)
  )
}

output "port" {
  value = coalesce(
    try(module.aws[0].port, null)
  )
}

output "security_group_id" {
  value = coalesce(
    try(module.aws[0].security_group_id, null)
  )
}
