#!/usr/bin/env bash
set -euo pipefail

REPO_OWNER="${REPO_OWNER:-hiroshi75}"
REPO_NAME="${REPO_NAME:-cc-codex}"
REPO_REF="${REPO_REF:-main}"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

ARCHIVE_URL="https://github.com/${REPO_OWNER}/${REPO_NAME}/archive/refs/heads/${REPO_REF}.tar.gz"
curl -fsSL "${ARCHIVE_URL}" -o "${TMP_DIR}/repo.tar.gz"
tar -xzf "${TMP_DIR}/repo.tar.gz" -C "${TMP_DIR}"

bash "${TMP_DIR}/${REPO_NAME}-${REPO_REF}/install.sh"
