resource "null_resource" "package_lambda" {
  triggers = {
    code_hash = filebase64sha256("${path.module}/lambda_function_payload/lambda_function.py")
    deps_hash = filebase64sha256("${path.module}/lambda_function_payload/requirements.txt")
  }

  provisioner "local-exec" {
    command = "/bin/bash -c 'cd ${path.module}/lambda_function_payload && ./package_lambda.sh'"
  }
}

resource "aws_lambda_function" "api_funct" {
  filename         = "${path.module}/lambda_function_payload.zip"
  function_name    = var.lambda_function_name
  role             = aws_iam_role.lambda_exec.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.9"
  timeout          = 10
  memory_size      = 256
  source_code_hash = filebase64sha256("${path.module}/lambda_function_payload.zip")
  # reserved_concurrent_executions = 40

  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = [var.lambda_SG_Out]
  }

  tracing_config {
    mode = "Active"
  }

  environment {
    variables = {
      DYNAMODB_TABLE          = var.dynamodb_table_name
      POWERTOOLS_SERVICE_NAME = "api_funct"
      LOKI_ENDPOINT           = var.loki_endpoint
      LOKI_API_KEY            = var.api_key
      AWS_XRAY_DAEMON_ADDRESS = var.xray_daemon_address
    }
  }

  depends_on = [
    null_resource.package_lambda,
    aws_iam_role_policy_attachment.lambda_logs,
    aws_iam_role_policy_attachment.lambda_vpc,
    aws_iam_role_policy_attachment.lambda_xray,
  ]
}