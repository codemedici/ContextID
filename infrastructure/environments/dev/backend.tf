# ------------------------------------------------------------
# Terraform backend configuration (DEV Environment)
# Stores state in S3 and uses DynamoDB for state locking
# ------------------------------------------------------------
terraform {
  backend "s3" {
    bucket         = "terraform-state-dev"                    # Example S3 bucket for dev state
    key            = "llm-architecture/dev/terraform.tfstate" # Path within the bucket
    region         = "us-east-1"                              # Bucket region
    dynamodb_table = "terraform-lock-dev"                     # DynamoDB table for locking
    encrypt        = true                                     # Encrypt state at rest
  }
}
