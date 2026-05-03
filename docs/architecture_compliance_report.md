# Architecture Compliance Report

## System Diagram (current state)

```
Users/Web UI (not implemented here)
    │
    │  HTTP(S) via optional nginx Ingress (disabled by default) — wcag/k8s/charts/platform/templates/ingress.yaml:1-22
    ▼
upload-api Deployment (single container image) — wcag/k8s/charts/platform/templates/deployment.yaml:2-22
    │
    ├─(intended) upload/download of files → S3 docs bucket — wcag/infra/modules/storage_docs/_impl/aws/main.tf:18-74
    ├─(intended) invoke Analyzer/Remediator jobs → sample standalone Job manifest — wcag/k8s/charts/platform/templates/job.yaml:1-16
    └─ExternalSecret placeholder for object store URL — wcag/k8s/charts/platform/templates/externalsecret.yaml:1-13
```

**Missing:** API gateway/authn/rate limiting, orchestrator/job launcher, report/download service, metadata DB, queue, observability plumbing, Analyzer vs. Remediator job separation, and any Web UI assets.

## Repository Map

- `wcag/infra/envs/dev` combines networking, storage, IAM bastion, and EKS modules in one Terraform state (`main.tf`, `bastion.tf`, `compute_k8s.tf`).  
- `wcag/infra/modules/networking` and `compute_k8s` expose an interface + `_impl/{aws,azure,gcp}` pattern, but only the AWS variants are implemented; Azure/GCP are stubs (e.g., `wcag/infra/modules/compute_k8s/_impl/azure/main.tf`).  
- `wcag/infra/modules/storage_docs/_impl/aws` provisions a single S3 bucket with versioning/lifecycle rules but no KMS key.  
- `wcag/k8s/charts/platform` is the lone Helm chart, covering upload-api Deployment, Service, optional Ingress, ExternalSecret, and a demo Job.  
- `docs/` contains the prior Confluence export — no architecture-specific automation.  
- `wcag/scripts` (added) now holds `dev-up.sh`, `dev-down.sh`, and `dev-reset.sh` wrappers for compute lifecycle control.

## Service-by-Service Assessment

| Component | Expectation | Status | Evidence / Notes |
|-----------|-------------|--------|------------------|
| Web UI | Upload/download UX with Analyze & Remediate buttons | ❌ Missing | No UI code anywhere in repo (`rg --files` result). |
| API Gateway layer | TLS termination, OIDC/JWT auth, rate limiting | ❌ Missing | Only Kubernetes Ingress optional block (`wcag/k8s/charts/platform/templates/ingress.yaml:1-22`) without auth/rate limiting. |
| Upload Service | Accept files, push to S3 | ⚠️ Stub | `upload-api` deployment exists but uses demo container image (`wcag/k8s/charts/platform/values.yaml:1-9`) and has no env/S3 wiring. |
| Orchestrator + Job Launcher | Decide analyze vs remediate, enqueue jobs | ❌ Missing | No deployments, controllers, or queue usage. |
| Analyzer Job | Containerized run per request | ⚠️ Placeholder | Single Job manifest uses `busybox` (`templates/job.yaml:11-15`). No linkage to Upload service nor metadata. |
| Remediator Job | Dedicated job worker | ⚠️ Placeholder | Same manifest intended for Remediator, but no separate template or image. |
| Report/Download Service | List artifacts, generate download links | ❌ Missing | No chart, deployment, or infra referencing this concern. |
| Metadata DB | Track jobs, statuses, artifact paths | ❌ Missing | Terraform lacks RDS/Dynamo/etc; no schema definitions. |
| Queue (optional requirement) | Buffer jobs | ❌ Missing | No SQS/SNS/Kafka modules or Helm releases. |
| Storage (S3 + KMS) | Raw uploads, reports, remediations | ⚠️ Partial | S3 bucket exists without KMS or `prevent_destroy` (`storage_docs/_impl/aws/main.tf:18-74`). |
| Observability | OTEL, logging, metrics | ❌ Missing | No collector Helm chart, OTEL configs, or CloudWatch pipelines. |

