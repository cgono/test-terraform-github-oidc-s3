variable "bucket_arn" {
  type        = string
  description = "S3 dirty bucket ARN for enabling GuardDuty on"
}

variable "oidc_provider_arn" {
  description = "The ARN of the GitHub OIDC provider"
  type        = string
}

variable "github_repo" {
  type        = string
  description = "GitHub org and repo to authorize e.g. cgono/test-terraform-github-oidc-s3"
}

variable "github_oidc_role_name" {
  description = "Name of the GitHub OIDC IAM role"
  type        = string
}
