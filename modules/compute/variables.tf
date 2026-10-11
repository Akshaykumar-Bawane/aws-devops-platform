variable "project_name" {
  description = "Project name for tagging and naming"
  type        = string
}

variable "env" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where compute resources will be deployed"
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs for bastion EC2"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for EKS node group"
  type        = list(string)
}

variable "bastion_ami" {
  description = "AMI ID for bastion EC2 - use latest Amazon Linux 2 for us-east-1"
  type        = string
}

variable "bastion_instance_type" {
  description = "EC2 instance type - t3.micro is free tier"
  type        = string
  default     = "t3.micro"
}

variable "bastion_instance_profile" {
  description = "IAM instance profile name from security module"
  type        = string
}

variable "key_pair_name" {
  description = "SSH key pair name - must exist in AWS before apply"
  type        = string
}

variable "eks_cluster_version" {
  description = "Kubernetes version for EKS cluster"
  type        = string
  default     = "1.29"
}

variable "eks_cluster_role_arn" {
  description = "IAM role ARN for EKS cluster from security module"
  type        = string
}

variable "eks_node_role_arn" {
  description = "IAM role ARN for EKS node group from security module"
  type        = string
}

variable "eks_node_instance_types" {
  description = "EC2 instance types for EKS worker nodes"
  type        = list(string)
  default     = ["t3.micro"]
}

variable "eks_node_desired" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2
}

variable "eks_node_min" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 1
}

variable "eks_node_max" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 3
}

variable "enable_eks" {
  description = "Create EKS cluster - costs $0.10/hr, destroy after practice"
  type        = bool
  default     = false
}