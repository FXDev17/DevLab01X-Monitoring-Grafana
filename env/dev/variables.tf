variable "api_key" {
  description = "Grafana Cloud API Key"
  type        = string
  sensitive   = true
}

variable "loki_endpoint" {
  description = "Grafana Loki endpoint"
  type        = string
}

