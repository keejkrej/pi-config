# pi-config

Portable config for [pi](https://pi.dev), mirrored into `~/.pi/agent/`.

## Files

| File | Purpose | Copy to |
| --- | --- | --- |
| `mcp.json` | MCP servers (paper via local `paper mcp`; ambient over local HTTP; mobbin, OAuth via `pi mcp login mobbin`) | `~/.pi/agent/mcp.json` |
| `AGENTS.md` | Global instructions loaded in every session: the Ambient memory block | `~/.pi/agent/AGENTS.md` (optionally also `~/.config/opencode/AGENTS.md`) |

Provider credentials (`auth.json`) and settings (`settings.json`) are machine-local and not
tracked; never commit `auth.json`.

## New machine

Copy the tracked files into `~/.pi/agent/`, then sign in to your providers in pi.

The `paper` server runs the `paper` CLI that Paper Desktop installs into `~/.paper/bin`;
add that directory to `PATH` (on Windows: `%USERPROFILE%\.paper\bin` in the user `Path`).
Sign in to Mobbin once with `pi mcp login mobbin` (Pro/Team/Enterprise plan required).
Check everything with `pi mcp list`.

## Ambient memory

The `ambient` server is the MCP endpoint inside the running [Ambient](https://alexandria.so)
desktop app (`http://127.0.0.1:8765/mcp`); its tools are unavailable when the app is closed.
The memory tools (`memory_search`, `memory_show`, `memory_save`, `activity_search`,
`activity_show`) are declared directly; the rest load through `tool_search`.

`AGENTS.md` holds the same "always check Ambient memory" block Ambient writes into
Claude Code's `CLAUDE.md` and Codex's `AGENTS.md`. Ambient manages neither pi nor
opencode, so copy it into both global instruction files yourself:

- pi: `~/.pi/agent/AGENTS.md`
- opencode (optional): `~/.config/opencode/AGENTS.md`

The block is not refreshed when the app's wording changes: copy it again from
`ambient-app/electron/agent-global-instructions.ts` when needed.
