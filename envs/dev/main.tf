# ─────────────────────────────────────────
# VPC MODULE
# always first — everything depends on it
# ─────────────────────────────────────────
module "vpc" {
  source = "../../modules/vpc"

  project_name         = var.project_name
  env                  = var.env
  region               = var.region
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
  enable_nat_gateway   = var.enable_nat_gateway
}

# ─────────────────────────────────────────
# SECURITY MODULE
# IAM roles needed before compute launches
# ─────────────────────────────────────────
module "security" {
  source = "../../modules/security"

  project_name           = var.project_name
  env                    = var.env
  enable_kms             = var.enable_kms
  enable_secrets_manager = var.enable_secrets_manager
  db_password            = var.db_password
}

# ─────────────────────────────────────────
# STORAGE MODULE
# S3, ECR, EBS
# ─────────────────────────────────────────
module "storage" {
  source = "../../modules/storage"

  project_name   = var.project_name
  env            = var.env
  bucket_name    = var.bucket_name
  ecr_repo_names = var.ecr_repo_names
}

# ─────────────────────────────────────────
# DATABASE MODULE
# RDS in private subnets
# depends on vpc for subnet IDs
# ─────────────────────────────────────────
module "database" {
  source = "../../modules/database"

  project_name       = var.project_name
  env                = var.env
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  vpc_cidr_block     = module.vpc.vpc_cidr_block
  db_password        = var.db_password
}

# ─────────────────────────────────────────
# COMPUTE MODULE
# EC2 bastion + EKS
# depends on vpc and security modules
# ─────────────────────────────────────────
module "compute" {
  source = "../../modules/compute"

  project_name             = var.project_name
  env                      = var.env
  vpc_id                   = module.vpc.vpc_id
  public_subnet_ids        = module.vpc.public_subnet_ids
  private_subnet_ids       = module.vpc.private_subnet_ids
  bastion_ami              = var.bastion_ami
  key_pair_name            = var.key_pair_name
  bastion_instance_profile = module.security.bastion_instance_profile_name
  eks_cluster_role_arn     = module.security.eks_cluster_role_arn
  eks_node_role_arn        = module.security.eks_node_role_arn
  enable_eks               = var.enable_eks
  eks_cluster_version      = var.eks_cluster_version
  eks_node_desired         = var.eks_node_desired
  eks_node_max     = var.eks_node_max
}

# ─────────────────────────────────────────
# OBSERVABILITY MODULE
# CloudWatch, CloudTrail, SNS alarms
# depends on compute for RDS instance ID
# ─────────────────────────────────────────
module "observability" {
  source = "../../modules/observability"

  project_name           = var.project_name
  env                    = var.env
  alarm_email            = var.alarm_email
  rds_instance_id        = module.database.rds_endpoint
  eks_cluster_name       = module.compute.eks_cluster_name
  cloudtrail_bucket_name = var.cloudtrail_bucket_name
  enable_cloudtrail      = var.enable_cloudtrail
}