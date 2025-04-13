resource "aws_iam_role" "lambda_execution" {
  name = "GuardDutyLambdaExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = { Service = "lambda.amazonaws.com" },
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_policy" {
  role = aws_iam_role.lambda_execution.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_lambda_function" "guardduty_webhook_forwarder" {
  function_name = "GuardDutyWebhookForwarder"
  runtime       = "python3.12"
  handler       = "handler.lambda_handler"
  role          = aws_iam_role.lambda_execution.arn
  timeout       = 30

  filename         = "lambda.zip" # Zip your handler.py manually
  source_code_hash = filebase64sha256("lambda.zip")

  environment {
    variables = {
      WEBHOOK_URL = var.webhook_url
    }
  }
}