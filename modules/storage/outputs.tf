output "bucket_id" {
  description = "S3 bucket name"
  value       = aws_s3_bucket.main.id
}

output "bucket_arn" {
  description = "S3 bucket ARN"
  value       = aws_s3_bucket.main.arn
}

output "ecr_repository_urls" {
  description = "List of ECR repository URLs for docker push"
  value       = aws_ecr_repository.main[*].repository_url
}

output "ebs_volume_id" {
  description = "EBS volume ID for attaching to EC2"
  value       = aws_ebs_volume.main.id
}