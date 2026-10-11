variable "project_name" {
  description = "Project name for tagging"
  type        = string
}

variable "env" {
  description = "Environment name"
  type        = string
}

variable "enable_kms" {
  description = "Create KMS key for encryption - costs $1/month, disable for practice"
  type        = bool
  default     = false
}

variable "enable_secrets_manager" {
  description = "Create Secrets Manager secret - costs $0.40/month per secret"
  type        = bool
  default     = false
}

variable "db_password" {
  description = "RDS database password stored in Secrets Manager"
  type        = string
  sensitive   = true
  default     = ""
}