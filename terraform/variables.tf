variable "webhook_url" {
  type        = string
  description = "Webhook URL to receive GuardDuty findings"

  validation {
    condition     = can(regex("^https://", var.webhook_url))
    error_message = "The webhook URL must start with https://"
  }
}

variable "s3_bucket_name" {
  type        = string
  description = "S3 dirty bucket name"
}

variable "github_repo" {
  type        = string
  description = "GitHub org and repo name"
}