output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

output "bastion_public_ip" {
  description = "SSH into bastion using this IP"
  value       = module.compute.bastion_public_ip
}

output "rds_endpoint" {
  description = "RDS connection string for your app"
  value       = module.database.rds_endpoint
}

output "ecr_urls" {
  description = "ECR URLs for docker push"
  value       = module.storage.ecr_repository_urls
}

output "sns_topic_arn" {
  description = "SNS topic for alarms"
  value       = module.observability.sns_topic_arn
}

output "fleet_private_ips" {
  value = module.fleet.private_ips
}