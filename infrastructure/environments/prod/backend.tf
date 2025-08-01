# ------------------------------------------------------------
# Terraform backend configuration (PROD Environment)
# Stores state in S3 with DynamoDB table for locking
# ------------------------------------------------------------
terraform {
  backend "s3" {
    bucket         = "terraform-state-prod"                    # Production S3 bucket for state
    key            = "llm-architecture/prod/terraform.tfstate" # Path within the bucket
    region         = "us-east-1"                               # Bucket region
    dynamodb_table = "terraform-lock-prod"                     # DynamoDB table for locking
    encrypt        = true                                      # Encrypt state at rest
  }
}
