# Lambda Log Group
# checkov:skip=CKV_AWS_158:Default AWS encryption is sufficient for demo logs
# checkov:skip=CKV_AWS_338:Short retention (7 days) for cost savings
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${var.lambda_function_name}" 
  retention_in_days = 3
}


# Lambda Execution Role 
resource "aws_iam_role" "lambda_exec" {
  name = "lambda_exec_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}



# Attaching basic execution policy (for CloudWatch logs)
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_exec.id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Attach VPC execution policy (since Lambda is in private subnet)
resource "aws_iam_role_policy_attachment" "lambda_vpc" {
  role       = aws_iam_role.lambda_exec.id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# Attach X-Ray policy for tracing
resource "aws_iam_role_policy_attachment" "lambda_xray" {
  role       = aws_iam_role.lambda_exec.id
  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
}

# Attach custom DynamoDB policy
resource "aws_iam_role_policy" "lambda_dynamodb" {
  name = "lambda-dynamodb-access"
  role = aws_iam_role.lambda_exec.id # This attaches it to the role
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:UpdateItem",
          "dynamodb:Query",
          "dynamodb:DeleteItem"
        ]
        Effect = "Allow"
        Resource = [
           var.request_metrics_db_arn, 
          "${var.request_metrics_db_arn}/index/*" # For GSI access
        ]
      }
    ]
  })
}


# Additional permissions for Lambda Powertools
resource "aws_iam_role_policy" "lambda_powertools" {
  # checkov:skip=CKV_AWS_355:Wildcard permissions are acceptable for side project Lambda
  # checkov:skip=CKV_AWS_290:Basic Lambda logging/metrics permissions are safe
  name   = "lambda-powertools"
  role   = aws_iam_role.lambda_exec.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:CreateLogGroup"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "cloudwatch:namespace" = "ObservabilityAPI"
          }
        }
      }
    ]
  })
}