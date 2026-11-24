# Cognition-style memory repos for Pi

Two published Pi extensions explicitly implement the Markdown/Git format from Cognition’s [Agent Memory Repo spec](https://github.com/AgentMemoryRepo/agentmemoryrepo). The [Cognition overview](https://cognition.com/agent-memory-repo) also describes a broader workflow: pull or clone shared memory, push edits, and periodically consolidate notes with a separate Dreaming agent. Don’t assume that format compatibility includes that workflow.

| Package | What it offers |
| --- | --- |
| [`pi-agent-memory-repo` 1.2.0](https://www.npmjs.com/package/pi-agent-memory-repo/v/1.2.0) ([source](https://github.com/chensirui2008/pi-agent-memory-repo)) | Global and project repos, `MEMORY.md` injection, wikilinks, read/recall/write/list tools, Git commits, interactive `/remember`, and on-demand `/dreaming`. The published manifest uses `@mariozechner/pi-tui`, which Pi 1.6.0 aliases to the current package. |
| [`@kivlor/pi-memory` 0.1.2](https://www.npmjs.com/package/@kivlor/pi-memory/v/0.1.2) | One configurable local repo, session-start `MEMORY.md` injection, wikilinks, init/search/read/save tools, provenance, and Git commits. Its published manifest targets `@earendil-works/pi-*`. No Dreaming command is documented. |

Both published Git helpers stage with `git add -A`. For a trial, put memory in a **dedicated directory outside any existing Git worktree**. Set `PI_MEMORY_DIR` for `@kivlor/pi-memory`, or both `AGENT_MEMORY_GLOBAL_DIR` and `AGENT_MEMORY_PROJECT_DIR` for `pi-agent-memory-repo`; isolating Pi config alone does not redirect these paths. Neither extension's published README documents automatic remote synchronization or a scheduled Dreaming agent. The [upstream skill](https://github.com/AgentMemoryRepo/agentmemoryrepo#try-with-your-agent) is another option for a manual trial; it does not include automatic startup or scheduled Dreaming.

Both extensions automate loading, but their documented write paths require model-facing tools or slash commands. Neither is an exact match for an automatic Pi extension that exposes no tools and does not use MCP. For that requirement, prefer Pi lifecycle hooks for recall and capture, with local Git commits and no remote push by default. Smoke-test that a synthetic durable fact is saved in one session and recalled in another without either session invoking a memory tool or command.

Evidence: upstream spec, npm README and manifest for each version, and published tarballs (`dist/src/index.js`, `dist/src/core/git.js`, and `dist/src/commands/remember.js` for the first package; `src/index.ts` and `src/git.ts` for the second). Neither extension was installed or executed.
