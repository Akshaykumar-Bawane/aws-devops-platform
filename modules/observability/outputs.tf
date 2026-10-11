output "sns_topic_arn" {
  description = "SNS topic ARN for alarm notifications"
  value       = aws_sns_topic.alerts.arn
}

output "app_log_group_name" {
  description = "CloudWatch log group name for application logs"
  value       = aws_cloudwatch_log_group.app.name
}

output "eks_log_group_name" {
  description = "CloudWatch log group name for EKS logs"
  value       = aws_cloudwatch_log_group.eks.name
}

output "cloudtrail_name" {
  description = "CloudTrail trail name"
  value       = var.enable_cloudtrail ? aws_cloudtrail.main[0].name : null
}