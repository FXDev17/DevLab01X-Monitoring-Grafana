variable "ec2_role_name" {
  description = "Name of the IAM role for the EC2 instance"
  default     = "monitoring_pipeline_Role"
}

variable "ec2_policy_name" {
  description = "Name of the IAM policy for the EC2 instance"
  default     = "monitoring_pipeline_Policy"
}

variable "pipeline_role_name" {
  description = "Name of the IAM role for the Terraform pipeline"
  default     = "terraform_deploy_role"  # ← New role for pipeline
}