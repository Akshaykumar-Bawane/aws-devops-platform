variable "project_name" {
  description = "Project name for tagging and naming"
  type        = string
}

variable "env" {
  description = "Environment name"
  type        = string
}

variable "bucket_name" {
  description = "Globally unique S3 bucket name"
  type        = string
}

variable "enable_versioning" {
  description = "Enable S3 versioning - protects against accidental deletes"
  type        = bool
  default     = true
}

variable "ecr_repo_names" {
  description = "List of ECR repository names - one per microservice"
  type        = list(string)
  default     = ["app"]
}

variable "ebs_volume_size" {
  description = "Size of EBS volume in GB - 30GB is free tier limit"
  type        = number
  default     = 20
}

variable "ebs_volume_type" {
  description = "EBS volume type - gp2 is free tier, gp3 is faster and cheaper"
  type        = string
  default     = "gp2"
}