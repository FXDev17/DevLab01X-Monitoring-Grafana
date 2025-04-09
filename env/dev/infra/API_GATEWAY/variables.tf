variable "agw_name" {
  description = "API Gateway Name"
  type        = string
  default     = "observability-api"
}

variable "agw_function_name" {
  description = "Lambda Function Name"
  type = string
  default = "api_funct"
}

variable "agw_description" {
  description = "API Gateway Description"
  type        = string
  default     = "API for Observability Demo"
}

variable "agw_resource_proxy_path_part" {
  description = "Resource Proxy Path"
  type        = string
  default     = "{proxy+}"
}

variable "agw_proxy_http_method" {
  description = "Proxy HTTP Method"
  type        = string
  default     = "ANY"
}

variable "agw_proxy_auth" {
  description = "Proxy HTTP Auth"
  type        = string
  default     = "NONE"
}

variable "agw_integration_http_method" {
  description = "HTTP integration method"
  type        = string
  default     = "POST"
}

variable "agw_type" {
  description = "value"
  type        = string
  default     = "AWS_PROXY"
}

variable "agw_statement_id" {
  description = "value"
  type        = string
  default     = "AllowAPIGatewayInvoke"
}

variable "agw_action" {
  description = "value"
  type        = string
  default     = "lambda:InvokeFunction"
}

variable "agw_principal" {
  description = "value"
  type        = string
  default     = "apigateway.amazonaws.com"
}


variable "agw_stage_name" {
  description = "value"
  type        = string
  default     = "prod"
}


variable "lambda_arn" {
  description = "ARN of the Lambda function to integrate with API Gateway"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC for VPC-linked API Gateway (optional if not VPC-linked)"
  type        = string
  default     = null  # Optional: allows vpc_id to be unset if not needed
}

variable "lambda_name" {
  type = string
}

variable "lambda_invoke_arn" {
  type = string
}