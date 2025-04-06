# S3 bucket for Terraform state
resource "aws_s3_bucket" "terraform_state" {
  bucket = "guardduty-malware-scanning-terraform-state"

  # Prevent accidental deletion of this S3 bucket
  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name        = "guardduty-malware-scanning-terraform-state"
    Environment = "management"
  }
}

# Set the bucket region
resource "aws_s3_bucket_region" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  region = "ap-southeast-1"
}

# Enable versioning for state files
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Enable server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block all public access
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# DynamoDB table for state locking
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "guardduty-malware-scanning-terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "guardduty-malware-scanning-terraform-locks"
    Environment = "management"
  }
}

# Configure the backend
terraform {
  backend "s3" {
    bucket         = "guardduty-malware-scanning-terraform-state"
    key            = "terraform.tfstate"
    region         = "ap-southeast-1"  # This needs to be hardcoded as it's used during initialization
    encrypt        = true
    use_lockfile   = true
  }
} 