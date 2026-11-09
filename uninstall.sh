#!/usr/bin/env bash
# Remove the launchd agent, CLI symlink and skills. Config and history are kept.
set -euo pipefail
BIN_DIR="${BIN_DIR:-$HOME/.local/bin}"
[ -x "$BIN_DIR/tokenplan" ] && "$BIN_DIR/tokenplan" uninstall || true
rm -f "$BIN_DIR/tokenplan"
rm -rf "$HOME/.claude/skills/tokenplan" "$HOME/.codex/skills/tokenplan"
echo "removed. config: ~/.config/tokenplan, history: ~/.local/state/tokenplan"
