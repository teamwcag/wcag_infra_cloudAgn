#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "[1/2] Destroying compute plane..."
"${SCRIPT_DIR}/dev-down.sh"

echo "[2/2] Recreating compute plane..."
"${SCRIPT_DIR}/dev-up.sh"

echo "Dev reset complete."
