#!/usr/bin/env bash
set -euo pipefail

# pi-config installer for macOS / Linux
# Automates the setup shown in IMG_1156 plus an Ollama cloud model provider.

PI_PACKAGE="@earendil-works/pi-coding-agent"
OLLAMA_HOST="${OLLAMA_HOST:-https://ollama.com}"
OLLAMA_MODEL="${OLLAMA_MODEL:-kimi-k2.7-code}"

OLLAMA_API_URL="${OLLAMA_HOST%/}"
OLLAMA_API_URL="${OLLAMA_API_URL%/v1}"

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
AGENT_DIR="${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}"
MODELS_FILE_SRC="$REPO_DIR/models.json"
SETTINGS_FILE_SRC="$REPO_DIR/.pi/settings.json"

die() {
  echo "[pi-config] Error: $1" >&2
  exit 1
}

log() {
  echo "[pi-config] $1"
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

require_node() {
  if ! command_exists node || ! command_exists npm; then
    die "Node.js and npm are required. Install them first: https://nodejs.org/"
  fi
  log "node $(node --version), npm $(npm --version)"
}

install_pi() {
  if command_exists pi; then
    log "pi already installed: $(pi --version 2>/dev/null || true)"
    log "updating pi..."
    pi update --self || npm install -g --ignore-scripts "$PI_PACKAGE"
  else
    log "installing pi..."
    npm install -g --ignore-scripts "$PI_PACKAGE"
  fi
}

ensure_agent_dir() {
  mkdir -p "$AGENT_DIR"
  log "Pi agent dir: $AGENT_DIR"
}

install_models_json() {
  local target="$AGENT_DIR/models.json"
  if [ -f "$MODELS_FILE_SRC" ]; then
    cp "$MODELS_FILE_SRC" "$target"
    log "installed $target"
  else
    die "models.json source not found at $MODELS_FILE_SRC"
  fi
}

install_project_settings() {
  local target="$AGENT_DIR/settings.json"
  mkdir -p "$AGENT_DIR"
  if [ -f "$SETTINGS_FILE_SRC" ]; then
    cp "$SETTINGS_FILE_SRC" "$target"
    log "installed settings: $target"
  else
    die "settings.json source not found at $SETTINGS_FILE_SRC"
  fi
}

ollama_cloud_reachable() {
  if [ -z "${OLLAMA_API_KEY:-}" ]; then
    return 1
  fi
  curl -fsS -H "Authorization: Bearer $OLLAMA_API_KEY" "$OLLAMA_API_URL/v1/models" >/dev/null 2>&1
}

ensure_ollama() {
  if [ -z "${OLLAMA_API_KEY:-}" ]; then
    die "OLLAMA_API_KEY is not set. Export it before running this script."
  fi

  log "checking Ollama cloud endpoint: $OLLAMA_HOST"
  if ollama_cloud_reachable; then
    log "Ollama cloud reachable with API key"
  else
    die "could not reach $OLLAMA_HOST/v1/models with OLLAMA_API_KEY"
  fi
}

install_packages() {
  log "installing pi packages..."
  pi update --all || true
  # If project settings were just written, pi should pick them up on next launch.
  # The following explicit installs are a safety net in case --all is slow/fails.
  for pkg in @plannotator/pi-extension @ff-labs/pi-fff pi-web-extension pi-cursor-sdk pi-thinking-steps pi-mcp-adapter @sampfp/pi-essentials; do
    pi install "$pkg" || log "warning: failed to install $pkg (may already be installed or unavailable)"
  done
}

print_next_steps() {
  log "setup complete"
  echo ""
  echo "Run 'pi' in this directory to start a session with the configured setup."
  echo "Default model: $OLLAMA_MODEL via Ollama cloud."
  echo ""
  echo "If you want a different default model, set OLLAMA_MODEL and re-run this script:"
  echo "  OLLAMA_MODEL=kimi-k3 sh install.sh"
}

main() {
  require_node
  install_pi
  ensure_agent_dir
  install_models_json
  install_project_settings
  ensure_ollama
  install_packages
  print_next_steps
}

main "$@"
