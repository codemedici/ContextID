# ------------------------------------------------------------
# Terraform backend configuration (DEV Environment)
# Stores state in S3 and uses DynamoDB for state locking
# ------------------------------------------------------------
terraform {
  backend "s3" {
    bucket         = "terraform-state-contextid-eu-west-2"
    key            = "terraform.tfstate"
    region         = "eu-west-2"
    dynamodb_table = "terraform-lock-contextid"
    encrypt        = true
  }
}
