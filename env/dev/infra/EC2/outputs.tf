output "opentelemetry_private_ip" {
  value = aws_instance.opentelemetry_instance.private_ip
}