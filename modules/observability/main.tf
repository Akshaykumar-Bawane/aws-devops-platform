# ─────────────────────────────────────────
# SNS TOPIC
# notification hub — CloudWatch alarms
# send alerts here, SNS delivers to email
# ─────────────────────────────────────────
resource "aws_sns_topic" "alerts" {
  name = "${var.project_name}-${var.env}-alerts"

  tags = {
    Name    = "${var.project_name}-${var.env}-alerts"
    Env     = var.env
    Project = var.project_name
  }
}

# Subscribe your email to the SNS topic
# you must confirm the subscription email
# AWS sends before alarms start delivering
resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alarm_email
}

# ─────────────────────────────────────────
# CLOUDWATCH LOG GROUPS
# one log group per service
# retention set low to save cost
# ─────────────────────────────────────────
resource "aws_cloudwatch_log_group" "app" {
  name              = "/aws/${var.project_name}/${var.env}/app"
  retention_in_days = var.log_retention_days

  tags = {
    Name    = "${var.project_name}-${var.env}-app-logs"
    Env     = var.env
    Project = var.project_name
  }
}

resource "aws_cloudwatch_log_group" "eks" {
  name              = "/aws/eks/${var.project_name}-${var.env}/cluster"
  retention_in_days = var.log_retention_days

  tags = {
    Name = "${var.project_name}-${var.env}-eks-logs"
    Env  = var.env
  }
}

resource "aws_cloudwatch_log_group" "rds" {
  name              = "/aws/rds/${var.project_name}-${var.env}"
  retention_in_days = var.log_retention_days

  tags = {
    Name = "${var.project_name}-${var.env}-rds-logs"
    Env  = var.env
  }
}

# ─────────────────────────────────────────
# CLOUDWATCH ALARMS
# monitors key metrics and fires SNS alert
# when threshold is breached
# ─────────────────────────────────────────

# EC2 CPU alarm — fires if bastion CPU
# stays above 80% for 2 consecutive minutes
resource "aws_cloudwatch_metric_alarm" "ec2_cpu" {
  alarm_name          = "${var.project_name}-${var.env}-ec2-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "EC2 CPU utilization exceeded 80%"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  tags = {
    Name = "${var.project_name}-${var.env}-ec2-cpu-alarm"
    Env  = var.env
  }
}

# RDS CPU alarm — database CPU above 70%
# usually means missing indexes or
# unoptimized queries
resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  alarm_name          = "${var.project_name}-${var.env}-rds-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 60
  statistic           = "Average"
  threshold           = 70
  alarm_description   = "RDS CPU utilization exceeded 70%"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  dimensions = {
    DBInstanceIdentifier = var.rds_instance_id
  }

  tags = {
    Name = "${var.project_name}-${var.env}-rds-cpu-alarm"
    Env  = var.env
  }
}

# RDS storage alarm — fires when free
# storage drops below 5GB
# gives you time to increase storage
# before the database runs out of space
resource "aws_cloudwatch_metric_alarm" "rds_storage" {
  alarm_name          = "${var.project_name}-${var.env}-rds-storage-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 5000000000
  alarm_description   = "RDS free storage below 5GB"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    DBInstanceIdentifier = var.rds_instance_id
  }

  tags = {
    Name = "${var.project_name}-${var.env}-rds-storage-alarm"
    Env  = var.env
  }
}

# ─────────────────────────────────────────
# CLOUDTRAIL
# logs every single AWS API call
# who did what, from where, and when
# essential for security auditing
# ─────────────────────────────────────────
resource "aws_cloudtrail" "main" {
  count                         = var.enable_cloudtrail ? 1 : 0
  name                          = "${var.project_name}-${var.env}-trail"
  s3_bucket_name                = var.cloudtrail_bucket_name
  include_global_service_events = true
  is_multi_region_trail         = false
  enable_log_file_validation    = true

  event_selector {
    read_write_type           = "All"
    include_management_events = true

    data_resource {
      type   = "AWS::S3::Object"
      values = ["arn:aws:s3:::"]
    }
  }

  tags = {
    Name    = "${var.project_name}-${var.env}-trail"
    Env     = var.env
    Project = var.project_name
  }
}

# S3 bucket policy for CloudTrail
# CloudTrail needs explicit permission to
# write logs into the S3 bucket
resource "aws_s3_bucket_policy" "cloudtrail" {
  count  = var.enable_cloudtrail ? 1 : 0
  bucket = var.cloudtrail_bucket_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = "arn:aws:s3:::${var.cloudtrail_bucket_name}"
      },
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "arn:aws:s3:::${var.cloudtrail_bucket_name}/AWSLogs/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}