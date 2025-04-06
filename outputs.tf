output "s3_bucket_name" {
  description = "Name of the S3 bucket created for malware scanning"
  value       = aws_s3_bucket.malware_scan_bucket.id
}

output "lambda_function_name" {
  description = "Name of the Lambda function that processes findings"
  value       = aws_lambda_function.process_findings.function_name
}

output "eventbridge_rule_name" {
  description = "Name of the EventBridge rule for GuardDuty findings"
  value       = aws_cloudwatch_event_rule.guardduty_findings.name
} 