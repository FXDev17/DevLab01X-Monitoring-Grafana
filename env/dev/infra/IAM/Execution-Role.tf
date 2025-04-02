# 1. Monitoring Pipeline Role (for EC2 instances)
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

# 2. Monitoring Pipeline Policy (EC2 runtime permissions)
resource "aws_iam_policy" "monitoring_pipeline_Policy" {
  name        = "monitoring_pipeline_Policy"
  description = "Permissions for monitoring pipeline EC2 instances"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # S3 permissions
      {
        Effect   = "Allow",
        Action   = ["s3:ListBucket", "s3:GetObject", "s3:PutObject", "s3:DeleteObject"],
        Resource = ["arn:aws:s3:::devlab00-logging", "arn:aws:s3:::devlab00-logging/*"]
      },
      # EC2 permissions
      {
        Effect   = "Allow",
        Action   = ["ec2:DescribeInstances", "ec2:StartInstances", "ec2:StopInstances"],
        Resource = "*"
      },
      # IAM self-inspection
      {
        Effect   = "Allow",
        Action   = ["iam:GetRole", "iam:GetPolicy", "iam:List*"],
        Resource = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/monitoring_pipeline_Role"]
      }
    ]
  })
}

# 3. Attach policy to monitoring role
resource "aws_iam_role_policy_attachment" "monitoring_pipeline_attachment" {
  role       = aws_iam_role.monitoring_pipeline_Role.name
  policy_arn = aws_iam_policy.monitoring_pipeline_Policy.arn
}

# 4. Instance profile for EC2
resource "aws_iam_instance_profile" "monitoring_pipeline_profile" {
  name = "monitoring_pipeline_profile"
  role = aws_iam_role.monitoring_pipeline_Role.name
}

# 5. Jenkins Pipeline Execution Role (NEW)
resource "aws_iam_role" "jenkins_pipeline_role" {
  name               = "jenkins_terraform_deploy_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = {
        AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" # Tighten this to your Jenkins instance role ARN later
      }
    }]
  })
}

# 6. Custom policy for Jenkins deployments (least privilege)
resource "aws_iam_policy" "jenkins_deploy_policy" {
  name        = "jenkins_terraform_deploy_policy"
  description = "Permissions for Jenkins to execute Terraform"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "iam:PassRole",
          "sts:AssumeRole",
          "ec2:*",
          "s3:*",
          "iam:Get*",
          "iam:List*"
        ],
        Resource = "*"
      },
      {
        Effect    = "Allow",
        Action    = "iam:CreatePolicy",
        Resource  = "*",
        Condition = {
          StringEquals = {
            "iam:PermissionsBoundary" = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/terraform-boundary"
          }
        }
      }
    ]
  })
}

# 7. Attach policy to Jenkins role
resource "aws_iam_role_policy_attachment" "jenkins_deploy_attach" {
  role       = aws_iam_role.jenkins_pipeline_role.name
  policy_arn = aws_iam_policy.jenkins_deploy_policy.arn
}

data "aws_caller_identity" "current" {}