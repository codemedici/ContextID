# Repository Structure

This repository scaffolds a secure, scalable, and reusable architecture for LLM-powered applications built with AWS, Terraform, Docker, and GitHub Actions. The structure below outlines the major directories and their intended contents.

```
.
├── docs/
│   ├── adr/
│   └── diagrams/
├── infrastructure/
│   ├── modules/
│   │   ├── network/
│   │   ├── ecs/
│   │   ├── rds-opensearch/
│   │   ├── lambda-proxies/
│   │   └── api-gateway/
│   └── environments/
│       ├── dev/
│       └── prod/
├── apps/
│   ├── privileged-llm/
│   └── quarantined-llm/
├── contextid/
│   ├── gateway/
│   ├── vc-engine/
│   ├── sdk/
│   │   ├── ts/
│   │   └── py/
│   └── schema/
├── scripts/
└── .github/
    └── workflows/
```

## Directory Descriptions

- **docs/** – Project documentation including Architectural Decision Records and design diagrams.
  - **adr/** – Records of architectural decisions and rationale.
  - **diagrams/** – Visual representations of system components and workflows.
- **infrastructure/** – Terraform code defining AWS infrastructure and environments.
  - **modules/** – Reusable Terraform modules encapsulating infrastructure components.
    - **network/** – VPCs, subnets, and security groups for network isolation.
    - **ecs/** – ECS Fargate task definitions and services for dual LLM containers.
    - **rds-opensearch/** – PostgreSQL and OpenSearch resources with KMS encryption.
    - **lambda-proxies/** – Lambda functions acting as secure API proxies.
    - **api-gateway/** – API Gateway configurations with DID/VC/BBS+ authorizers.
  - **environments/** – Environment-specific Terraform root configurations with remote state backends.
    - **dev/** – Calls modules with sandbox values; includes `backend.tf`, `main.tf`, `variables.tf`, and `outputs.tf`.
    - **prod/** – Production settings and state backend; mirrors `dev/` structure with hardened defaults.
- **apps/** – Application source code and Dockerfiles for LLM containers.
  - **privileged-llm/** – Code for the privileged LLM container.
  - **quarantined-llm/** – Code for the quarantined LLM container.
- **contextid/** – Implementation of the ContextID identity layer.
  - **gateway/** – API gateway logic and routing.
  - **vc-engine/** – Verifiable credential verification engine.
  - **sdk/** – Client SDKs for integrating ContextID features.
    - **ts/** – TypeScript SDK.
    - **py/** – Python SDK.
  - **schema/** – Credential schemas and related definitions.
- **scripts/** – Utility scripts for deployment and maintenance.
- **.github/workflows/** – GitHub Actions workflows for CI/CD.

Each directory currently contains placeholder files (e.g., `.gitkeep`) to maintain the structure and will be populated with implementation details as development progresses.
