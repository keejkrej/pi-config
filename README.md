# pi-config

Portable config for [pi](https://pi.dev), mirrored into `~/.pi/agent/`.

## Files

| File | Purpose | Copy to |
| --- | --- | --- |
| `mcp.json` | MCP servers (paper via local `paper mcp`; ambient over local HTTP; mobbin through `mcp-remote`, which owns the OAuth login; browse via local `browse mcp`) | `~/.pi/agent/mcp.json` |
| `AGENTS.md` | Ambient memory and primary-session orchestration instructions | `~/.pi/agent/AGENTS.md` |
| `agents/worker.md` | Implementation and command execution role | `~/.pi/agent/agents/worker.md` |
| `agents/scout.md` | Read-only file research role | `~/.pi/agent/agents/scout.md` |
| `agents/reviewer.md` | `reviewer` agent for the bundled `subagent` extension: an independent, read-only code reviewer with the same brief as the other agents' reviewers | `~/.pi/agent/agents/reviewer.md` |
| `codex-fast.settings.json` | Pinned `pi-codex-fast` package and saved Ultrafast mode | Merged into `~/.pi/agent/settings.json` by the installers |
| `pi-memory.settings.json` | Pinned `pi-memory` extension | Merged into `~/.pi/agent/settings.json` by the installers |
| `pi-goal.settings.json` | Pinned `@narumitw/pi-goal` extension | Merged into `~/.pi/agent/settings.json` by the installers |

The full `settings.json` stays machine-local. Never commit provider credentials (`auth.json`).

## New machine

Run `./install.sh` (Git Bash, macOS, Linux) or `./install.ps1` (PowerShell): they copy the files
into `~/.pi/agent/`, back up anything they replace as `*.bak.<timestamp>`, and register the
`subagent` extension and merge the package settings into `settings.json` (both installers
need Node.js 18 or newer for those steps). Pi installs the pinned packages at startup. Nothing is
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

## Codex speed

The installers set `@calesennett/pi-codex-fast` to request Ultrafast on supported models.
Use `/codex-ultrafast` in Pi to toggle it. The server decides which tier actually serves a request.

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

## Pi Memory

[`pi-memory`](https://github.com/jayzeng/pi-memory) stores local Markdown notes and a
scratchpad under `~/.pi/agent/memory/`. It is separate from Ambient, which remains
configured and is still the first place to look for project context. Ask Pi to run
`memory_status` after restarting or running `/reload`. The extension requires Node.js
22.19.0 or newer. The optional qmd dependency for searching local notes is not installed
by this repo.

By default, `pi-memory` can send session context to the configured model for an exit
summary and save that summary in its local daily log. To turn off exit summaries, set
`PI_MEMORY_EXIT_SUMMARY=0` in the environment before launching Pi.

## Pi Goal

Use `/goal <objective>` to start a session goal or `/goal` to manage it. Goal mode
can run additional paid model turns and use active tools. The installers leave
machine-local `pi-goal.json` settings alone.

## Orchestration and review

Pi has no built-in subagents. The installer points the `extensions` entry in `settings.json` at the
`subagent` extension that ships with pi (`examples/extensions/subagent/index.ts`), which adds a
`subagent` tool that runs an agent in a separate `pi` process with its own context. Agents live in
`~/.pi/agent/agents/*.md`; this repo installs `worker.md`, `scout.md`, and `reviewer.md`. The reviewer has the same brief as the other
agents' reviewers: read the diff, run the build or tests, report findings with file:line, never fix.
All three roles inherit the active session model and thinking level; there is no separate main
agent or model override. The primary session scopes and delegates work rather than implementing:
`subagent({ agent: "worker", task: "..." })` for implementation and commands,
`subagent({ agent: "scout", task: "..." })` for read-only file research, and
`subagent({ agent: "reviewer", task: "Review the diff against ..." })` before reporting
non-trivial changes done. Use `tasks: [{ agent, task }, ...]` for independent parallel work.
Separate contexts share the working directory, so concurrent workers need non-overlapping scopes.
Delegated roles work directly rather than recursively orchestrating. These are prompt rules and
per-role tool lists, not custom permission enforcement; reviewer retains bash for checks.

For prompt-only updates on an existing machine, copy `AGENTS.md` and `agents/*.md` to their
destinations above without running the full installer: it also replaces `mcp.json`, which may
have machine-specific paths. If the bundled subagent registration is missing, run
`node scripts/merge-settings.cjs "$HOME/.pi/agent"`; it preserves unrelated settings while
also merging this repo's pinned package settings. Restart Pi or run `/reload` after updating.
