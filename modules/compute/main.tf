# ─────────────────────────────────────────
# BASTION SECURITY GROUP
# allows SSH from anywhere into bastion
# bastion is the ONLY entry point to
# private resources like RDS and EKS nodes
# ─────────────────────────────────────────
resource "aws_security_group" "bastion" {
  name        = "${var.project_name}-${var.env}-bastion-sg"
  description = "Security group for bastion host"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH from anywhere - restrict to your IP in production"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project_name}-${var.env}-bastion-sg"
    Env     = var.env
    Project = var.project_name
  }
}

# ─────────────────────────────────────────
# BASTION EC2 INSTANCE
# sits in public subnet
# jumpbox to reach private resources
# t2.micro = free tier
# ─────────────────────────────────────────
resource "aws_instance" "bastion" {
  ami                    = var.bastion_ami
  instance_type          = var.bastion_instance_type
  subnet_id              = var.public_subnet_ids[0]
  vpc_security_group_ids = [aws_security_group.bastion.id]
  iam_instance_profile   = var.bastion_instance_profile
  key_name               = var.key_pair_name

  root_block_device {
    volume_size           = 8
    volume_type           = "gp2"
    encrypted             = true
    delete_on_termination = true
  }

  metadata_options {
    http_tokens = "required"
  }

  tags = {
    Name    = "${var.project_name}-${var.env}-bastion"
    Env     = var.env
    Project = var.project_name
  }
}

# ─────────────────────────────────────────
# EKS CLUSTER
# managed Kubernetes control plane
# AWS manages etcd, api-server, scheduler
# you only manage worker nodes
# ─────────────────────────────────────────
resource "aws_eks_cluster" "main" {
  count    = var.enable_eks ? 1 : 0
  name     = "${var.project_name}-${var.env}-eks"
  role_arn = var.eks_cluster_role_arn
  version  = var.eks_cluster_version

  vpc_config {
    subnet_ids              = concat(var.public_subnet_ids, var.private_subnet_ids)
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  enabled_cluster_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]

  tags = {
    Name    = "${var.project_name}-${var.env}-eks"
    Env     = var.env
    Project = var.project_name
  }

  depends_on = [var.eks_cluster_role_arn]
}

# ─────────────────────────────────────────
# EKS NODE GROUP
# managed group of EC2 worker nodes
# nodes live in private subnets
# AWS handles node provisioning and updates
# ─────────────────────────────────────────
resource "aws_eks_node_group" "main" {
  count           = var.enable_eks ? 1 : 0
  cluster_name    = aws_eks_cluster.main[0].name
  node_group_name = "${var.project_name}-${var.env}-node-group"
  node_role_arn   = var.eks_node_role_arn
  subnet_ids      = var.private_subnet_ids
  instance_types  = var.eks_node_instance_types

  scaling_config {
    desired_size = var.eks_node_desired
    min_size     = var.eks_node_min
    max_size     = var.eks_node_max
  }

  update_config {
    max_unavailable = 1
  }

  tags = {
    Name    = "${var.project_name}-${var.env}-node-group"
    Env     = var.env
    Project = var.project_name
  }

  depends_on = [aws_eks_cluster.main]
}

# ─────────────────────────────────────────
# EKS SECURITY GROUP
# controls traffic to EKS nodes
# nodes need to talk to each other
# and to the control plane
# ─────────────────────────────────────────
resource "aws_security_group" "eks_nodes" {
  count       = var.enable_eks ? 1 : 0
  name        = "${var.project_name}-${var.env}-eks-nodes-sg"
  description = "Security group for EKS worker nodes"
  vpc_id      = var.vpc_id

  ingress {
    description = "Node to node communication"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  ingress {
    description     = "Bastion SSH access to nodes"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.env}-eks-nodes-sg"
    Env  = var.env
  }
}