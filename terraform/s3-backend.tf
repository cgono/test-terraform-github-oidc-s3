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

resource "aws_iam_role" "terraform_ci_role" {
  name = "TerraformCICDRole"

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

resource "aws_iam_policy" "terraform_ci_policy" {
  name        = "TerraformCICDPolicy"
  description = "Least-privilege policy for Terraform CI/CD pipeline"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      # S3 state bucket and artifact bucket management
      {
        Effect = "Allow",
        Action = [
          "s3:CreateBucket",
          "s3:DeleteBucket",
          "s3:GetBucket*",
          "s3:ListBucket",
          "s3:PutBucket*",
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:GetBucketPolicy",
          "s3:PutBucketPolicy"
        ],
        Resource = [
          "arn:aws:s3:::test-gh-oidc-s3-terraform-state-bucket",
          "arn:aws:s3:::test-gh-oidc-s3-terraform-state-bucket/*",
          "arn:aws:s3:::dirty-binaries",
          "arn:aws:s3:::dirty-binaries/*"
        ]
      },
      # IAM for roles and policies managed by this project
      {
        Effect = "Allow",
        Action = [
          "iam:GetRole",
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:UpdateAssumeRolePolicy",
          "iam:PassRole",
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",
          "iam:PutRolePolicy",
          "iam:DeleteRolePolicy",
          "iam:GetPolicy",
          "iam:CreatePolicy",
          "iam:DeletePolicy",
          "iam:List*",
          "iam:GetOpenIDConnectProvider",
          "iam:CreateOpenIDConnectProvider",
          "iam:DeleteOpenIDConnectProvider",
          "iam:UpdateOpenIDConnectProviderThumbprint"
        ],
        Resource = "*"
      },
      # Lambda management
      {
        Effect = "Allow",
        Action = [
          "lambda:CreateFunction",
          "lambda:DeleteFunction",
          "lambda:GetFunction",
          "lambda:UpdateFunctionCode",
          "lambda:UpdateFunctionConfiguration",
          "lambda:AddPermission",
          "lambda:RemovePermission",
          "lambda:InvokeFunction",
          "lambda:GetPolicy"
        ],
        Resource = "*"
      },
      # CloudWatch Events (EventBridge)
      {
        Effect = "Allow",
        Action = [
          "events:PutRule",
          "events:DeleteRule",
          "events:DescribeRule",
          "events:PutTargets",
          "events:RemoveTargets",
          "events:ListRules",
          "events:ListTargetsByRule"
        ],
        Resource = "*"
      },
      # GuardDuty
      {
        Effect = "Allow",
        Action = [
          "guardduty:CreateDetector",
          "guardduty:DeleteDetector",
          "guardduty:GetDetector",
          "guardduty:UpdateDetector",
          "guardduty:ListDetectors",
          "guardduty:CreateFilter",
          "guardduty:DeleteFilter",
          "guardduty:GetFilter",
          "guardduty:UpdateFilter",
          "guardduty:ListFilters",
          "guardduty:ListFindings",
          "guardduty:GetFindings",
          "guardduty:CreatePublishingDestination",
          "guardduty:DeletePublishingDestination",
          "guardduty:ListPublishingDestinations"
        ],
        Resource = "*"
      },
      # CloudWatch Logs for Lambda
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_terraform_ci_policy" {
  role       = aws_iam_role.terraform_ci_role.name
  policy_arn = aws_iam_policy.terraform_ci_policy.arn
}
