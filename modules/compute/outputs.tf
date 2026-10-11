output "bastion_public_ip" {
  description = "Public IP of bastion - use this to SSH in"
  value       = aws_instance.bastion.public_ip
}

output "bastion_instance_id" {
  description = "Bastion EC2 instance ID"
  value       = aws_instance.bastion.id
}

output "eks_cluster_name" {
  description = "EKS cluster name - used for kubectl config"
  value       = var.enable_eks ? aws_eks_cluster.main[0].name : null
}

output "eks_cluster_endpoint" {
  description = "EKS API server endpoint"
  value       = var.enable_eks ? aws_eks_cluster.main[0].endpoint : null
}

output "eks_cluster_ca" {
  description = "EKS cluster certificate authority data"
  value       = var.enable_eks ? aws_eks_cluster.main[0].certificate_authority[0].data : null
}

output "eks_node_group_status" {
  description = "EKS node group current status"
  value       = var.enable_eks ? aws_eks_node_group.main[0].status : null
}