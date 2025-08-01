terraform {
  required_version = ">= 1.3"
}

# ------------------------------------------------------------
# RDS & OpenSearch module
# ------------------------------------------------------------
# Provides placeholders for a PostgreSQL database and an OpenSearch
# domain, both encrypted using KMS keys. Adjust networking, backups,
# and access policies to meet production requirements.
# ------------------------------------------------------------

# PostgreSQL instance for application data
resource "aws_db_instance" "postgres" {
  identifier             = var.db_identifier
  engine                 = "postgres"
  engine_version         = var.db_engine_version
  instance_class         = var.db_instance_class
  allocated_storage      = var.db_allocated_storage
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = var.db_subnet_group_name
  vpc_security_group_ids = var.db_security_group_ids
  storage_encrypted      = true
  kms_key_id             = var.db_kms_key_arn
  skip_final_snapshot    = true

  # TODO: configure backup retention, monitoring, and parameter groups
}

# OpenSearch domain for indexing and search
resource "aws_opensearch_domain" "search" {
  domain_name    = var.os_domain_name
  engine_version = var.os_engine_version

  cluster_config {
    instance_type  = var.os_instance_type
    instance_count = var.os_instance_count
  }

  ebs_options {
    ebs_enabled = true
    volume_size = var.os_volume_size
  }

  encrypt_at_rest {
    enabled    = true
    kms_key_id = var.os_kms_key_arn
  }

  # TODO: add access policies and fine-grained access control
}
