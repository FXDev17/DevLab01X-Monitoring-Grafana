# infra/API_GATEWAY/main.tf
resource "aws_api_gateway_rest_api" "api" {
  name        = "observability-api"
  description = "API with /ping and /fail endpoints"
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

# Root resource
resource "aws_api_gateway_resource" "root" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "{proxy+}"
}

# /ping resource
resource "aws_api_gateway_resource" "ping" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "ping"
}

# /fail resource
resource "aws_api_gateway_resource" "fail" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "fail"
}

# Methods for each endpoint
resource "aws_api_gateway_method" "ping" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.ping.id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "fail" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.fail.id
  http_method   = "ANY"
  authorization = "NONE"
}

# Integrations to Lambda
resource "aws_api_gateway_integration" "lambda_ping" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.ping.id
  http_method             = aws_api_gateway_method.ping.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.lambda_invoke_arn
}

resource "aws_api_gateway_integration" "lambda_fail" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.fail.id
  http_method             = aws_api_gateway_method.fail.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.lambda_invoke_arn
}

# Deployment
resource "aws_api_gateway_deployment" "api" {
  depends_on = [
    aws_api_gateway_integration.lambda_ping,
    aws_api_gateway_integration.lambda_fail
  ]

  rest_api_id = aws_api_gateway_rest_api.api.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.ping.id,
      aws_api_gateway_resource.fail.id,
      aws_api_gateway_method.ping.id,
      aws_api_gateway_method.fail.id,
      aws_api_gateway_integration.lambda_ping.id,
      aws_api_gateway_integration.lambda_fail.id
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Permissions
resource "aws_lambda_permission" "apigw_ping" {
  statement_id  = "AllowAPIGatewayInvokePing"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/GET/ping"
}

resource "aws_lambda_permission" "apigw_fail" {
  statement_id  = "AllowAPIGatewayInvokeFail"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/GET/fail"
}

# Stage with X-Ray
resource "aws_api_gateway_stage" "prod" {
  stage_name    = "prod"
  rest_api_id   = aws_api_gateway_rest_api.api.id
  deployment_id = aws_api_gateway_deployment.api.id
  xray_tracing_enabled = true
}

# Outputs
output "base_url" {
  value = aws_api_gateway_deployment.api.invoke_url
}

output "ping_url" {
  value = "${aws_api_gateway_deployment.api.invoke_url}/ping"
}

output "fail_url" {
  value = "${aws_api_gateway_deployment.api.invoke_url}/fail"
}