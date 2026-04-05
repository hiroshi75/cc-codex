# Claude Code Plugin For Codex

The reverse of `openai/codex-plugin-cc`: this project lets Codex call a local Claude Code CLI for reviews, investigations, and delegated implementation work.

This repository is packaged as a redistributable Codex plugin. It does not bundle Anthropic code. It only invokes a locally installed `claude` CLI.

## Contents

- `.agents/plugins/marketplace.json`
  Marketplace manifest for Codex
- `plugins/claude-code/.codex-plugin/plugin.json`
  Plugin manifest
- `plugins/claude-code/skills/claude-code/SKILL.md`
  Skill used when the user asks Codex to involve Claude Code
- `plugins/claude-code/scripts/claude-code-bridge.sh`
  Thin wrapper around the local Claude Code CLI
- `install.sh`
  Main installer
- `bootstrap.sh`
  Stable bootstrap entrypoint for `curl | bash`

## What It Does

- Ask Claude Code to review the current git state from inside Codex
- Delegate investigations or implementation tasks from Codex to Claude Code
- Bring Claude Code output back into the active Codex workflow

## Requirements

- Claude Code CLI installed locally
- `claude` available on `PATH`
- `git`, `bash`, `curl`, `tar`, and `python3`

Install Claude Code with one of:

```bash
curl -fsSL https://claude.ai/install.sh | bash
```

or:

```bash
brew install --cask claude-code
```

## Quick Install

Because self-serve publishing to the official Plugin Directory is not available yet, installation currently requires local file placement. This repository includes an installer to make that manageable.

```bash
curl -fsSL https://raw.githubusercontent.com/hiroshi75/cc-codex/v0.1.0/install.sh | bash
```

This installs:

- the plugin into `~/.codex/plugins/claude-code`
- a marketplace entry into `~/.agents/plugins/marketplace.json`
- a reminder to install Claude Code CLI if `claude` is not available

This command uses the immutable `v0.1.0` tag instead of `main`, which avoids stale branch-cache issues on GitHub raw.

After the files are placed locally, open the Plugin Directory in Codex, install the plugin from your local marketplace, then start a new thread before trying to use it.

## Direct Script Usage

You can also use the wrapper directly:

```bash
plugins/claude-code/scripts/claude-code-bridge.sh check
plugins/claude-code/scripts/claude-code-bridge.sh review
plugins/claude-code/scripts/claude-code-bridge.sh review --base main --focus "Look for migration regressions"
plugins/claude-code/scripts/claude-code-bridge.sh delegate --task "Investigate why the integration test is flaky"
```

## Configuration

Behavior can be overridden with environment variables:

- `CLAUDE_CODE_BIN`
  Override the `claude` executable path
- `CLAUDE_CODE_MODEL`
  Set the default Claude model
- `CLAUDE_CODE_EXTRA_ARGS`
  Append extra flags to every Claude CLI invocation

Example:

```bash
export CLAUDE_CODE_MODEL=claude-sonnet-4-5
export CLAUDE_CODE_EXTRA_ARGS="--output-format stream-json"
```

## Design Notes

- For review mode, the wrapper summarizes git state and asks Claude for findings
- For delegate mode, the wrapper runs Claude in the current workspace
- Write permissions and Claude-side safety policy remain controlled by the user's Claude Code setup

## License

MIT
