output "lambda_cloudwatch_log_group_name" {
  value = aws_cloudwatch_log_group.lambda_logs
}

output "lambda_invoke_arn" {
  description = "The ARN to invoke the Lambda function"
  value       = aws_lambda_function.api_funct.invoke_arn
}

output "lambda_function_name" {
  description = "The name of the Lambda function"
  value       = aws_lambda_function.api_funct.function_name
}

output "lambda_function_arn" {
  description = "The ARN of the Lambda function"
  value       = aws_lambda_function.api_funct.arn
}
