# Required tools and skills

Read this when a task-required tool or skill is missing or fails. Investigate
the specific dependency; do not audit every configured integration.

Check the session's tools, installed configuration, and declared repository
dependencies. A missing menu entry does not prove that the tool is absent.
For skills, read known paths directly and follow symlinks when searching:
`rg --files --hidden --follow`.

For Codex MCP configuration, inspect `codex mcp list`, `~/.codex/config.toml`,
and any repository `.codex/config.toml`. A `.mcp.json` or `.cursor/mcp.json`
entry alone does not configure Codex. For other clients, inspect their actual
configuration rather than assuming it matches another client's.

A task that requires an existing integration includes repairing its local
configuration from the repository's declaration. Preserve unrelated settings.
Do not install prohibited dependencies, create accounts, or change shared
services merely to satisfy a local preflight.

Verify connectivity with an actual tool call. A listing only verifies
configuration. A running session may not expose newly configured tools;
use an existing local MCP client when it can perform the required check.

Use an available equivalent when the requirement is the outcome. If the
repository explicitly requires a named validator or integration, complete
that check or report it as blocked. Never claim a substitute satisfied it.
After checking configuration and attempting a targeted repair, report any
remaining dependency on credentials, user access, or a new session. Continue
independent work instead of repeatedly retrying the same failure.
