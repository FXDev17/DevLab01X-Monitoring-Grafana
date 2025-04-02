# IAM Role for EC2
resource "aws_iam_role" "monitoring_pipeline_Role" {
  name               = "monitoring_pipeline_Role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

# IAM Policy
resource "aws_iam_policy" "monitoring_pipeline_Policy" {
  name        = "monitoring_pipeline_Policy"
  description = "Permissions for monitoring pipeline"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["s3:ListBucket", "s3:GetObject", "s3:PutObject", "s3:DeleteObject"],
        Resource = ["arn:aws:s3:::devlab00-logging", "arn:aws:s3:::devlab00-logging/*"]
      },
      {
        Effect   = "Allow",
        Action   = ["ec2:DescribeInstances", "ec2:StartInstances", "ec2:StopInstances"],
        Resource = "*"
      },
      {
        Effect   = "Allow",
        Action   = ["iam:GetRole", "iam:GetPolicy", "iam:List*"],
        Resource = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/monitoring_pipeline_Role"]
      }
    ]
  })
}

# Policy Attachment
resource "aws_iam_role_policy_attachment" "monitoring_pipeline_attachment" {
  role       = aws_iam_role.monitoring_pipeline_Role.name
  policy_arn = aws_iam_policy.monitoring_pipeline_Policy.arn
}

# Instance Profile
resource "aws_iam_instance_profile" "monitoring_pipeline_profile" {
  name = "monitoring_pipeline_profile"
  role = aws_iam_role.monitoring_pipeline_Role.name
}

data "aws_caller_identity" "current_execution" {}
