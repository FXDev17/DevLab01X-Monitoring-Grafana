# 1. Define the IAM Role with EC2 trust relationship
resource "aws_iam_role" "monitoring_pipeline_Role" {
  name = "monitoring_pipeline_Role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

# 2. Define the IAM Policy with proper permissions
resource "aws_iam_policy" "monitoring_pipeline_Policy" {
  name        = "monitoring_pipeline_Policy"
  description = "Permissions for monitoring pipeline"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # S3 Permissions
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = [
          "arn:aws:s3:::devlab00-logging",
          "arn:aws:s3:::devlab00-logging/*"
        ]
      },
      
      # EC2 Permissions
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:StartInstances",
          "ec2:StopInstances",
          "ec2:ImportKeyPair",
          "ec2:CreateSecurityGroup",
          "ec2:DescribeKeyPairs",
          "ec2:DescribeSecurityGroups"
        ]
        Resource = "*"
      },
      
      # Critical IAM Permissions - Allow the role to manage itself
      {
        Effect = "Allow"
        Action = [
          "iam:GetRole",
          "iam:GetRolePolicy",
          "iam:ListAttachedRolePolicies"
        ]
        Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/monitoring_pipeline_Role"
      },
      
      # Other IAM permissions (restricted to specific resources)
      {
        Effect = "Allow"
        Action = [
          "iam:CreateRole",
          "iam:CreatePolicy",
          "iam:GetPolicy"
        ]
        Resource = [
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/monitoring_pipeline_Role/*",
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/monitoring_pipeline_Policy*"
        ]
      }
    ]
  })
}

# 3. Attach the policy to the role
resource "aws_iam_role_policy_attachment" "monitoring_pipeline" {
  role       = aws_iam_role.monitoring_pipeline_Role.name
  policy_arn = aws_iam_policy.monitoring_pipeline_Policy.arn
}

# 4. Create the instance profile
resource "aws_iam_instance_profile" "monitoring_pipeline_profile" {
  name = "monitoring_pipeline_profile"
  role = aws_iam_role.monitoring_pipeline_Role.name
}

# Get current AWS account ID
data "aws_caller_identity" "current" {}