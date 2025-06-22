resource "aws_s3_bucket" "terraform_state" {
  bucket = "test-gh-oidc-s3-terraform-state-bucket"
}

resource "aws_s3_bucket_versioning" "terraform_state_versioning" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state_encryption" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state_block" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_iam_role" "github_oidc_role" {
  name = "GitHubOIDCRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = { Federated = var.oidc_provider_arn },
        Action    = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringEquals = { "token.actions.githubusercontent.com:aud" : "sts.amazonaws.com" },
          StringLike   = { "token.actions.githubusercontent.com:sub" : "repo:${var.github_repo}:*" }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "terraform_backend_access" {
  name        = "GitHubTerraformBackendAccessPolicy"
  description = "Allow GitHub Actions to access the Terraform backend state bucket"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket",
          "s3:DeleteObject"
        ],
        Resource = [
          "arn:aws:s3:::test-gh-oidc-s3-terraform-state-bucket",
          "arn:aws:s3:::test-gh-oidc-s3-terraform-state-bucket/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_backend_policy" {
  role       = aws_iam_role.github_oidc_role.name
  policy_arn = aws_iam_policy.terraform_backend_access.arn
}
