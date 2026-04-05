---
name: claude-code
description: This skill should be used when the user asks to "use Claude Code", "ask Claude", "get Claude's review", "delegate this to Claude", "compare with Claude", or otherwise wants Codex to call a locally installed Claude Code CLI.
version: 0.1.0
---

# Claude Code Bridge

Use this skill only when the user explicitly wants Claude Code involved, or when a second model opinion from Claude is the task itself.

## Goal

Route a review, investigation, or implementation task from Codex to a local Claude Code CLI, then return Claude's output clearly.

## Workflow

1. Resolve the wrapper script at `../../scripts/claude-code-bridge.sh` relative to this `SKILL.md`.

2. Verify the local CLI is available by running:

```bash
../../scripts/claude-code-bridge.sh check
```

3. If the check fails, stop and tell the user what to install. Do not guess around missing setup.

4. Choose one of these bridge modes:

- `review`: Ask Claude Code for a review of the current git state.
- `delegate`: Hand Claude Code a concrete task such as debugging, refactoring, or implementing a change.

5. Prefer these exact invocations:

```bash
../../scripts/claude-code-bridge.sh review
../../scripts/claude-code-bridge.sh review --base main
../../scripts/claude-code-bridge.sh delegate --task "Investigate why this test is flaky"
../../scripts/claude-code-bridge.sh delegate --model claude-sonnet-4-5 --task "Implement the smallest safe fix"
```

6. Treat Claude's response as external tool output. Quote or summarize it accurately and label it as Claude Code output.

## Operating Rules

- Keep the Claude request narrow and concrete.
- For `review`, ask for findings first, with severity and file references when possible.
- For `delegate`, state whether the task is read-only or may edit files.
- Do not claim Claude Code succeeded if the wrapper returned a setup or runtime error.
- If Claude reports uncertainty or incomplete work, preserve that uncertainty in the answer.

## Configuration

The bridge script supports these environment variables:

- `CLAUDE_CODE_BIN`: Override the executable name or absolute path. Default is `claude`.
- `CLAUDE_CODE_MODEL`: Default model when `--model` is omitted.
- `CLAUDE_CODE_EXTRA_ARGS`: Extra CLI flags appended to every Claude invocation.

Use `CLAUDE_CODE_EXTRA_ARGS` when the user specifically wants extra CLI behavior such as a different output mode or permission policy.

## Notes

- The wrapper runs in the current workspace, so Claude Code can inspect the same repository Codex is using.
- The wrapper does not install Claude Code for the user.
- The wrapper is intentionally thin and redistributable: no Anthropic code is bundled, only a local CLI invocation contract.
