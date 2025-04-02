# Defining Policy For EC2 to Use to Assume Role
data "aws_iam_policy_document" "monitoring_pipeline_Assume_Role_Policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# Defining the IAM Role
resource "aws_iam_role" "monitoring_pipeline_Role" {
  name               = var.role_name
  assume_role_policy = data.aws_iam_policy_document.monitoring_pipeline_Assume_Role_Policy.json
}

# Defining the IAM Policy Document
data "aws_iam_policy_document" "monitoring_pipeline_Permissions_Policy" {
  # S3 Permissions (no condition)
  statement {
    actions = [
      "s3:ListBucket",
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]
    resources = [
      "arn:aws:s3:::devlab00-logging",
      "arn:aws:s3:::devlab00-logging/*"
    ]
  }

  # EC2 Operational Permissions (with condition)
  statement {
    actions = [
      "ec2:DescribeInstances",
      "ec2:StartInstances",
      "ec2:StopInstances",
      "ec2:ImportKeyPair",
      "ec2:CreateSecurityGroup"
    ]
    resources = [
      "arn:aws:ec2:eu-west-1:817520395860:key-pair/*",
      "arn:aws:ec2:eu-west-1:817520395860:security-group/*"
    ]
    condition {
      test     = "StringEquals"
      variable = "ec2:ResourceTag/ManagedBy"
      values   = ["jenkins"]
    }
  }

  # EC2 Read Permissions (no condition, broader scope)
  statement {
    actions = [
      "ec2:DescribeKeyPairs",
      "ec2:DescribeSecurityGroups"
    ]
    resources = ["*"]  # Describe actions often require broader access
  }

  # IAM Permissions (with condition where applicable)
  statement {
    actions = [
      "iam:CreateRole",
      "iam:CreatePolicy",
      "iam:GetRole",
      "iam:GetPolicy"
    ]
    resources = [
      "arn:aws:iam::817520395860:role/monitoring_pipeline_Role",       # Added exact role ARN
      "arn:aws:iam::817520395860:role/monitoring_pipeline_Role/*",     # Existing path pattern
      "arn:aws:iam::817520395860:policy/monitoring_pipeline_Policy",   # Added exact policy ARN
      "arn:aws:iam::817520395860:policy/monitoring_pipeline_Policy/*"  # Existing path pattern
    ]
  }
}

# Defining IAM Policy
resource "aws_iam_policy" "monitoring_pipeline_Policy" {
  name        = var.aws_iam_policy_name
  description = var.aws_iam_policy_description
  policy      = data.aws_iam_policy_document.monitoring_pipeline_Permissions_Policy.json
}

# Attaching Policy To Role
resource "aws_iam_role_policy_attachment" "monitoring_pipeline_Role_Attachment" {
  role       = aws_iam_role.monitoring_pipeline_Role.name
  policy_arn = aws_iam_policy.monitoring_pipeline_Policy.arn
}

# Create instance profile for EC2
resource "aws_iam_instance_profile" "monitoring_pipeline_profile" {
  name = "monitoring_pipeline_profile"
  role = aws_iam_role.monitoring_pipeline_Role.name
}