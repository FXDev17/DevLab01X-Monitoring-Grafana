# 1. Monitoring Pipeline Role (for EC2 instances)
resource "aws_iam_role" "pipeline_execution_Role" {
  name               = "pipeline_execution_Role"
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
resource "aws_iam_policy" "pipeline_execution_Policy" {
  name        = "pipeline_execution_Policy"
  description = "Permissions for monitoring pipeline EC2 instances"

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
        Resource = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/pipeline_execution_Role"]
      }
    ]
  })
}

# 3. Attach policy to monitoring role
resource "aws_iam_role_policy_attachment" "pipeline_execution_attachment" {
  role       = aws_iam_role.pipeline_execution_Role.name
  policy_arn = aws_iam_policy.pipeline_execution_Policy.arn
}

# 4. Instance profile for EC2
resource "aws_iam_instance_profile" "pipeline_execution_profile" {
  name = "pipeline_execution_profile"
  role = aws_iam_role.pipeline_execution_Role.name
}

# 5. Jenkins Pipeline Execution Role (for assuming roles)
resource "aws_iam_role" "jenkins_pipeline_role" {
  name               = "jenkins_terraform_deploy_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = {
        AWS = "arn:aws:iam::817520395860:role/monitoring_pipeline_Role"  # Jenkins instance role (if Jenkins is on EC2)
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