## Runtime Flow Validation

1. **Upload ➜ S3:** Intended path is Upload API ➜ S3 bucket. The Storage module provisions `wcag-dev-docs` with versioning/lifecycle policies (`storage_docs/_impl/aws/main.tf:18-54`), but upload-api lacks S3 credentials/env wiring, so flow cannot complete. The IAM role for doc service (`compute_k8s/_impl/aws/iam.tf:27-93`) targets namespace `wcag-docs/doc-service`, yet no service account or deployment uses it.
2. **Job record creation:** There is no metadata DB or CRD to record jobs; Helm chart has no ConfigMap/DB connection. Flow fails at this step.
3. **Analyze/Remediate decision:** Orchestrator absent, so job type selection is manual. `templates/job.yaml:4-15` is a static Job with hard-coded args; no API ties exist.
4. **Job output ➜ S3:** IAM policy allows S3 access, but no Job spec mounts credentials or references the IRSA role, so artifacts cannot be written without extra manifests.
5. **UI fetch artifact links:** Missing Web UI/report service. No signed URL generation or list endpoint exists.

Result: Only networking + EKS foundations are provisioned; runtime flows are mostly unimplemented.

## Security Boundary Review

- **Service-to-service auth:** Kubernetes manifests run a single deployment without NetworkPolicies, sidecars, or auth middleware (`templates/deployment.yaml:2-22`). There is no mention of mutual TLS or JWT propagation, so lateral movement is unchecked.
- **API security:** Ingress is disabled by default and, when enabled, has no TLS secret automation or auth annotations (`templates/ingress.yaml:1-22`). An API Gateway tier (OIDC, rate-limit, WAF) is entirely missing.
- **IAM least privilege:** The doc-service IAM role limits permissions to the single bucket (`compute_k8s/_impl/aws/iam.tf:27-51`), which is good, but it presumes a specific namespace/service account that does not exist, so IRSA is unusable. There is no IAM role for Upload or Report services, meaning they would default to node IAM credentials (bad practice).
- **Secrets handling:** ExternalSecret expects a ClusterSecretStore named `cloud-secrets` (`templates/externalsecret.yaml:6-8`), but none is provisioned. Secrets path only exposes `OBJECT_STORE_URL`; no mention of DB creds, API keys, or JWT signing keys.
- **KMS & encryption:** S3 bucket uses AES256 SSE (`storage_docs/_impl/aws/main.tf:56-63`), not a customer-managed KMS key. KMS + CMK grants are required per architecture.
- **Network isolation:** VPC is split into public/private/data subnets (`networking/_impl/aws/main.tf:27-117`), but there are no security groups for services beyond the bastion. No NetworkPolicies exist in Kubernetes manifests.

## Infra-as-Code Review

- **Foundation vs. compute split:** `infra/envs/dev/main.tf` provisions VPC + S3, `bastion.tf` provisions EC2/IAM, and `compute_k8s.tf` provisions EKS—all under one Terraform backend (`providers.tf:1-20`). Destroying the env removes persistent resources, violating the requirement.
- **State targeting:** All resources share the `networking/terraform.tfstate` key (`providers.tf:8-15`). There are no child workspaces or separate directories for compute vs. foundation.
- **Lifecycle protections:** Persistent assets (S3, KMS once added, DB, VPC) lack `prevent_destroy` or dedicated states, so a developer `terraform destroy` would wipe artifacts.
- **Multi-cloud modules:** Azure/GCP `_impl` folders are empty placeholders, so the codebase is not actually cloud-agnostic today.
- **Pipelines:** No dev-up/dev-down automation existed prior to this review; manual `terraform apply` runs were required.

## Key Gaps & Recommended Refactors

