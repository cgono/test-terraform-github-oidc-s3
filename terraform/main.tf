module "s3" {
  source         = "./modules/s3"
  s3_bucket_name = var.s3_bucket_name
}

module "iam" {
  source                = "./modules/iam"
  bucket_arn            = module.s3.bucket_arn
  oidc_provider_arn     = module.oidc.oidc_provider_arn
  github_repo           = var.github_repo
  github_oidc_role_name = aws_iam_role.github_oidc_role.name
}

module "oidc" {
  source = "./modules/oidc"
}

module "guardduty" {
  source      = "./modules/guardduty"
  webhook_url = var.webhook_url
}