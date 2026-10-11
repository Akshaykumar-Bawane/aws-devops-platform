# ─────────────────────────────────────────
# S3 BUCKET
# stores app assets, logs, artifacts
# ─────────────────────────────────────────
resource "aws_s3_bucket" "main" {
  bucket        = var.bucket_name
  force_destroy = true

  tags = {
    Name    = var.bucket_name
    Env     = var.env
    Project = var.project_name
  }
}

# Block all public access — production default
# never expose S3 bucket publicly unless
# explicitly serving static website
resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.main.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Versioning — keeps every version of every
# object, protects against accidental deletes
resource "aws_s3_bucket_versioning" "main" {
  bucket = aws_s3_bucket.main.id

  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Suspended"
  }
}

# Server side encryption — all objects
# encrypted at rest using AES256 by default
resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# ─────────────────────────────────────────
# ECR REPOSITORIES
# one repo per microservice
# count loops over ecr_repo_names list
# ─────────────────────────────────────────
resource "aws_ecr_repository" "main" {
  count                = length(var.ecr_repo_names)
  name                 = "${var.project_name}-${var.env}-${var.ecr_repo_names[count.index]}"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name    = "${var.project_name}-${var.env}-${var.ecr_repo_names[count.index]}"
    Env     = var.env
    Project = var.project_name
  }
}

# ECR lifecycle policy — keeps only last 10
# images per repo, older ones auto-deleted
# prevents storage cost creep
resource "aws_ecr_lifecycle_policy" "main" {
  count      = length(var.ecr_repo_names)
  repository = aws_ecr_repository.main[count.index].name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# ─────────────────────────────────────────
# EBS VOLUME
# persistent block storage attached to EC2
# stays alive even if EC2 is stopped
# ─────────────────────────────────────────
resource "aws_ebs_volume" "main" {
  availability_zone = "us-east-1a"
  size              = var.ebs_volume_size
  type              = var.ebs_volume_type
  encrypted         = true

  tags = {
    Name    = "${var.project_name}-${var.env}-ebs"
    Env     = var.env
    Project = var.project_name
  }
}