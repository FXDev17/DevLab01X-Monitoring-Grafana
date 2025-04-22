output "base_url" {
  value = "https://${aws_api_gateway_rest_api.api.id}.execute-api.${var.agw_region}.amazonaws.com/${aws_api_gateway_stage.prod.stage_name}"
}

output "ping_url" {
  value = "https://${aws_api_gateway_rest_api.api.id}.execute-api.${var.agw_region}.amazonaws.com/${aws_api_gateway_stage.prod.stage_name}/ping"
}

output "fail_url" {
  value = "https://${aws_api_gateway_rest_api.api.id}.execute-api.${var.agw_region}.amazonaws.com/${aws_api_gateway_stage.prod.stage_name}/fail"
}