1. **Missing application services:** Add discrete Helm charts (or a mono-chart with multiple deployments) for Upload, Orchestrator, Report, Analyzer job templates, Remediator job templates, and a lightweight UI. Each service needs its own service account + IRSA role so S3/DB access is scoped tightly.
2. **API Gateway tier:** Introduce AWS API Gateway (HTTP API) or an ALB ingress controller with AWS WAF + Cognito/OIDC. Terminate TLS and enforce rate limits before traffic reaches upload-api.
3. **Metadata layer:** Provision Aurora Serverless v2 or DynamoDB for job metadata, and add a Kubernetes `metadata-service` that persists job state + artifact paths. Use Secrets Manager + ExternalSecret to inject credentials.
4. **Job orchestration:** Create SQS (queue optional requirement) and Orchestrator service that writes job records, enqueues messages, and spins up Kubernetes Jobs via the K8s API. Provide CRDs or Argo/K-native? but walkway: use plain Jobs with `ttlSecondsAfterFinished`.
5. **Observability:** Deploy OpenTelemetry Collector (Kubernetes DaemonSet) plus CloudWatch/X-Ray exporters; instrument services with OTEL SDKs. Provide central logging (e.g., Fluent Bit) and metrics (Prometheus + AMP).
6. **Foundation split:** Move VPC/S3/KMS/IAM/DB into `infra/foundation/<env>` with its own backend. Keep EKS/node groups/add-ons and bastion in `infra/compute/<env>` referencing data sources for VPC/subnets. Mark buckets, KMS keys, and DBs with `lifecycle { prevent_destroy = true }`.
7. **Cost controls:** Scale node group min size to 0 when cluster idle, support spot instances, and supply scripts/pipeline jobs for dev-up/down/reset (implemented below).

## Concrete Refactor Plan (Deliverable B)

### Proposed folder/module structure

```
infra/
  foundation/
    modules/
      networking/
      storage/
      kms/
      metadata_db/
      queue/
    envs/dev/main.tf        # VPC, subnets, NAT, S3, KMS, RDS/Dynamo, IAM, SQS, Secrets Manager
  compute/
    modules/
      eks_cluster/
      bastion/
    envs/dev/main.tf        # EKS, node groups, add-ons, ingress controller, ExternalDNS, ExternalSecrets store
k8s/
  charts/
    upload-service/
    orchestrator-service/
    report-service/
    analyzer-job/
    remediator-job/
    ui/
    otel-collector/
scripts/
  dev-up.sh, dev-down.sh, dev-reset.sh (added)
```

### Files to create/edit

| File/Path | Action |
|-----------|--------|
| `infra/foundation/envs/dev/main.tf` | Instantiate networking, storage, KMS, Secrets Manager, metadata DB, queue modules; output IDs for compute stack. |
| `infra/foundation/modules/storage` | Extend current S3 module with CMK encryption + lifecycle + `prevent_destroy`. |
| `infra/foundation/modules/kms` | Define CMK(s) for S3 + EKS secrets. |
| `infra/foundation/modules/metadata_db` | Choose DynamoDB (serverless, simple) to store job metadata; output table name + IAM policies. |
| `infra/foundation/modules/queue` | Provision SQS standard queue; output ARN/URL for Orchestrator. |
| `infra/compute/envs/dev/main.tf` | Reference foundation outputs (via remote state data sources) and provision EKS, node groups, IAM roles per service, API Gateway or ingress components, observability add-ons, ExternalSecrets ClusterSecretStore. |
| `k8s/charts/*` | Split the monolithic chart into service-specific charts with dedicated ServiceAccounts + annotations for IRSA, configmaps referencing metadata DB + queue. |
| `k8s/charts/api-gateway` (or Terraform module) | Manage API Gateway/ALB resources, TLS certs, rate limits, and WAF. |
| `k8s/charts/otel-collector` | Ship metrics/logs/traces via OTEL exporter. |
| `scripts/dev-*.sh` | Already added; extend once directories split (accept `STACK=foundation|compute`). |

### Terraform module split recommendations

1. Extract S3/KMS resources from `wcag/infra/envs/dev/main.tf` into `infra/foundation`.
2. Convert `module.networking` outputs into remote state consumed by compute via `data "terraform_remote_state"`.
3. Move bastion + EKS-specific IAM into compute stack; keep NAT/vpc endpoints in foundation.
4. Add new modules (metadata DB, queue, API gateway) with opinionated defaults but optional toggles for other clouds.

