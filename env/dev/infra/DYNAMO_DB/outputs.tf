output "request_metrics_db" {
  value = aws_dynamodb_table.request_metrics_db
}

output "request_metrics_db_arn" {
  value = aws_dynamodb_table.request_metrics_db.arn
}

output "table_name" {
  value = aws_dynamodb_table.request_metrics_db.name
}

output "table_arn" {
  value = aws_dynamodb_table.request_metrics_db.arn
}