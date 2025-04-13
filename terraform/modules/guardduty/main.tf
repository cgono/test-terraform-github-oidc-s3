resource "aws_guardduty_detector" "guardduty" {
  enable = true
}

resource "aws_guardduty_detector_feature" "malware_protection" {
  detector_id = aws_guardduty_detector.guardduty.id
  name        = "EKS_AUDIT_LOGS"
  status      = "ENABLED"
}