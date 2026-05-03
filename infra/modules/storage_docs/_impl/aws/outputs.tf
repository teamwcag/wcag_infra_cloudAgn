output "bucket_name" {
  value       = aws_s3_bucket.documents.id
  description = "Name of the S3 bucket used for document storage"
}

output "bucket_arn" {
  value       = aws_s3_bucket.documents.arn
  description = "ARN of the S3 bucket used for document storage"
}

