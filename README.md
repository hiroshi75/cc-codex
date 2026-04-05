# Claude Code Plugin For Codex

`openai/codex-plugin-cc` の逆方向版です。Codex からローカルの Claude Code CLI を呼び出し、レビューや調査、実装タスクを Claude に委譲できます。

このリポジトリは Codex 向けの再配布可能なプラグイン構成を含みます。Anthropic のコード本体は同梱せず、ローカルにインストール済みの `claude` CLI だけを呼び出します。

## Contents

- `.agents/plugins/marketplace.json`
  Codex 用 marketplace manifest
- `plugins/claude-code/.codex-plugin/plugin.json`
  プラグイン manifest
- `plugins/claude-code/skills/claude-code/SKILL.md`
  Codex が「Claude を使って」と依頼されたときに使うスキル
- `plugins/claude-code/scripts/claude-code-bridge.sh`
  ローカルの Claude Code CLI を呼ぶ薄いラッパー

## What It Does

- Codex から Claude Code にレビューを依頼する
- Codex から Claude Code に実装や調査タスクを委譲する
- 同じワークスペース上で Claude の結果を Codex 側に持ち帰る

## Requirements

- Claude Code CLI がローカルに入っていること
- `claude` が `PATH` から実行できること
- `git` と `bash` が使えること

Claude Code のインストール例:

```bash
curl -fsSL https://claude.ai/install.sh | bash
```

または:

```bash
brew install --cask claude-code
```

## Direct Script Usage

CLI 単体でも以下のように使えます。

```bash
plugins/claude-code/scripts/claude-code-bridge.sh check
plugins/claude-code/scripts/claude-code-bridge.sh review
plugins/claude-code/scripts/claude-code-bridge.sh review --base main --focus "Look for migration regressions"
plugins/claude-code/scripts/claude-code-bridge.sh delegate --task "Investigate why the integration test is flaky"
```

## Configuration

環境変数で挙動を上書きできます。

- `CLAUDE_CODE_BIN`
  `claude` 以外の実行パスを使う
- `CLAUDE_CODE_MODEL`
  デフォルトモデルを指定する
- `CLAUDE_CODE_EXTRA_ARGS`
  毎回追加したい Claude CLI フラグを指定する

例:

```bash
export CLAUDE_CODE_MODEL=claude-sonnet-4-5
export CLAUDE_CODE_EXTRA_ARGS="--output-format stream-json"
```

## Design Notes

- レビュー時は wrapper が git 状況を添えて Claude に依頼します
- 実装委譲時は現在のワークスペースで Claude を実行します
- 書き込み権限や詳細な Claude CLI ポリシーはユーザー側の Claude 設定に委ねます

## License

MIT
