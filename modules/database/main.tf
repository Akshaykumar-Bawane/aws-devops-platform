# ─────────────────────────────────────────
# RDS SECURITY GROUP
# controls who can reach the database
# only allow traffic from within VPC
# never expose RDS to public internet
# ─────────────────────────────────────────
resource "aws_security_group" "rds" {
  name        = "${var.project_name}-${var.env}-rds-sg"
  description = "Security group for RDS - allows MySQL from VPC only"
  vpc_id      = var.vpc_id

  ingress {
    description = "MySQL from within VPC only"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project_name}-${var.env}-rds-sg"
    Env     = var.env
    Project = var.project_name
  }
}

# ─────────────────────────────────────────
# DB SUBNET GROUP
# tells RDS which subnets it can use
# must span minimum 2 AZs — AWS requirement
# always use private subnets
# ─────────────────────────────────────────
resource "aws_db_subnet_group" "main" {
  name        = "${var.project_name}-${var.env}-db-subnet-group"
  description = "RDS subnet group across private subnets"
  subnet_ids  = var.private_subnet_ids

  tags = {
    Name    = "${var.project_name}-${var.env}-db-subnet-group"
    Env     = var.env
    Project = var.project_name
  }
}

# ─────────────────────────────────────────
# DB PARAMETER GROUP
# database engine configuration settings
# using default group works but custom
# group gives you control over things like
# slow query logs, max connections, charset
# ─────────────────────────────────────────
resource "aws_db_parameter_group" "main" {
  name        = "${var.project_name}-${var.env}-db-params"
  family      = "mysql8.0"
  description = "Custom parameter group for MySQL 8.0"

  parameter {
    name  = "slow_query_log"
    value = "1"
  }

  parameter {
    name  = "long_query_time"
    value = "2"
  }

  tags = {
    Name = "${var.project_name}-${var.env}-db-params"
    Env  = var.env
  }
}

# ─────────────────────────────────────────
# RDS INSTANCE
# the actual database server
# ─────────────────────────────────────────
resource "aws_db_instance" "main" {
  identifier        = "${var.project_name}-${var.env}-rds"
  engine            = var.db_engine
  engine_version    = var.db_engine_version
  instance_class    = var.db_instance_class
  allocated_storage = var.db_allocated_storage

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  parameter_group_name   = aws_db_parameter_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  multi_az               = var.multi_az
  publicly_accessible    = false
  skip_final_snapshot    = var.skip_final_snapshot
  deletion_protection    = false
  storage_encrypted      = true

  backup_retention_period = 0
  backup_window           = "03:00-04:00"
  maintenance_window      = "Mon:04:00-Mon:05:00"

  tags = {
    Name    = "${var.project_name}-${var.env}-rds"
    Env     = var.env
    Project = var.project_name
  }
}

# ─────────────────────────────────────────
# DYNAMODB TABLE
# NoSQL table for app use
# PAY_PER_REQUEST = no idle cost
# ─────────────────────────────────────────
resource "aws_dynamodb_table" "main" {
  name         = "${var.project_name}-${var.env}-${var.dynamodb_table_name}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = {
    Name    = "${var.project_name}-${var.env}-${var.dynamodb_table_name}"
    Env     = var.env
    Project = var.project_name
  }
}