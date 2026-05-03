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

output "db_name" {
  value = coalesce(
    try(module.aws[0].db_name, null)
  )
}

output "username" {
  value = coalesce(
    try(module.aws[0].username, null)
  )
  sensitive = true
}

output "security_group_id" {
  value = coalesce(
    try(module.aws[0].security_group_id, null)
  )
}
