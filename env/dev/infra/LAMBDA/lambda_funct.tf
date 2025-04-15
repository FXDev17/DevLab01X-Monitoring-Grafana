# With local-exec provisioner the ZIP file will be automatically created during deployment
resource "null_resource" "package_lambda" {
  provisioner "local-exec" {
    command = "${path.module}/lambda_function_payload/package_lambda.sh"
  }

  triggers = {
    always_run = "${timestamp()}"
  }
}

# Setting Up Lambda Function 
# checkov:skip=CKV_AWS_272:Code signing not needed for side project
# checkov:skip=CKV_AWS_116:CloudWatch Logs sufficient for error tracking
# checkov:skip=CKV_AWS_173:Default AWS encryption is sufficient
resource "aws_lambda_function" "api_funct" {
  
  filename         = "${path.module}/lambda_function_payload.zip"
  function_name    = var.lambda_function_name
  role             = aws_iam_role.lambda_exec.arn
  handler          = var.lambda_handler
  runtime          = var.lambda_runtime
  timeout          = var.lambda_timeout
  memory_size      = var.lambda_memory_size
  source_code_hash = filebase64sha256("${path.module}/lambda_function_payload.zip")
  reserved_concurrent_executions = 45

  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = [var.lambda_SG_Out]
  }

  tracing_config {
    mode = "Active" # For X-Ray tracing
  }

  environment {
    variables = {
      DYNAMODB_TABLE = var.dynamodb_table_name
    POWERTOOLS_SERVICE_NAME = "api_funct" }
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_logs,
    aws_cloudwatch_log_group.lambda_logs,
    null_resource.package_lambda
  ]
}
