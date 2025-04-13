# test-terraform-github-oidc-s3
Test setup of S3 bucket with AWS GuardDuty using Terraform

## Notes

### AWS
Provisioned with AWS tag `testtfghs3`

### Terraform init
```bash
AWS_PROFILE=PowerUserAccess-345594603974 aws s3api create-bucket --bucket test-gh-oidc-s3-terraform-state-bucket --region ap-southeast-1 --create-bucket-configuration LocationConstraint=ap-southeast-1
AWS_PROFILE=PowerUserAccess-345594603974 terraform init
```

Outputs:
```
{
    "Location": "http://test-gh-oidc-s3-terraform-state-bucket.s3.amazonaws.com/"
}
```