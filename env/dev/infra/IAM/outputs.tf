output "monitoring_pipeline_role" {
  description = "IAM role name for monitoring pipeline"
  value       = aws_iam_role.monitoring_pipeline_Role.name
}

output "monitoring_pipeline_role_arn" {
  description = "IAM role ARN for monitoring pipeline"
  value       = aws_iam_role.monitoring_pipeline_Role.arn
}

output "monitoring_policy_arn" {
  description = "IAM policy ARN for monitoring pipeline"
  value       = aws_iam_policy.monitoring_pipeline_Policy.arn
}