# test-terraform-github-oidc-s3

This repository provisions an AWS S3 bucket and enables AWS GuardDuty Malware Protection using Terraform. It also sets up the necessary IAM roles and permissions to allow GitHub Actions to upload files to the S3 bucket and trigger malware scans.

## What this repository sets up

- **S3 Bucket**: Creates a secure S3 bucket for storing files, with public access blocked and server-side encryption enabled.
- **GuardDuty Malware Protection**: Activates GuardDuty with malware scanning for files uploaded to the S3 bucket.
- **EventBridge & Lambda**: Sets up an EventBridge rule to capture GuardDuty malware findings and forwards them to a webhook via a Lambda function.
- **GitHub OIDC Integration**: Configures IAM roles and policies to allow GitHub Actions workflows to authenticate via OIDC and upload artifacts to the S3 bucket.
- **Terraform Backend**: Uses an S3 bucket as the Terraform state backend for safe and remote state management.

## How to test

1. **Provision Infrastructure**:  
   Run Terraform to create the S3 bucket, GuardDuty detector, Lambda, and IAM roles.
2. **Upload a File**:  
   Use the provided GitHub Actions workflow or AWS CLI to upload a file to the S3 bucket.
3. **Trigger Malware Scan**:  
   GuardDuty will automatically scan new files uploaded to the bucket. If malware is detected, a finding is generated.
4. **Webhook Notification**:  
   The Lambda function forwards GuardDuty findings to your configured webhook URL.

## Quickstart

### AWS

Provisioned with AWS tag `testtfghs3`

### Terraform init

```bash
# Log in to AWS via SSO
aws sso login

aws --profile PowerUserAccess-345594603974 s3api create-bucket --bucket test-gh-oidc-s3-terraform-state-bucket --region ap-southeast-1 --create-bucket-configuration LocationConstraint=ap-southeast-1
AWS_PROFILE=PowerUserAccess-345594603974 terraform init
```

Outputs:

```
{
    "Location": "http://test-gh-oidc-s3-terraform-state-bucket.s3.amazonaws.com/"
}
```

## How to run Terraform

1. **Initialize Terraform**  
   This sets up the backend and downloads required providers:

   ```bash
   terraform init
   ```

2. **Review the planned changes**  
   See what Terraform will do before making changes:

   ```bash
   terraform plan
   ```

3. **Apply the configuration**  
   Provision the resources in your AWS account:

   ```bash
   terraform apply
   ```

   Confirm the action when prompted, or use `-auto-approve` to skip confirmation.

4. **(Optional) Destroy resources**  
   To clean up all resources created by Terraform:
   ```bash
   terraform destroy
   ```

> **Note:** Make sure your AWS credentials are configured (e.g., using `AWS_PROFILE` or environment variables).
