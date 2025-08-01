terraform {
  required_version = ">= 1.3"
}

# ------------------------------------------------------------
# ECS module
# ------------------------------------------------------------
# Creates an ECS Fargate cluster with container insights enabled,
# defines a dual-container task definition, and deploys a service
# with autoscaling and CloudWatch logging.
# ------------------------------------------------------------

data "aws_region" "current" {}

# CloudWatch log group for task logs
resource "aws_cloudwatch_log_group" "this" {
  name              = "/ecs/${var.cluster_name}"
  retention_in_days = var.log_retention_in_days
}

# IAM role for task execution (pulling images, publishing logs)
data "aws_iam_policy_document" "ecs_assume" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "execution" {
  name               = "${var.cluster_name}-exec-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume.json
}

resource "aws_iam_role_policy_attachment" "execution" {
  role       = aws_iam_role.execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Task role assumed by application containers
resource "aws_iam_role" "task" {
  name               = "${var.cluster_name}-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume.json
}

# ECS cluster to run LLM workloads with container insights
resource "aws_ecs_cluster" "this" {
  name = var.cluster_name

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

# Task definition with two containers for privileged and quarantined LLMs
resource "aws_ecs_task_definition" "dual_llm" {
  family                   = "dual-llm"
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.execution.arn
  task_role_arn            = aws_iam_role.task.arn

  container_definitions = jsonencode([
    {
      name         = "privileged-llm"
      image        = var.privileged_llm_image
      essential    = true
      portMappings = [{ containerPort = 8080 }]
      environment = [
        {
          name  = "QUARANTINED_LLM_ENDPOINT"
          value = "http://localhost:9090"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.this.name
          awslogs-region        = data.aws_region.current.name
          awslogs-stream-prefix = "privileged"
        }
      }
    },
    {
      name         = "quarantined-llm"
      image        = var.quarantined_llm_image
      essential    = true
      portMappings = [{ containerPort = 9090 }]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.this.name
          awslogs-region        = data.aws_region.current.name
          awslogs-stream-prefix = "quarantined"
        }
      }
    }
  ])
}

# ECS service running the task definition
resource "aws_ecs_service" "this" {
  name            = var.service_name
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.dual_llm.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = var.security_group_ids
    assign_public_ip = false
  }

  lifecycle {
    ignore_changes = [task_definition]
  }
}

# Autoscaling target for the service
resource "aws_appautoscaling_target" "this" {
  max_capacity       = var.max_capacity
  min_capacity       = var.min_capacity
  resource_id        = "service/${aws_ecs_cluster.this.name}/${aws_ecs_service.this.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

# Scale based on average CPU utilization
resource "aws_appautoscaling_policy" "cpu" {
  name               = "ecs-cpu-target"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.this.resource_id
  scalable_dimension = aws_appautoscaling_target.this.scalable_dimension
  service_namespace  = aws_appautoscaling_target.this.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = 50
    scale_in_cooldown  = 300
    scale_out_cooldown = 300
  }
}

