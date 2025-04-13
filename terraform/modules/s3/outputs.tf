output "bucket_arn" {
  description = "The ARN of the artifact S3 bucket."
  value       = aws_s3_bucket.artifact_bucket.arn
}