## Dev Cost-Control Implementation (Deliverable C)

### Scripts & commands

- `scripts/dev-up.sh` initializes Terraform in `infra/envs/dev` and applies only the compute module (`module.compute_k8s`) so VPC/S3 remain untouched (`wcag/scripts/dev-up.sh:1-27`).  
  Command: `./scripts/dev-up.sh` (optional `ENV_DIR` / `TFVARS_FILE` overrides).
- `scripts/dev-down.sh` performs a targeted destroy on `module.compute_k8s`, letting persistent resources survive (`wcag/scripts/dev-down.sh:1-26`).  
  Command: `./scripts/dev-down.sh`.
- `scripts/dev-reset.sh` chains the previous scripts to cycle the cluster (`wcag/scripts/dev-reset.sh:1-12`).

Future split: once foundation/compute directories exist, update scripts to run `terraform -chdir=infra/compute/envs/dev` by default and add a `scripts/foundation-apply.sh` for rare foundation changes.

### Terraform clean-destroy safeguards to add

1. Introduce `lifecycle { prevent_destroy = true }` on S3 buckets, KMS keys, DB tables.
2. Enable final snapshotting on future DB resources; add `deletion_protection = true`.
3. Ensure Kubernetes add-ons (Ingress controllers, AWS Load Balancer Controller) annotate LoadBalancers with `service.beta.kubernetes.io/aws-load-balancer-type` so they delete cleanly.
4. Add `kubectl delete ingress --all -A` and `kubectl delete pvc --all -A` hooks inside scripts (pre-destroy) to keep AWS load balancers and EBS volumes from blocking `terraform destroy`.

### Pre-destroy checklist

1. Scale application Deployments to zero to drain workloads (`kubectl scale deploy -n <ns> --replicas=0`).  
2. Delete Ingress resources and wait for ALB/NLB cleanup (`kubectl delete ingress -A --wait`).  
3. Remove persistent volumes/claims and snapshot needed data.  
4. Ensure no Jobs are running; `kubectl delete job -A --wait`.  
5. Run `./scripts/dev-down.sh` to destroy EKS only; verify CloudFormation stacks for load balancers are gone before exiting.

## Top 5 Cost Drivers & Mitigations (Deliverable D)

1. **Always-on EKS node group (t3.large x2) — `compute_k8s.tf:12-15`:** Reduce desired/min to 0 when idle, enable Cluster Autoscaler + Karpenter for scale-to-zero worker nodes, and use mixed spot/on-demand instances to cut compute spend by ~60%.  
2. **NAT Gateway (`networking/_impl/aws/main.tf:69-80`):** Each NAT costs ~$32/mo. Keep a single AZ NAT (already the case) and add VPC interface endpoints for ECR, S3, SSM so worker traffic bypasses the NAT when the cluster is online briefly. For dev, consider AWS PrivateLink or toggling NAT off when compute is destroyed.  
3. **Bastion EC2 instance (`bastion.tf:71-85`):** Even t3.micro accrues cost while idle. Replace with EC2 Instance Connect Endpoint or AWS Systems Manager port forwarding to eliminate the host.  
4. **EKS control plane & add-ons (`compute_k8s/_impl/aws/main.tf:12-48`):** Control plane costs ~$74/mo regardless of node count. Use `dev-down.sh` to destroy compute when unused, and consider EKS Blueprints with `terraform destroy` guardrails for quick recreate.  
5. **S3 storage growth without intelligent tiering (`storage_docs/_impl/aws/main.tf:36-52`):** Lifecycle policy moves to STANDARD_IA after 30 days but deletes fully at 365 days. Add Glacier Deep Archive transitions for reports/remediated outputs after 90 days and keep metadata in DB instead of retaining duplicate artifacts to minimize storage cost while preserving compliance.

---

**Summary:** The repo provisions baseline AWS networking, storage, and an EKS cluster but omits most platform services and security guardrails mandated by the architecture. The new scripts provide immediate compute cost controls, and the refactor plan above outlines how to align the codebase with the desired architecture while protecting persistent data and minimizing costs.
