resource "aws_iam_role" "grafana_cloudwatch" {
  name = "grafana-cloudwatch-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::008923505280:root" # Replace with Grafana Cloud’s AWS account ID
        }
        Condition = {
          StringEquals = {
            "sts:ExternalId" = "2372833"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "grafana_cloudwatch_policy" {
  name   = "grafana-cloudwatch-policy"
  role   = aws_iam_role.grafana_cloudwatch.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
            "tag:GetResources",
            "cloudwatch:GetMetricData",
            "cloudwatch:ListMetrics",
            "apigateway:GET",
            "aps:ListWorkspaces",
            "autoscaling:DescribeAutoScalingGroups",
            "dms:DescribeReplicationInstances",
            "dms:DescribeReplicationTasks",
            "ec2:DescribeTransitGatewayAttachments",
            "ec2:DescribeSpotFleetRequests",
            "shield:ListProtections",
            "storagegateway:ListGateways",
            "storagegateway:ListTagsForResource"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

