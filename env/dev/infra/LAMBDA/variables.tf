# Setting Up Lambda Function 

variable "lambda_function_name" {
  description = "Lambda Function Name"
  type        = string
  default     = "api_funct"
}

variable "lambda_handler" {
  description = "Lambda Handler"
  type        = string
  default     = "lambda_function.lambda_handler"
}

variable "lambda_runtime" {
  description = "Lambda Runtime"
  type        = string
  default     = "python3.9"
}

variable "lambda_timeout" {
  description = "Lambda Timeouts"
  type        = number
  default     = 10
}

variable "lambda_memory_size" {
  description = "Lambda Memory Size"
  type        = number
  default     = 256
}


variable "lambda_retention_in_days" {
  description = "Log Retention Days Value"
  type        = number
  default     = 5
}


variable "lambda_exec_role" {
  description = "Role Name"
  type = string
  default = "lambda_exec_role"
}

variable "vpc_id" {
  description = "Input from Main.tf"
  type        = string
}

variable "subnet_ids" {
  description = "Input from Main.tf"
  type        = list(string)
}

variable "dynamodb_table_name" {
  description = "Input from Main.tf"
  type        = string
}

variable "lambda_SG_Out" {
    description = "Input from Main.tf"
    type        = string
}

variable "request_metrics_db_arn" {
    description = "Input from Main.tf"
    type        = string
}