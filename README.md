# pi-config

Portable config for [pi](https://pi.dev), mirrored into `~/.pi/agent/`.

## Files

| File | Purpose | Secrets? |
| --- | --- | --- |
| `settings.json` | Defaults, installed extension packages, changelog versions | no |
| `mcp.json` | MCP servers (composio, paper via `mcp-remote`; ambient over local HTTP) | no |
| `AGENTS.md` | User instructions loaded in every session: the Ambient memory block | no |
| `auth.json` | Provider credentials — **template only**, key is empty | no (keep it empty) |

## New machine

Copy the tracked files into `~/.pi/agent/`, then paste the Ollama Cloud API key into
`auth.json`:

```json
{
  "ollama-cloud": {
    "type": "api_key",
    "key": "<your key>"
  }
}
```

Then launch pi — the `pi-ollama-cloud` extension refreshes the catalog on first run.

## Ambient memory

The `ambient` server is the MCP endpoint inside the running [Ambient](https://alexandria.so)
desktop app (`http://127.0.0.1:8765/mcp`); its tools are unavailable when the app is closed.
The memory tools (`memory_search`, `memory_show`, `memory_save`, `activity_search`,
`activity_show`) are declared directly; the rest load through `tool_search`.

`AGENTS.md` holds the same "always check Ambient memory" block Ambient writes into
Claude Code's `CLAUDE.md` and Codex's `AGENTS.md`. Ambient does not manage pi, so the
block is not refreshed when the app's wording changes: copy it again from
`ambient-app/electron/agent-global-instructions.ts` when needed.

## Model catalog

`pi-ollama-cloud` manages the catalog; there is no hand-maintained `models.json`.

- Live catalog: `~/.pi/agent/models-store.json` (generated, never commit)
- Refreshed from `ollama.com/v1/models` + `/api/show`, cached for 4h
- First-launch fallback: the extension's baked-in model list

## Caveat: the empty key blocks the env var

An `auth.json` entry with `"key": ""` counts as a *present* credential, and pi checks
stored credentials before interpolating `apiKey: "$OLLAMA_API_KEY"`. So the empty
template shadows `OLLAMA_API_KEY` and leaves the provider unconfigured (baked-in model
list, web tools disabled).

Either fill in the key, or delete the `ollama-cloud` entry entirely if you prefer to
supply the key via the environment.
