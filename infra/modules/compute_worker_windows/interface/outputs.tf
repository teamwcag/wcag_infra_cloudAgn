output "instance_id" {
  value = coalesce(
    try(module.aws[0].instance_id, null)
  )
}

output "private_ip" {
  value = coalesce(
    try(module.aws[0].private_ip, null)
  )
}

output "security_group_id" {
  value = coalesce(
    try(module.aws[0].security_group_id, null)
  )
}

output "iam_role_arn" {
  value = coalesce(
    try(module.aws[0].iam_role_arn, null)
  )
}
