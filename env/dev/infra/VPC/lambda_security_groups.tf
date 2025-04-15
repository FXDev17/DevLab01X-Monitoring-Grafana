# Creating Security Groups
# checkov:skip=CKV2_AWS_5:SG is attached to Lambda (Checkov visibility issue)
resource "aws_security_group" "lambda_SG_Out" {
  name_prefix = "lambda_SG_Out"
  description = "Egress rules for Lambda"
  vpc_id = aws_vpc.main.id

  dynamic "egress" {
    for_each = var.lambda_security_groups_egress
    content {
      from_port   = egress.value.from_port
      to_port     = egress.value.to_port
      protocol    = egress.value.protocol
      cidr_blocks = egress.value.cidr_blocks
      description = egress.value.description
    }
  }
}