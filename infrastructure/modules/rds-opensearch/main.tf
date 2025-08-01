terraform {
  required_version = ">= 1.3"
}

# ------------------------------------------------------------
# RDS & OpenSearch module
# ------------------------------------------------------------
# Provisions an encrypted PostgreSQL database and an OpenSearch domain
# with secure networking, IAM roles for data access, and CloudWatch
# monitoring to support production workloads.
# ------------------------------------------------------------

# IAM role that application workloads can assume to access data stores
data "aws_iam_policy_document" "data_access_assume" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "data_access" {
  name               = "data-access-role"
  assume_role_policy = data.aws_iam_policy_document.data_access_assume.json
}

data "aws_iam_policy_document" "data_access" {
  statement {
    effect = "Allow"
    actions = [
      "rds-db:connect",
      "es:ESHttpGet",
      "es:ESHttpPost",
      "es:ESHttpPut",
      "es:ESHttpDelete"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "data_access" {
  name   = "data-access-policy"
  role   = aws_iam_role.data_access.id
  policy = data.aws_iam_policy_document.data_access.json
}

# -------------------------------------------
# PostgreSQL instance
# -------------------------------------------

# Subnet group spanning private subnets
resource "aws_db_subnet_group" "this" {
  name       = var.db_subnet_group_name
  subnet_ids = var.db_subnet_ids

  tags = merge(var.tags, { Name = "${var.db_identifier}-subnets" })
}

resource "aws_db_instance" "postgres" {
  identifier                      = var.db_identifier
  engine                          = "postgres"
  engine_version                  = var.db_engine_version
  instance_class                  = var.db_instance_class
  allocated_storage               = var.db_allocated_storage
  username                        = var.db_username
  password                        = var.db_password
  db_subnet_group_name            = aws_db_subnet_group.this.name
  vpc_security_group_ids          = var.db_security_group_ids
  storage_encrypted               = true
  kms_key_id                      = var.db_kms_key_arn
  deletion_protection             = true
  backup_retention_period         = 7
  multi_az                        = var.db_multi_az
  performance_insights_enabled    = true
  enabled_cloudwatch_logs_exports = ["postgresql"]
  skip_final_snapshot             = false

  tags = merge(var.tags, { Name = var.db_identifier })
}

# CloudWatch alarm for high CPU utilization
resource "aws_cloudwatch_metric_alarm" "db_cpu" {
  alarm_name          = "${var.db_identifier}-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_actions       = var.alarm_topic_arns

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.postgres.id
  }
}

# -------------------------------------------
# OpenSearch domain
# -------------------------------------------

resource "aws_cloudwatch_log_group" "opensearch" {
  name              = "/aws/opensearch/${var.os_domain_name}"
  retention_in_days = 30
}

data "aws_iam_policy_document" "os_access" {
  statement {
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.data_access.arn]
    }
    actions   = ["es:*"]
    resources = ["*"]
  }
}

resource "aws_opensearch_domain" "search" {
  domain_name    = var.os_domain_name
  engine_version = var.os_engine_version

  cluster_config {
    instance_type          = var.os_instance_type
    instance_count         = var.os_instance_count
    zone_awareness_enabled = true
  }

  ebs_options {
    ebs_enabled = true
    volume_size = var.os_volume_size
    volume_type = "gp3"
  }

  encrypt_at_rest {
    enabled    = true
    kms_key_id = var.os_kms_key_arn
  }

  node_to_node_encryption { enabled = true }

  domain_endpoint_options {
    enforce_https       = true
    tls_security_policy = "Policy-Min-TLS-1-2-2019-07"
  }

  vpc_options {
    subnet_ids         = var.os_subnet_ids
    security_group_ids = var.os_security_group_ids
  }

  log_publishing_options {
    log_type                 = "ES_APPLICATION_LOGS"
    cloudwatch_log_group_arn = aws_cloudwatch_log_group.opensearch.arn
  }

  advanced_security_options {
    enabled                        = true
    internal_user_database_enabled = true
    master_user_options {
      master_user_name     = var.os_master_user
      master_user_password = var.os_master_password
    }
  }

  access_policies = data.aws_iam_policy_document.os_access.json
}

# Alarm if the cluster status turns red
resource "aws_cloudwatch_metric_alarm" "os_status_red" {
  alarm_name          = "${var.os_domain_name}-status-red"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ClusterStatus.red"
  namespace           = "AWS/ES"
  period              = 60
  statistic           = "Maximum"
  threshold           = 0
  alarm_actions       = var.alarm_topic_arns

  dimensions = {
    DomainName = aws_opensearch_domain.search.domain_name
  }
}

