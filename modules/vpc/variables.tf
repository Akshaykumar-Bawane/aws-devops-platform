variable "project_name" {
  description = "Name of the project, used to tag all resources"
  type        = string
}

variable "env" {
  description = "Environment name: dev, staging, prod"
  type        = string
}

variable "region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "List of CIDRs for public subnets - one per AZ"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "List of CIDRs for private subnets - one per AZ"
  type        = list(string)
}

variable "availability_zones" {
  description = "List of AZs to spread subnets across"
  type        = list(string)
}

variable "enable_nat_gateway" {
  description = "Set to true when testing EKS, false otherwise to save cost"
  type        = bool
  default     = false
}