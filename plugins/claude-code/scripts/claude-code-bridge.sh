#!/usr/bin/env bash
set -euo pipefail

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "${SELF_DIR}/.." && pwd)"

CLAUDE_BIN="${CLAUDE_CODE_BIN:-claude}"
DEFAULT_MODEL="${CLAUDE_CODE_MODEL:-}"
DEFAULT_EXTRA_ARGS="${CLAUDE_CODE_EXTRA_ARGS:-}"

usage() {
  cat <<'EOF'
Usage:
  claude-code-bridge.sh check
  claude-code-bridge.sh review [--base <ref>] [--focus <text>] [--model <model>]
  claude-code-bridge.sh delegate --task <text> [--model <model>]

Environment:
  CLAUDE_CODE_BIN         Override the claude executable path.
  CLAUDE_CODE_MODEL       Default model when --model is omitted.
  CLAUDE_CODE_EXTRA_ARGS  Extra flags appended to every claude invocation.
EOF
}

json_escape() {
  python3 - <<'PY' "$1"
import json
import sys
print(json.dumps(sys.argv[1]))
PY
}

join_by() {
  local delimiter="$1"
  shift
  local first=1
  for item in "$@"; do
    if [[ $first -eq 1 ]]; then
      printf '%s' "$item"
      first=0
    else
      printf '%s%s' "$delimiter" "$item"
    fi
  done
}

require_claude() {
  if ! command -v "$CLAUDE_BIN" >/dev/null 2>&1; then
    cat <<EOF
Claude Code CLI was not found.

Expected executable: ${CLAUDE_BIN}

Install Claude Code first:
  Mac/Linux: curl -fsSL https://claude.ai/install.sh | bash
  Homebrew:  brew install --cask claude-code

Then rerun this command.
EOF
    exit 1
  fi
}

require_git_repo() {
  if ! git rev-parse --show-toplevel >/dev/null 2>&1; then
    echo "This command must be run inside a git repository." >&2
    exit 1
  fi
}

split_extra_args() {
  EXTRA_ARGS=()
  if [[ -n "${DEFAULT_EXTRA_ARGS}" ]]; then
    # Intentional word splitting for user-supplied CLI fragments.
    read -r -a EXTRA_ARGS <<<"${DEFAULT_EXTRA_ARGS}"
  fi
}

build_claude_args() {
  local model="$1"
  CLAUDE_ARGS=(-p)
  if [[ -n "${model}" ]]; then
    CLAUDE_ARGS+=(--model "${model}")
  fi
  split_extra_args
  if [[ ${#EXTRA_ARGS[@]} -gt 0 ]]; then
    CLAUDE_ARGS+=("${EXTRA_ARGS[@]}")
  fi
}

run_claude() {
  local prompt="$1"
  shift || true
  local model="$1"
  build_claude_args "${model}"
  "${CLAUDE_BIN}" "${CLAUDE_ARGS[@]}" "${prompt}"
}

render_git_summary() {
  local base_ref="${1:-}"
  if [[ -n "${base_ref}" ]]; then
    echo "Branch comparison target: ${base_ref}"
    git diff --stat "${base_ref}...HEAD" || true
    return
  fi

  echo "Working tree status:"
  git status --short --untracked-files=all || true
  echo
  echo "Staged diff summary:"
  git diff --cached --stat || true
  echo
  echo "Unstaged diff summary:"
  git diff --stat || true
}

build_review_prompt() {
  local base_ref="$1"
  local focus="$2"
  local summary
  summary="$(render_git_summary "${base_ref}")"

  cat <<EOF
You are Claude Code running as a secondary reviewer inside another coding session.

Review only. Do not modify files.

Repository: $(pwd)

Git summary:
${summary}

Review target:
$(if [[ -n "${base_ref}" ]]; then
    printf 'Compare the current branch against %s.\n' "${base_ref}"
  else
    printf 'Review the current working tree, including staged, unstaged, and untracked changes.\n'
  fi)

Required output format:
- Findings first, ordered by severity.
- Include file paths and line references when you can justify them.
- Call out behavioral regressions, correctness risks, security issues, and missing tests.
- If there are no findings, say that explicitly and mention residual risk.

Additional focus:
$(if [[ -n "${focus}" ]]; then
    printf '%s\n' "${focus}"
  else
    printf 'No extra focus provided.\n'
  fi)
EOF
}

build_delegate_prompt() {
  local task="$1"
  cat <<EOF
You are Claude Code running as a delegated coding agent inside another coding session.

Workspace: $(pwd)

Task:
${task}

Execution rules:
- Work directly in the current repository if edits are needed.
- Prefer the smallest safe change set.
- Explain blockers instead of guessing.
- End with a concise summary of what you changed or learned.
EOF
}

cmd="${1:-}"
if [[ -z "${cmd}" ]]; then
  usage
  exit 1
fi
shift || true

case "${cmd}" in
  check)
    require_claude
    printf '{\n'
    printf '  "ok": true,\n'
    printf '  "claudeBin": %s,\n' "$(json_escape "$(command -v "${CLAUDE_BIN}")")"
    printf '  "pluginRoot": %s\n' "$(json_escape "${PLUGIN_ROOT}")"
    printf '}\n'
    ;;
  review)
    require_claude
    require_git_repo
    base_ref=""
    focus=""
    model="${DEFAULT_MODEL}"
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --base)
          base_ref="${2:-}"
          shift 2
          ;;
        --focus)
          focus="${2:-}"
          shift 2
          ;;
        --model)
          model="${2:-}"
          shift 2
          ;;
        -h|--help)
          usage
          exit 0
          ;;
        *)
          echo "Unknown argument for review: $1" >&2
          usage
          exit 1
          ;;
      esac
    done
    prompt="$(build_review_prompt "${base_ref}" "${focus}")"
    run_claude "${prompt}" "${model}"
    ;;
  delegate)
    require_claude
    task=""
    model="${DEFAULT_MODEL}"
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --task)
          task="${2:-}"
          shift 2
          ;;
        --model)
          model="${2:-}"
          shift 2
          ;;
        -h|--help)
          usage
          exit 0
          ;;
        *)
          echo "Unknown argument for delegate: $1" >&2
          usage
          exit 1
          ;;
      esac
    done
    if [[ -z "${task}" ]]; then
      echo "delegate requires --task <text>." >&2
      exit 1
    fi
    prompt="$(build_delegate_prompt "${task}")"
    run_claude "${prompt}" "${model}"
    ;;
  -h|--help|help)
    usage
    ;;
  *)
    echo "Unknown subcommand: ${cmd}" >&2
    usage
    exit 1
    ;;
esac
