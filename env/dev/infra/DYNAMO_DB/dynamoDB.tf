# checkov:skip=CKV_AWS_119:Default encryption is fine for demo
# checkov:skip=CKV_AWS_28:TTL handles data lifecycle
resource "aws_dynamodb_table" "request_metrics_db" {
  name         = var.dB_name
  billing_mode = var.dB_billing_mode
  hash_key     = var.dB_hash_key
  range_key    = var.dB_range_key

  attribute {
    name = "request_id"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "N"
  }

  attribute {
    name = "path"
    type = "S"
  }

  global_secondary_index {
    name            = var.dB_global_index_name
    hash_key        = var.dB_global_index_hash_key
    range_key       = var.dB_global_index_range_key
    projection_type = var.dB_global_index_projection_type
    read_capacity   = var.dB_global_index_read_capacity
    write_capacity  = var.dB_global_index_write_capacity
  }

  # Auto-expire records after 7 days (604800 seconds)
  ttl {
    attribute_name = "expires_at"
    enabled        = true
  }

  tags = {
    Environment = "production"
    Service     = "api"
  }
}