# ─────────────────────────────────────────
# EKS CLUSTER IAM ROLE
# EKS control plane assumes this role to
# manage AWS resources on your behalf
# ─────────────────────────────────────────
resource "aws_iam_role" "eks_cluster" {
  name = "${var.project_name}-${var.env}-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name    = "${var.project_name}-${var.env}-eks-cluster-role"
    Env     = var.env
    Project = var.project_name
  }
}

# Attach AWS managed policy — gives EKS
# permission to manage networking + nodes
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# ─────────────────────────────────────────
# EKS NODE GROUP IAM ROLE
# EC2 worker nodes assume this role to
# pull images, write logs, join the cluster
# ─────────────────────────────────────────
resource "aws_iam_role" "eks_node" {
  name = "${var.project_name}-${var.env}-eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name    = "${var.project_name}-${var.env}-eks-node-role"
    Env     = var.env
    Project = var.project_name
  }
}

# Three policies every EKS node must have
resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  role       = aws_iam_role.eks_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  role       = aws_iam_role.eks_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "eks_ecr_readonly" {
  role       = aws_iam_role.eks_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# ─────────────────────────────────────────
# EC2 BASTION IAM ROLE
# Allows bastion host to call AWS APIs
# e.g. SSM Session Manager, S3 access
# ─────────────────────────────────────────
resource "aws_iam_role" "ec2_bastion" {
  name = "${var.project_name}-${var.env}-bastion-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-${var.env}-bastion-role"
    Env  = var.env
  }
}

resource "aws_iam_role_policy_attachment" "bastion_ssm" {
  role       = aws_iam_role.ec2_bastion.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Instance profile wraps the role so EC2
# can actually use it — roles alone aren't
# enough, EC2 needs an instance profile
resource "aws_iam_instance_profile" "bastion" {
  name = "${var.project_name}-${var.env}-bastion-profile"
  role = aws_iam_role.ec2_bastion.name
}

# ─────────────────────────────────────────
# KMS KEY — optional, costs $1/month
# ─────────────────────────────────────────
resource "aws_kms_key" "main" {
  count                   = var.enable_kms ? 1 : 0
  description             = "${var.project_name}-${var.env} encryption key"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Name = "${var.project_name}-${var.env}-kms"
    Env  = var.env
  }
}

resource "aws_kms_alias" "main" {
  count         = var.enable_kms ? 1 : 0
  name          = "alias/${var.project_name}-${var.env}"
  target_key_id = aws_kms_key.main[0].key_id
}

# ─────────────────────────────────────────
# SECRETS MANAGER — optional, $0.40/month
# stores RDS credentials securely
# ─────────────────────────────────────────
resource "aws_secretsmanager_secret" "db_credentials" {
  count                   = var.enable_secrets_manager ? 1 : 0
  name                    = "${var.project_name}-${var.env}-db-credentials"
  recovery_window_in_days = 0

  tags = {
    Name = "${var.project_name}-${var.env}-db-secret"
    Env  = var.env
  }
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  count     = var.enable_secrets_manager ? 1 : 0
  secret_id = aws_secretsmanager_secret.db_credentials[0].id
  secret_string = jsonencode({
    username = "admin"
    password = var.db_password
  })
}