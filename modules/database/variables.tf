variable "project_name" {
  description = "Project name for tagging and naming"
  type        = string
}

variable "env" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where RDS will be deployed"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for RDS subnet group"
  type        = list(string)
}

variable "vpc_cidr_block" {
  description = "VPC CIDR - allows internal traffic to RDS"
  type        = string
}

variable "db_name" {
  description = "Name of the initial database"
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "Master username for RDS"
  type        = string
  default     = "admin"
}

variable "db_password" {
  description = "Master password for RDS - never hardcode, pass from tfvars"
  type        = string
  sensitive   = true
}

variable "db_instance_class" {
  description = "RDS instance size - db.t3.micro is free tier"
  type        = string
  default     = "db.t3.micro"
}

variable "db_engine" {
  description = "Database engine type"
  type        = string
  default     = "mysql"
}

variable "db_engine_version" {
  description = "Database engine version"
  type        = string
  default     = "8.0"
}

variable "db_allocated_storage" {
  description = "Storage in GB - 20GB is free tier limit"
  type        = number
  default     = 20
}

variable "multi_az" {
  description = "Enable Multi-AZ for high availability - costs double, false for dev"
  type        = bool
  default     = false
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot on destroy - true for dev, false for prod"
  type        = bool
  default     = true
}

variable "dynamodb_table_name" {
  description = "DynamoDB table name for app use"
  type        = string
  default     = "app-table"
}