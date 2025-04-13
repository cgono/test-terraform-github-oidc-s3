data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "artifact_bucket" {
  bucket = var.s3_bucket_name
}

resource "aws_s3_bucket_public_access_block" "block" {
  bucket                  = aws_s3_bucket.artifact_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "guardduty_policy" {
  bucket = aws_s3_bucket.artifact_bucket.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = { Service = "guardduty.amazonaws.com" },
        Action    = "s3:GetObject",
        Resource  = "${aws_s3_bucket.artifact_bucket.arn}/*",
        Condition = {
          StringEquals = { "aws:SourceAccount" : data.aws_caller_identity.current.account_id }
        }
      }
    ]
  })
}