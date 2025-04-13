resource "aws_iam_role" "github_oidc_role" {
  name = "GitHubOIDCRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = { Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com" },
        Action    = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringEquals = { "token.actions.githubusercontent.com:aud" : "sts.amazonaws.com" },
          StringLike   = { "token.actions.githubusercontent.com:sub" : "repo:ORG_NAME/REPO_NAME:*" }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "s3_upload_policy" {
  name = "GitHubS3UploadPolicy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["s3:PutObject", "s3:GetObject", "s3:ListBucket"],
        Resource = ["${var.bucket_arn}", "${var.bucket_arn}/*"]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_s3_policy" {
  policy_arn = aws_iam_policy.s3_upload_policy.arn
  role       = aws_iam_role.github_oidc_role.name
}