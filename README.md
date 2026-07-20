# Pi coding agent setup

This repository automates the Pi coding-agent configuration shown in the screenshot (IMG_1156):

- `@plannotator/pi-extension`
- `@ff-labs/pi-fff`
- `pi-web-extension`
- `pi-cursor-sdk`
- `pi-thinking-steps`
- `pi-mcp-adapter`
- `@sampfp/pi-essentials`

It also wires up an Ollama local provider so `pi` can launch against Ollama models.

## Quick start

### Windows

```powershell
.\install.ps1
```

### macOS / Linux

```bash
sh install.sh
```

## What the installer does

1. Checks for Node.js and npm (required by Pi).
2. Installs or updates the Pi coding-agent CLI globally.
3. Makes sure the Pi agent directory exists (`~/.pi/agent/` on Unix, `%USERPROFILE%\.pi\agent\` on Windows).
4. Copies `models.json` to the Pi agent directory, adding an `ollama` provider pointing at `http://localhost:11434/v1`.
5. Copies `.pi/settings.json` into the current project (this repo) so project-local settings and packages are loaded when you run `pi` here.
6. Optionally starts Ollama and pulls a default model (`kimi-k2.7-code:cloud` by default).
7. Runs `pi update --all` to install the configured packages.

## Running Pi

After setup:

```bash
pi
```

Pi will load the Ollama provider and the configured extensions automatically for this project.

## Files

| File | Purpose |
|------|---------|
| `install.ps1` | Windows installer |
| `install.sh` | macOS/Linux installer |
| `.pi/settings.json` | Project-local Pi settings and packages |
| `models.json` | Source template for the global Ollama provider |
| `package.json` | Convenience npm scripts to run the installers |

## Customizing

- Edit `.pi/settings.json` to change the default model, thinking level, or package list.
- Edit `models.json` (and re-run the installer, or copy it to `~/.pi/agent/models.json`) to add/remove Ollama models.
- Set the environment variable `OLLAMA_MODEL` before running the installer to change the default pulled model, e.g. `OLLAMA_MODEL=llama3.1:8b sh install.sh` or `$env:OLLAMA_MODEL='llama3.1:8b'; .\install.ps1` on Windows.
