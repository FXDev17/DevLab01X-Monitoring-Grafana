# Output the IAM role's name
output "monitoring_pipeline_role" {
  value       = module.iam.monitoring_pipeline_role
  description = "The name of the Jenkins Dev Pipeline IAM role"
#   depends_on = [ aws_iam_role.monitoring_Pipeline_Role ]
}

# Output the IAM role's arn
output "monitoring_pipeline_role_arn" {
  value = module.iam.monitoring_pipeline_role_arn
}

