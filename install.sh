#!/usr/bin/env bash
# model-router installer — installs the skill for Claude Code and GitHub Copilot,
# and creates the config file for your OpenRouter API key.
set -euo pipefail

REPO_RAW="https://raw.githubusercontent.com/ferduque/model-router/main"

# When run from a cloned/downloaded repo, use local files; otherwise fetch from GitHub.
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || true)"

fetch() { # fetch <filename> <dest>
  if [ -n "$SRC_DIR" ] && [ -f "$SRC_DIR/$1" ]; then
    cp "$SRC_DIR/$1" "$2"
  else
    curl -fsSL "$REPO_RAW/$1" -o "$2"
  fi
}

install_into() { # install_into <skills-parent-dir> <label>
  local dir="$1/model-router"
  mkdir -p "$dir"
  fetch "SKILL.md" "$dir/SKILL.md"
  echo "✓ Installed skill for $2 -> $dir"
}

# 1) Claude Code (always) + Copilot (if present, or create anyway — harmless)
install_into "$HOME/.claude/skills" "Claude Code"
install_into "$HOME/.copilot/skills" "GitHub Copilot"

# 2) Config file with key placeholder (never overwrite an existing key)
CONF_DIR="$HOME/.model-router"
mkdir -p "$CONF_DIR"
if [ ! -f "$CONF_DIR/env" ]; then
  fetch "env.example" "$CONF_DIR/env"
  chmod 600 "$CONF_DIR/env"
  echo "✓ Created $CONF_DIR/env"
else
  echo "• Kept existing $CONF_DIR/env (your key is safe)"
fi

# 3) Check worker runtime
if command -v claude >/dev/null 2>&1; then
  echo "✓ Claude Code CLI found ($(claude --version 2>/dev/null | head -1))"
else
  echo "⚠ Claude Code CLI not found — it is the worker runtime."
  echo "  Install it from https://claude.com/claude-code"
fi

echo ""
echo "Almost done — one manual step:"
echo "  1. Open  $CONF_DIR/env  and paste your OpenRouter API key"
echo "     (get one at https://openrouter.ai -> Keys, add a few dollars of credits)"
echo "  2. Restart Claude Code / Copilot"
echo "  3. Try: \"Use model-router: have glm build ...\""
