variable "project_name" {
  description = "Project name"
  type        = string
}

variable "env" {
  description = "Environment name"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDRs"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDRs"
  type        = list(string)
}

variable "availability_zones" {
  description = "AZs to deploy into"
  type        = list(string)
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway - costs money"
  type        = bool
}

variable "enable_eks" {
  description = "Enable EKS cluster - costs money"
  type        = bool
}

variable "enable_kms" {
  description = "Enable KMS key"
  type        = bool
}

variable "enable_secrets_manager" {
  description = "Enable Secrets Manager"
  type        = bool
}

variable "bucket_name" {
  description = "S3 bucket name - must be globally unique"
  type        = string
}

variable "ecr_repo_names" {
  description = "ECR repository names"
  type        = list(string)
}

variable "db_password" {
  description = "RDS master password"
  type        = string
  sensitive   = true
}

variable "bastion_ami" {
  description = "AMI ID for bastion EC2"
  type        = string
}

variable "key_pair_name" {
  description = "SSH key pair name created in AWS console"
  type        = string
}

variable "alarm_email" {
  description = "Email for CloudWatch alarm notifications"
  type        = string
}

variable "cloudtrail_bucket_name" {
  description = "S3 bucket name for CloudTrail logs"
  type        = string
}

variable "bastion_instance_type" {
  description = "EC2 instance type for the bastion host"
  type        = string
  default     = "t3.micro"
}
variable "enable_cloudtrail" {
  description = "Enable CloudTrail"
  type        = bool
  default     = false
}

variable "eks_cluster_version" {
  description = "Kubernetes version for EKS cluster"
  type        = string
  default     = "1.36"
}

variable "eks_node_desired" {
  description = "Desired number of EKS worker nodes"
  type        = number
  default     = 2
}

variable "eks_node_max" {
  description = "Maximum number of EKS worker nodes"
  type        = number
  default     = 4
}

variable "enable_ansible_fleet" {
  description = "Create the 2 Ansible practice nodes"
  type        = bool
  default     = false
}