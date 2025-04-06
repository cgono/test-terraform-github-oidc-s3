locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# S3 bucket for malware scanning
resource "aws_s3_bucket" "malware_scan_bucket" {
  bucket = "${local.name_prefix}-malware-scan-bucket"

  tags = {
    Name        = "${local.name_prefix}-malware-scan-bucket"
    Environment = var.environment
  }
}

# Enable GuardDuty malware scanning on the bucket
resource "aws_guardduty_detector" "malware_detector" {
  enable = true
}

resource "aws_guardduty_detector_feature" "malware_scanning" {
  detector_id = aws_guardduty_detector.malware_detector.id
  name        = "EBS_MALWARE_PROTECTION"
  status      = "ENABLED"
}

# EventBridge rule for GuardDuty findings
resource "aws_cloudwatch_event_rule" "guardduty_findings" {
  name        = "${local.name_prefix}-guardduty-findings"
  description = "Capture GuardDuty malware scanning findings"
  event_pattern = jsonencode({
    source      = ["aws.guardduty"]
    detail-type = ["GuardDuty Finding"]
  })

  tags = {
    Name        = "${local.name_prefix}-guardduty-findings"
    Environment = var.environment
  }
}

# Lambda function to process findings
resource "aws_lambda_function" "process_findings" {
  filename         = "lambda_function.zip"
  function_name    = "${local.name_prefix}-process-findings"
  role            = aws_iam_role.lambda_role.arn
  handler         = "index.handler"
  runtime         = "nodejs18.x"
  timeout         = 30
  memory_size     = 128
  source_code_hash = filebase64sha256("lambda_function.zip")

  environment {
    variables = {
      WEBHOOK_URL = var.webhook_url
    }
  }

  tags = {
    Name        = "${local.name_prefix}-process-findings"
    Environment = var.environment
  }
}

# IAM role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "${local.name_prefix}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${local.name_prefix}-lambda-role"
    Environment = var.environment
  }
}

# IAM policy for Lambda
resource "aws_iam_role_policy" "lambda_policy" {
  name = "${local.name_prefix}-lambda-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# EventBridge target
resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.guardduty_findings.name
  target_id = "SendToLambda"
  arn       = aws_lambda_function.process_findings.arn
}

# Lambda permission for EventBridge
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.process_findings.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.guardduty_findings.arn
} 