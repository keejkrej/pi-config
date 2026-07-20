#!/usr/bin/env bash
set -euo pipefail

# pi-config installer for macOS / Linux
# Automates the setup shown in IMG_1156 plus an Ollama local model provider.

PI_PACKAGE="@earendil-works/pi-coding-agent"
OLLAMA_HOST="${OLLAMA_HOST:-https://ollama.com}"
OLLAMA_MODEL="${OLLAMA_MODEL:-kimi-k2.7-code}"
OLLAMA_URL="${OLLAMA_HOST#http://}"
OLLAMA_URL="${OLLAMA_URL#https://}"
OLLAMA_PORT="${OLLAMA_URL##*:}"
OLLAMA_PORT="${OLLAMA_PORT:-11434}"

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
  local target="$REPO_DIR/.pi/settings.json"
  mkdir -p "$REPO_DIR/.pi"
  if [ -f "$SETTINGS_FILE_SRC" ]; then
    cp "$SETTINGS_FILE_SRC" "$target"
    log "installed project settings: $target"
  else
    die "settings.json source not found at $SETTINGS_FILE_SRC"
  fi
}

ollama_running() {
  curl -fsS "$OLLAMA_HOST/" >/dev/null 2>&1
}

ensure_ollama() {
  if ! command_exists ollama; then
    log "Ollama not found. Installing Ollama..."
    curl -fsSL https://ollama.com/install.sh | sh
  fi

  if ! ollama_running; then
    log "starting Ollama..."
    if [ "$(uname -s)" = "Darwin" ]; then
      open -a Ollama || true
    else
      nohup ollama serve >/tmp/ollama.log 2>&1 &
    fi
    local attempts=0
    while ! ollama_running && [ $attempts -lt 30 ]; do
      sleep 1
      attempts=$((attempts + 1))
    done
    if ! ollama_running; then
      die "Ollama did not start on $OLLAMA_HOST within 30s"
    fi
    log "Ollama is running"
  else
    log "Ollama already running"
  fi

  log "pulling Ollama model: $OLLAMA_MODEL"
  ollama pull "$OLLAMA_MODEL" || die "failed to pull $OLLAMA_MODEL"
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
  echo "Default model: $OLLAMA_MODEL via Ollama."
  echo ""
  echo "If you want a different default model, set OLLAMA_MODEL and re-run this script:"
  echo "  OLLAMA_MODEL=llama3.1:8b sh install.sh"
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
