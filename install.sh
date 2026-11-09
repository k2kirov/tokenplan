#!/usr/bin/env bash
# Install tokenplan: symlink the CLI, install the agent skill, start the launchd agent.
set -euo pipefail

REPO="$(cd "$(dirname "$0")" && pwd)"
BIN_DIR="${BIN_DIR:-$HOME/.local/bin}"

# tomllib needs Python 3.11+.
PY="$(command -v python3 || true)"
if [ -z "$PY" ] || ! "$PY" -c 'import sys; sys.exit(sys.version_info < (3, 11))'; then
  echo "tokenplan needs python3 >= 3.11 on PATH (e.g. brew install python)" >&2
  exit 1
fi
[ "$(uname)" = "Darwin" ] || { echo "tokenplan currently supports macOS only" >&2; exit 1; }

mkdir -p "$BIN_DIR"
chmod +x "$REPO/tokenplan"
ln -sf "$REPO/tokenplan" "$BIN_DIR/tokenplan"
echo "linked $BIN_DIR/tokenplan -> $REPO/tokenplan"

# Install the skill for every agent home that exists.
for home in "$HOME/.claude" "$HOME/.codex"; do
  if [ -d "$home" ]; then
    mkdir -p "$home/skills/tokenplan"
    ln -sf "$REPO/skill/SKILL.md" "$home/skills/tokenplan/SKILL.md"
    echo "skill installed in $home/skills/tokenplan"
  fi
done

# Shebang uses env python3; pin the interpreter checked above for launchd.
"$PY" "$REPO/tokenplan" install
"$PY" "$REPO/tokenplan" config >/dev/null
echo
"$PY" "$REPO/tokenplan"
