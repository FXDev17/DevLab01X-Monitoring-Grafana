resource "aws_iam_role" "opentelemetry_instance_role" {
  name = "opentelemetry_instance_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "opentelemetry_instance_xray" {
  role       = aws_iam_role.opentelemetry_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
}

resource "aws_iam_instance_profile" "opentelemetry_instance_profile" {
  name = "opentelemetry_instance_profile"
  role = aws_iam_role.opentelemetry_instance_role.name
}

