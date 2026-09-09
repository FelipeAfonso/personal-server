# Check required skills and tools

- Before implementation, check the skills and tools required by the task and
  repository instructions. A missing entry in the session's tool or skill
  list does not prove that the tool or skill is missing from the machine.
- Read unslop at `~/.agents/skills/unslop/SKILL.md`. If that path is missing,
  check `~/.claude/skills/unslop/SKILL.md`. On NixOS these files may be
  symlinks into `/nix/store`; read them directly. When searching skill
  directories, use `rg --files --hidden --follow`. Only use the fallback
  writing rules after checking the actual paths. Follow the client's skill
  invocation requirements when a Skill tool is available.
- For a required MCP server, check the active tools and the current client's
  configuration. In Codex, run `codex mcp list` and inspect the applicable
  `~/.codex/config.toml` or `.codex/config.toml`. A repository `.mcp.json`
  or `.cursor/mcp.json` entry alone does not configure Codex.
- If the repository declares a required MCP server and the current client
  has no equivalent entry, configure it using the existing declaration.
  Preserve unrelated settings and do not install missing dependencies
  against repository rules. Verify the server with an actual tool call;
  a configuration listing alone is not a connectivity check.
- A running session may not expose newly configured MCP tools. If an
  existing local MCP client can call the server, use it to complete the
  required checks. Otherwise report the exact limitation and checks
  attempted. Do not silently replace a required MCP check with a different
  validator or claim the server is unavailable based only on the tool list.

# Deliver repository changes through a pull request

- A request to implement or fix something in a repository includes creating
  a branch, committing the task's changes, pushing it, and opening a PR.
  Do not stop at local edits or wait for a separate request for the PR.
- Read-only questions and investigations do not require a PR. An explicit
  request for local-only work or a repository-specific delivery rule takes
  precedence. Preserve unrelated user and agent changes.
- Use `dev` as the base when the repository has it, otherwise its default
  branch, unless repository instructions or the user specify another base.
  Check the remote branches and recent PRs, and pass the base explicitly.
- Use a task branch before editing. Continue on the existing task branch
  for follow-up work. A separate worktree is only needed when the applicable
  isolation rules or concurrent work require one.
- Run the checks allowed by the repository, inspect the final diff, and
  verify that the pushed commit matches the local commit before opening
  the PR. Never claim checks passed unless their results confirm it.
- Finish with the PR URL, what changed, and validation status. Distinguish
  local checks from pending or failed CI. If a real blocker prevents a PR,
  state it and what remains instead of calling the task complete.
- Creating a PR does not authorize merging or deploying. Follow explicit
  repository rules for those actions and never force-push without approval.
- Existing hotfix exception: a single-file change of at most about ten
  lines, with no API or behavior change and passing required checks, may
  go directly to the base branch. When in doubt, use a PR.
