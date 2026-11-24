# pi-config

Portable config for [pi](https://pi.dev), mirrored into `~/.pi/agent/`.

## Files

| File | Purpose | Copy to |
| --- | --- | --- |
| `mcp.json` | MCP servers (paper via local `paper mcp`; ambient over local HTTP; mobbin through `mcp-remote`, which owns the OAuth login; browse via local `browse mcp`) | `~/.pi/agent/mcp.json` |
| `AGENTS.md` | Global instructions loaded in every session: the Ambient memory block plus a short "review before done" rule | `~/.pi/agent/AGENTS.md` |
| `agents/reviewer.md` | `reviewer` agent for the bundled `subagent` extension: an independent, read-only code reviewer with the same brief as the other agents' reviewers | `~/.pi/agent/agents/reviewer.md` |

Provider credentials (`auth.json`) and settings (`settings.json`) are machine-local and not
tracked; never commit `auth.json`.

## New machine

Run `./install.sh` (Git Bash, macOS, Linux) or `./install.ps1` (PowerShell): they copy the files
into `~/.pi/agent/`, back up anything they replace as `*.bak.<timestamp>`, and register the
`subagent` extension in `settings.json` (the `.sh` variant needs Node.js for that step). Nothing is
linked, so re-run the installer after editing, and after every pi upgrade, since the extension path
is pinned to the installed version. Then sign in to your providers in pi.

The `paper` server runs the `paper` CLI that Paper Desktop installs into `~/.paper/bin`;
add that directory to `PATH` (on Windows: `%USERPROFILE%\.paper\bin` in the user `Path`).
The `browse` server runs the `browse` CLI from `~/.local/bin`; keep that directory on `PATH`
(on Windows: `%USERPROFILE%\.local\bin`) and install the browse extension in your Chrome-family browser.
`mobbin` runs through [`mcp-remote`](https://github.com/geelen/mcp-remote). The first time pi starts
it, a browser opens for the Mobbin login (Pro/Team/Enterprise plan required). The token is stored
once in `~/.mcp-auth` and shared by every agent that starts the same `mcp-remote` command, so there
is no `pi mcp login`. On Windows, `npx` must resolve to a real executable (mise shims do this);
npm's own `npx.cmd` cannot be spawned without a shell, and the documented workaround is
`cmd /c npx -y mcp-remote …`.
Check everything with `pi mcp list`.

## Ambient memory

The `ambient` server is the MCP endpoint inside the running [Ambient](https://alexandria.so)
desktop app (`http://127.0.0.1:8765/mcp`); its tools are unavailable when the app is closed.
The memory tools (`memory_search`, `memory_show`, `memory_save`, `activity_search`,
`activity_show`) are declared directly; the rest load through `tool_search`.

`AGENTS.md` holds the same "always check Ambient memory" block Ambient writes into
Claude Code's `CLAUDE.md` and Codex's `AGENTS.md`. Ambient does not manage pi,
so copy it into `~/.pi/agent/AGENTS.md` yourself.

The block is not refreshed when the app's wording changes: copy it again from
`ambient-app/electron/agent-global-instructions.ts` when needed.

## Reviewer

Pi has no built-in subagents. The installer points the `extensions` entry in `settings.json` at the
`subagent` extension that ships with pi (`examples/extensions/subagent/index.ts`), which adds a
`subagent` tool that runs an agent in a separate `pi` process with its own context. Agents live in
`~/.pi/agent/agents/*.md`; this repo installs `reviewer.md` there with the same brief as the other
agents' reviewers: read the diff, run the build or tests, report findings with file:line, never fix.
It inherits the session model. `AGENTS.md` asks pi to run it on the diff before reporting any
non-trivial change done.
