# AWS GuardDuty Malware Scanning Setup

This Terraform configuration sets up AWS GuardDuty Malware Scanning with the following components:
- An S3 bucket with GuardDuty Malware Scanning enabled
- An EventBridge rule to capture GuardDuty findings
- A Lambda function to process findings and send them to a webhook
- S3 backend for Terraform state management with DynamoDB state locking

## Prerequisites

1. AWS CLI configured with appropriate credentials
2. Terraform installed
3. A webhook URL where you want to receive the malware scan results
4. GitHub repository with Actions enabled

## Setup Instructions

### Bootstrap Backend Resources

Before setting up the main infrastructure, we need to create the S3 bucket and DynamoDB table that will be used for Terraform state management:

1. Navigate to the bootstrap directory:
   ```bash
   cd bootstrap
   ```

2. Initialize and apply the bootstrap configuration:
   ```bash
   terraform init
   terraform apply
   ```

This will create:
- An S3 bucket for storing Terraform state
- A DynamoDB table for state locking
- All necessary security configurations

### Main Infrastructure Setup

1. Return to the main directory:
   ```bash
   cd ..
   ```

2. Create a ZIP file containing the Lambda function:
   ```bash
   zip lambda_function.zip lambda_function.js
   ```

3. For local development, create a `backend.hcl` file:
   ```hcl
   profile = "PowerUserAccess-345594603974"
   ```

4. Initialize Terraform with the backend configuration:
   ```bash
   terraform init -backend-config=backend.hcl
   ```

5. Create a `terraform.tfvars` file with your configuration:
   ```hcl
   webhook_url = "https://your-webhook-url.com"
   environment = "dev"  # or "prod"
   project_name = "guardduty-malware-scanning"
   github_org = "your-github-org"
   github_repo = "your-repo-name"
   aws_region = "ap-southeast-1"  # or your preferred region
   ```

6. Apply the initial configuration to set up the GitHub OIDC provider and IAM role:
   ```bash
   AWS_PROFILE=PowerUserAccess-345594603974 terraform apply -target=aws_iam_openid_connect_provider.github_actions -target=aws_iam_role.github_actions
   ```

### State Management Setup

The configuration includes a secure backend setup for Terraform state management:
- S3 bucket for storing state files with versioning and encryption
- DynamoDB table for state locking to prevent concurrent modifications
- All backend resources are created with security best practices

The backend resources are created during the bootstrap process. The main Terraform configuration will:
1. Use the S3 bucket for state storage
2. Use the DynamoDB table for state locking
3. Continue with the rest of the infrastructure deployment

Note: For local development:
- Use `-backend-config=backend.hcl` with `terraform init` to configure the backend
- Set the `AWS_PROFILE` environment variable for other Terraform commands
- This is not needed in GitHub Actions as it uses OIDC authentication

### GitHub Actions Setup

1. In your GitHub repository, go to Settings > Secrets and Variables > Actions
2. Add the following secrets:
   - `WEBHOOK_URL`: Your webhook URL for receiving malware scan results
3. Add the following variables:
   - `AWS_ACCOUNT_ID`: Your AWS account ID (345594603974)

### Automated Deployment

The GitHub Actions workflow will:
1. Run on pull requests to the main branch:
   - Format check
   - Initialize Terraform
   - Validate configuration
   - Show plan
2. Run on pushes to the main branch:
   - All the above steps
   - Apply the changes automatically

You can also manually trigger the workflow and specify a different AWS region:
1. Go to the "Actions" tab
2. Select the "Terraform" workflow
3. Click "Run workflow"
4. Enter your desired AWS region (e.g., "us-west-2")
5. Click "Run workflow"

## Usage

Once the infrastructure is set up:
1. Upload files to the created S3 bucket
2. GuardDuty will automatically scan the files for malware
3. When findings are detected, they will be sent to your specified webhook

## Outputs

After applying the configuration, you'll get the following outputs:
- S3 bucket name
- Lambda function name
- EventBridge rule name

## Cleanup

There are two ways to destroy the infrastructure:

### Using GitHub Actions (Recommended)

1. Go to the "Actions" tab in your GitHub repository
2. Select the "Terraform Destroy" workflow
3. Click "Run workflow"
4. Select the environment to destroy (dev/prod)
5. Type "DESTROY" in the confirmation field
6. Click "Run workflow"

This will:
- Show you a plan of what will be destroyed
- Require explicit confirmation
- Clean up the Terraform state files
- Remove all created resources

### Using Local Terraform (Alternative)

If you need to destroy the infrastructure locally:

1. Initialize Terraform with your backend config:
   ```bash
   terraform init -backend-config=backend.hcl
   ```

2. Show the destroy plan:
   ```bash
   AWS_PROFILE=PowerUserAccess-345594603974 terraform plan -destroy
   ```

3. Execute the destroy:
   ```bash
   AWS_PROFILE=PowerUserAccess-345594603974 terraform destroy
   ```

Note: The Terraform state bucket and DynamoDB table are protected from accidental deletion. If you need to remove them, you'll need to:
1. Navigate to the bootstrap directory
2. Run `terraform destroy` there
3. Then run `AWS_PROFILE=PowerUserAccess-345594603974 terraform destroy` in the main directory

## Security Notes

- The S3 bucket is created with default settings. Consider adding additional security configurations based on your requirements.
- The Lambda function has minimal IAM permissions. Add additional permissions if needed.
- Store sensitive information (like webhook URLs) securely and consider using AWS Secrets Manager or Parameter Store.
- The GitHub Actions role has broad permissions for Terraform operations. Consider restricting these permissions based on your security requirements.
- The Terraform state is stored securely in S3 with versioning and encryption enabled.
- State locking is implemented using DynamoDB to prevent concurrent modifications.
