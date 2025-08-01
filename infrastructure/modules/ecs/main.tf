terraform {
  required_version = ">= 1.3"
}

# ------------------------------------------------------------
# ECS module
# ------------------------------------------------------------
# Provisions an ECS Fargate cluster and task definition hosting the
# dual-LLM architecture (privileged & quarantined containers).
# Customize resources, IAM roles, and networking before deployment.
# ------------------------------------------------------------

# ECS cluster to run LLM workloads
resource "aws_ecs_cluster" "this" {
  name = var.cluster_name
  # TODO: add cluster settings, logging, and capacity providers
}

# Task definition with two containers for privileged and quarantined LLMs
resource "aws_ecs_task_definition" "dual_llm" {
  family                   = "dual-llm"
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arn

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
    },
    {
      name         = "quarantined-llm"
      image        = var.quarantined_llm_image
      essential    = true
      portMappings = [{ containerPort = 9090 }]
    }
  ])

  # TODO: add logging, volumes, and further hardening options
}
