output "instance_id" { value = aws_instance.worker.id }
output "private_ip" { value = aws_instance.worker.private_ip }
output "security_group_id" { value = aws_security_group.worker.id }
output "iam_role_arn" { value = aws_iam_role.worker.arn }
