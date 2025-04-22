resource "aws_api_gateway_rest_api" "api" {
  name        = "observability-api"
  description = "API with /ping and /fail endpoints"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_resource" "ping" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "ping"
}

resource "aws_api_gateway_resource" "fail" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "fail"
}

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

resource "aws_lambda_permission" "apigw_ping" {
  statement_id  = "AllowAPIGatewayInvokePing"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/*/ping"
}

resource "aws_lambda_permission" "apigw_fail" {
  statement_id  = "AllowAPIGatewayInvokeFail"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/*/fail"
}

resource "aws_api_gateway_integration" "lambda_ping" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.ping.id
  http_method             = aws_api_gateway_method.ping.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.lambda_invoke_arn

  depends_on = [aws_lambda_permission.apigw_ping]
}

resource "aws_api_gateway_integration" "lambda_fail" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.fail.id
  http_method             = aws_api_gateway_method.fail.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.lambda_invoke_arn

  depends_on = [aws_lambda_permission.apigw_fail]
}

resource "aws_api_gateway_deployment" "api" {
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

  depends_on = [
    aws_api_gateway_integration.lambda_ping,
    aws_api_gateway_integration.lambda_fail
  ]
}

resource "aws_api_gateway_stage" "prod" {
  stage_name           = "prod"
  rest_api_id          = aws_api_gateway_rest_api.api.id
  deployment_id        = aws_api_gateway_deployment.api.id
  xray_tracing_enabled = true
}

