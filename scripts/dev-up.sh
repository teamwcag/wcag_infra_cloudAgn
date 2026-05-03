#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_DIR="${ENV_DIR:-${REPO_ROOT}/infra/envs/dev}"
TFVARS_FILE="${TFVARS_FILE:-terraform.tfvars}"
TF_CMD="${TF_CMD:-terraform}"

if [[ ! -d "${ENV_DIR}" ]]; then
  echo "Environment directory '${ENV_DIR}' not found" >&2
  exit 1
fi

echo "Initializing Terraform in ${ENV_DIR}"
"${TF_CMD}" -chdir="${ENV_DIR}" init -upgrade

APPLY_ARGS=(
  -auto-approve
  -var-file="${TFVARS_FILE}"
  -target=module.compute_k8s
)

echo "Applying compute stack (EKS + dependencies)..."
"${TF_CMD}" -chdir="${ENV_DIR}" apply "${APPLY_ARGS[@]}"

echo "EKS cluster is up. Export kubeconfig with:"
echo "  terraform -chdir=${ENV_DIR} output -raw kubeconfig > kubeconfig-dev.yaml"
