# WCAG Remediator Infra

Terraform and Helm configuration for the WCAG remediation platform.

## Current Scope

This repo currently manages the AWS deployment path, including:

- VPC and networking
- EKS cluster
- Redis
- Postgres
- Windows worker infrastructure
- AWS Load Balancer Controller
- Helm release for:
  - frontend
  - `document-service`
  - `token-service`
  - ALB ingress

## Repository Structure

- `infra/envs/dev`
  - active development environment
- `infra/modules`
  - reusable Terraform modules
- `k8s/charts/platform`
  - application Helm chart
- `scripts`
  - helper scripts for local environment operations

## Quick Start

From:

- `infra/envs/dev`

Run:

```bash
terraform init
terraform plan
terraform apply
```

## Important Notes

- Local secrets and environment-specific values should stay in `terraform.tfvars`, which is intentionally gitignored.
- Use `terraform.tfvars.example` as the checked-in template.
- Public DNS is currently external to this repo and handled in Cloudflare.
- HTTPS/ACM enablement is supported through the Terraform env variables in `infra/envs/dev`.

## Related App Repo

The matching application repository is:

- `teamwcag/wcag-remediator-app`
