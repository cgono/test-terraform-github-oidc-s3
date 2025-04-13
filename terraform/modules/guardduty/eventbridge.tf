resource "aws_cloudwatch_event_rule" "guardduty_finding" {
  name        = "GuardDutyFindingEventRule"
  description = "Capture GuardDuty Malware Findings and forward them to a webhook"

  event_pattern = jsonencode({
    source      = ["aws.guardduty"],
    detail-type = ["GuardDuty Finding"],
    detail = {
      type = ["Execution:Malware"]
    }
  })
}

resource "aws_cloudwatch_event_target" "send_to_lambda" {
  rule      = aws_cloudwatch_event_rule.guardduty_finding.name
  target_id = "LambdaTarget"
  arn       = aws_lambda_function.guardduty_webhook_forwarder.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.guardduty_webhook_forwarder.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.guardduty_finding.arn
}