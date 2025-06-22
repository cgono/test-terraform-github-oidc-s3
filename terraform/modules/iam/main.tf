data "aws_caller_identity" "current" {}

resource "aws_iam_policy" "s3_upload_policy" {
  name = "GitHubS3UploadPolicy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket"
        ],
        Resource = ["${var.bucket_arn}", "${var.bucket_arn}/*"]
      },
      {
        Effect = "Allow",
        Action = [
          "guardduty:ListDetectors",
          "guardduty:ListFindings"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_s3_policy" {
  policy_arn = aws_iam_policy.s3_upload_policy.arn
  role       = var.github_oidc_role_name
}
