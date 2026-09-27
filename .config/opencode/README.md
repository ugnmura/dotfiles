# OpenCode

These files mirror the active OpenCode config from `~/.config/opencode` on the
source machine:

- `AGENTS.md` — agent/model routing instructions, synced verbatim.
- `opencode.json` — main OpenCode config (agents, provider, MCP servers).
- `opencode.jsonc` — Superpowers plugin config; keep alongside
  `opencode.json` to mirror the active configuration layout.

## Adjusting on another machine

The `mcp` servers in `opencode.json` contain absolute macOS paths
(`lsp`, `codegraph`, `cua_repl`, `node_repl`) and environment variables
pointing at this machine's installs. On another machine, update or remove
those paths before enabling the corresponding servers. Remote MCP server
URLs are machine-independent.

## Not tracked

Service/runtime state and dependency artifacts are intentionally not tracked
(see `.gitignore` in this directory): `service.json`, `node_modules/`,
`package.json`, `package-lock.json`, `bun.lock`, `bun.lockb`, `backup*/`,
`*.before-*`, and `lsp-install-decisions.json`. No credentials are stored in
the tracked files; MCP servers either use public URLs without embedded
tokens or rely on environment/runtime configuration elsewhere.
