#!/usr/bin/env bash
# Apply pi configuration from this repo into ~/.pi/agent.
# Copies mcp.json, AGENTS.md and the reviewer agent, and registers the subagent
# extension bundled with pi and the pinned package settings in settings.json.
set -euo pipefail

PI_DIR="${PI_DIR:-$HOME/.pi/agent}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

copy_file() {
  local src="$1" dest="$2"
  mkdir -p "$(dirname "$dest")"

  if [ ! -f "$src" ]; then
    echo "!! source missing: $src" >&2
    exit 1
  fi
  if [ -f "$dest" ] && cmp -s "$src" "$dest"; then
    echo "    unchanged $(basename "$dest")"
    return
  fi
  if [ -e "$dest" ]; then
    mv "$dest" "$dest.bak.$(date +%s)"
    echo "    backed up existing $(basename "$dest")"
  fi
  cp "$src" "$dest"
  echo "    copied $(basename "$dest")"
}

if ! command -v node >/dev/null 2>&1; then
  echo "!! Node.js is required to merge Pi settings" >&2
  exit 1
fi

echo "==> Applying pi config from $HERE -> $PI_DIR"
mkdir -p "$PI_DIR/agents"

copy_file "$HERE/mcp.json" "$PI_DIR/mcp.json"
copy_file "$HERE/AGENTS.md" "$PI_DIR/AGENTS.md"
for agent_file in "$HERE"/agents/*.md; do
  [ -e "$agent_file" ] || continue
  copy_file "$agent_file" "$PI_DIR/agents/$(basename "$agent_file")"
done
node "$HERE/scripts/merge-settings.cjs" "$PI_DIR"

echo
echo "==> Done. Installed:"
echo "    $PI_DIR/mcp.json         <- $HERE/mcp.json"
echo "    $PI_DIR/AGENTS.md        <- $HERE/AGENTS.md"
echo "    $PI_DIR/agents/*.md      <- $HERE/agents/*.md"
echo "    $PI_DIR/settings.json    bundled subagent extension and pinned package settings"
echo
echo "==> Notes:"
echo "    Sign in to your providers in pi."
echo "    mobbin runs through mcp-remote: the first time pi starts it, a browser opens"
echo "    for the Mobbin login; the token is then shared by every agent via ~/.mcp-auth."
echo "    The extension path is pinned to the installed pi version: re-run after a pi upgrade."
echo "    Nothing is linked: re-run this script after editing files here."
echo
echo "==> Verify with:"
echo "    pi mcp list"
