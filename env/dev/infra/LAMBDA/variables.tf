variable "lambda_function_name" {
  description = "Lambda function name"
  type        = string
  default = "api_funct"
}

variable "lambda_SG_Out" {
  description = "Lambda security group"
  type        = string
}

variable "subnet_ids" {
  description = "Subnets for Lambda VPC config"
  type        = list(string)
}

variable "dynamodb_table_name" {
  description = "DynamoDB table"
  type        = string
}

variable "request_metrics_db_arn" {
  description = "DynamoDB ARN for request metrics"
  type        = string
}

variable "api_key" {
  description = "API key"
  type        = string
}

variable "loki_endpoint" {
  description = "Loki endpoint"
  type        = string
}

variable "xray_daemon_address" {
  description = "X-Ray daemon address"
  type        = string
}

variable "lambda_basic_execution" {
  description = "Retention days for CloudWatch logs"
  type        = string
}
