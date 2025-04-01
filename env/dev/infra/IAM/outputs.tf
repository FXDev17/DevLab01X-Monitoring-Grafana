# Output the IAM role's name
output "monitoring_pipeline_role" {
  value       = aws_iam_role.monitoring_pipeline_Role.name
  description = "The name of the Jenkins Dev Pipeline IAM role"
#   depends_on = [ aws_iam_role.monitoring_Pipeline_Role ]
}

# Output the IAM role's arn
output "monitoring_pipeline_role_arn" {
  value = aws_iam_role.monitoring_pipeline_Role.arn
}

