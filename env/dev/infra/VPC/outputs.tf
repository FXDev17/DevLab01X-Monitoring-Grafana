# Output VPC information
output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_id" {
  value = aws_subnet.public_subnet.id
}

output "private_subnet_id" {
  value = aws_subnet.private_subnet.id
}

output "internet_gateway_id" {
  value = aws_internet_gateway.igw.id
}

output "nat_gateway_id" {
  value = aws_nat_gateway.nat_gateway.id
}

output "lambda_SG_Out" {
  value = aws_security_group.lambda_SG_Out.id
}

output "subnet_ids" {
  value = [aws_subnet.private_subnet.id, aws_subnet.public_subnet.id]
}
