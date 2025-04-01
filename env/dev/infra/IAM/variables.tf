variable "role_name" {
  description = "monitoring_pipeline Role Name"
  type        = string
  default     = "monitoring_pipeline_Role"
}

variable "aws_iam_policy_name" {
  description = "monitoring_pipeline Role Policy"
  type        = string
  default     = "monitoring_pipeline_Policy"
}

variable "aws_iam_policy_description" {
  description = "monitoring_pipeline Role Policy Description"
  type        = string
  default     = "monitoring_pipeline_Role_Policy"
}