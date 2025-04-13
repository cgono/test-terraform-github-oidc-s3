terraform {
  backend "s3" {
    bucket       = "test-gh-oidc-s3-terraform-state-bucket"
    key          = "terraform/state/terraform.tfstate"
    region       = "ap-southeast-1"
    encrypt      = true
    use_lockfile = true
  }
}