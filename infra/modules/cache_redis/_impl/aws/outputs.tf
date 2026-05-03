output "endpoint" { value = aws_elasticache_replication_group.redis.primary_endpoint_address }
output "port" { value = aws_elasticache_replication_group.redis.port }
output "security_group_id" { value = aws_security_group.redis.id }
