module "s3" {
  source      = "./modules/s3"
  bucket_name = "dirty-binaries"
}

module "iam" {
  source     = "./modules/iam"
  bucket_arn = module.s3.bucket_arn
}

module "guardduty" {
  source = "./modules/guardduty"
}