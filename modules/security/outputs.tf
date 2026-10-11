output "eks_cluster_role_arn" {
  description = "ARN of EKS cluster IAM role"
  value       = aws_iam_role.eks_cluster.arn
}

output "eks_node_role_arn" {
  description = "ARN of EKS node group IAM role"
  value       = aws_iam_role.eks_node.arn
}

output "bastion_instance_profile_name" {
  description = "Instance profile name for bastion EC2"
  value       = aws_iam_instance_profile.bastion.name
}

output "kms_key_arn" {
  description = "KMS key ARN - null if not enabled"
  value       = var.enable_kms ? aws_kms_key.main[0].arn : null
}

output "db_secret_arn" {
  description = "Secrets Manager ARN - null if not enabled"
  value       = var.enable_secrets_manager ? aws_secretsmanager_secret.db_credentials[0].arn : null
}