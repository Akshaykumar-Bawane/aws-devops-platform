variable "project_name" {
  description = "Project name for tagging and naming"
  type        = string
}

variable "env" {
  description = "Environment name"
  type        = string
}

variable "alarm_email" {
  description = "Email address to receive CloudWatch alarm notifications"
  type        = string
}

variable "rds_instance_id" {
  description = "RDS instance identifier for database alarms"
  type        = string
}

variable "eks_cluster_name" {
  description = "EKS cluster name for container log group"
  type        = string
  default     = ""
}

variable "enable_cloudtrail" {
  description = "Enable CloudTrail for API call logging"
  type        = bool
  default     = true
}

variable "cloudtrail_bucket_name" {
  description = "S3 bucket name to store CloudTrail logs"
  type        = string
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days - lower = less cost"
  type        = number
  default     = 7
}