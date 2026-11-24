#!/usr/bin/env bash
# Apply pi configuration from this repo into ~/.pi/agent.
# Copies mcp.json, AGENTS.md and the reviewer agent, and registers the subagent
# extension bundled with pi in settings.json so the reviewer can be spawned.
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

# The bundled extension lives under a version-pinned path, so resolve it from the
# installed version every time and replace any stale entry. Needs node for the JSON.
register_subagent_extension() {
  local version_file="$PI_DIR/install/current-version" version entry
  if ! command -v node >/dev/null 2>&1; then
    echo "!! node not found; add the subagent extension to \"extensions\" in $PI_DIR/settings.json by hand" >&2
    return
  fi
  if [ ! -f "$version_file" ]; then
    echo "!! $version_file not found; add the subagent extension to \"extensions\" in $PI_DIR/settings.json by hand" >&2
    return
  fi
  version="$(tr -d '[:space:]' < "$version_file")"
  entry="install/releases/$version/node_modules/@earendil-works/pi-coding-agent/examples/extensions/subagent/index.ts"
  if [ ! -f "$PI_DIR/$entry" ]; then
    echo "!! bundled subagent extension not found at $PI_DIR/$entry" >&2
    return
  fi
  node -e '
    const fs = require("fs");
    const [file, entry] = process.argv.slice(1);
    let settings = {};
    try { settings = JSON.parse(fs.readFileSync(file, "utf8")); } catch (err) { if (err.code !== "ENOENT") throw err; }
    const others = (Array.isArray(settings.extensions) ? settings.extensions : []).filter((e) => !e.includes("examples/extensions/subagent/"));
    settings.extensions = [...others, entry];
    fs.writeFileSync(file, JSON.stringify(settings, null, 2) + "\n");
  ' "$PI_DIR/settings.json" "$entry"
  echo "    registered subagent extension (pi $version) in settings.json"
}

echo "==> Applying pi config from $HERE -> $PI_DIR"
mkdir -p "$PI_DIR/agents"

copy_file "$HERE/mcp.json" "$PI_DIR/mcp.json"
copy_file "$HERE/AGENTS.md" "$PI_DIR/AGENTS.md"
for agent_file in "$HERE"/agents/*.md; do
  [ -e "$agent_file" ] || continue
  copy_file "$agent_file" "$PI_DIR/agents/$(basename "$agent_file")"
done
register_subagent_extension

echo
echo "==> Done. Installed:"
echo "    $PI_DIR/mcp.json         <- $HERE/mcp.json"
echo "    $PI_DIR/AGENTS.md        <- $HERE/AGENTS.md"
echo "    $PI_DIR/agents/*.md      <- $HERE/agents/*.md"
echo "    $PI_DIR/settings.json    \"extensions\" entry for the bundled subagent extension"
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
