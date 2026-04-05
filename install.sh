#!/usr/bin/env bash
set -euo pipefail

REPO_OWNER="${REPO_OWNER:-hiroshi75}"
REPO_NAME="${REPO_NAME:-cc-codex}"
REPO_REF="${REPO_REF:-main}"
PLUGIN_NAME="claude-code"
MARKETPLACE_DIR="${HOME}/.agents/plugins"
MARKETPLACE_PATH="${MARKETPLACE_DIR}/marketplace.json"
PLUGIN_PARENT_DIR="${HOME}/plugins"
PLUGIN_DEST_DIR="${PLUGIN_PARENT_DIR}/${PLUGIN_NAME}"

usage() {
  cat <<EOF
Install ${PLUGIN_NAME} for Codex.

Usage:
  ./install.sh

Environment overrides:
  REPO_OWNER   GitHub owner to fetch from. Default: ${REPO_OWNER}
  REPO_NAME    GitHub repository name. Default: ${REPO_NAME}
  REPO_REF     Git ref to fetch. Default: ${REPO_REF}

This installs:
  Plugin files to: ${PLUGIN_DEST_DIR}
  Marketplace to:  ${MARKETPLACE_PATH}
EOF
}

need_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

log() {
  printf '[install] %s\n' "$1" >&2
}

warn() {
  printf '[install] warning: %s\n' "$1" >&2
}

cleanup() {
  if [[ -n "${TMP_DIR:-}" && -d "${TMP_DIR:-}" ]]; then
    rm -rf "${TMP_DIR}"
  fi
}
trap cleanup EXIT

copy_tree() {
  local src="$1"
  local dst="$2"
  mkdir -p "$(dirname "${dst}")"
  rm -rf "${dst}"
  cp -R "${src}" "${dst}"
}

fetch_repo_snapshot() {
  TMP_DIR="$(mktemp -d)"
  local archive_url="https://github.com/${REPO_OWNER}/${REPO_NAME}/archive/refs/heads/${REPO_REF}.tar.gz"
  log "Fetching ${archive_url}"
  curl -fsSL "${archive_url}" -o "${TMP_DIR}/repo.tar.gz"
  tar -xzf "${TMP_DIR}/repo.tar.gz" -C "${TMP_DIR}"
  printf '%s\n' "${TMP_DIR}/${REPO_NAME}-${REPO_REF}"
}

resolve_source_root() {
  local script_dir
  if [[ "${BASH_SOURCE[0]-}" != "" ]]; then
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]-}")" && pwd)"
    if [[ -f "${script_dir}/plugins/${PLUGIN_NAME}/.codex-plugin/plugin.json" ]]; then
      printf '%s\n' "${script_dir}"
      return
    fi
  fi
  fetch_repo_snapshot
}

write_marketplace() {
  mkdir -p "${MARKETPLACE_DIR}"
  python3 - "${MARKETPLACE_PATH}" "${PLUGIN_NAME}" <<'PY'
import json
import os
import sys

marketplace_path = sys.argv[1]
plugin_name = sys.argv[2]

entry = {
    "name": plugin_name,
    "source": {
        "source": "local",
        "path": f"./plugins/{plugin_name}",
    },
    "policy": {
        "installation": "AVAILABLE",
        "authentication": "ON_INSTALL",
    },
    "category": "Developer Tools",
}

if os.path.exists(marketplace_path):
    with open(marketplace_path, "r", encoding="utf-8") as f:
        data = json.load(f)
else:
    data = {
        "name": "local-user-plugins",
        "interface": {
            "displayName": "Local User Plugins",
        },
        "plugins": [],
    }

plugins = [p for p in data.get("plugins", []) if p.get("name") != plugin_name]
plugins.append(entry)
data["plugins"] = plugins

if not data.get("name"):
    data["name"] = "local-user-plugins"

interface = data.get("interface")
if not isinstance(interface, dict):
    interface = {}
if not interface.get("displayName"):
    interface["displayName"] = "Local User Plugins"
data["interface"] = interface

with open(marketplace_path, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
PY
}

main() {
  if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
    exit 0
  fi

  need_cmd curl
  need_cmd tar
  need_cmd python3

  local source_root
  source_root="$(resolve_source_root)"

  if [[ ! -f "${source_root}/plugins/${PLUGIN_NAME}/.codex-plugin/plugin.json" ]]; then
    echo "Plugin source not found in ${source_root}" >&2
    exit 1
  fi

  log "Installing plugin into ${PLUGIN_DEST_DIR}"
  mkdir -p "${PLUGIN_PARENT_DIR}"
  copy_tree "${source_root}/plugins/${PLUGIN_NAME}" "${PLUGIN_DEST_DIR}"

  log "Updating ${MARKETPLACE_PATH}"
  write_marketplace

  if ! command -v claude >/dev/null 2>&1; then
    warn "Claude Code CLI was not found in PATH."
    warn "Install it with: curl -fsSL https://claude.ai/install.sh | bash"
  fi

  cat <<EOF

Installed ${PLUGIN_NAME} for Codex.

Plugin path:
  ${PLUGIN_DEST_DIR}

Marketplace:
  ${MARKETPLACE_PATH}

Next steps:
  1. Restart Codex if it is already running.
  2. Ask Codex: "Use Claude Code to review this change."
  3. If needed, install Claude Code CLI:
     curl -fsSL https://claude.ai/install.sh | bash
EOF
}

main "$@"
