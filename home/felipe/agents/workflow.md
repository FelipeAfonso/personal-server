# Writing

Run the unslop skill before sending prose to a human, including chat replies,
commit messages, PR descriptions, documentation, comments, and product copy.
Read its pattern list, rewrite, then self-audit. When the client has a Skill
tool, invoke `unslop` during the turn. Otherwise read the skill file directly.
Check the paths below before treating the skill as missing.

If it is missing, apply these rules from memory: no em dashes, no "not just X
but Y", no padded groups of three, no repetitive inline-header lists, and no
chatbot sign-offs. Use sentence-case headings and plain words.

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

# Presenting plans

- Present plans directly and concisely in chat by default.
- Use a planning or visualization skill when the user requests it or a
  separate artifact would materially help. The presence of an installed
  HTML planning skill does not require an artifact for every plan.
- Publish an artifact when the user requests a hosted link or an applicable
  repository workflow includes publishing. If publishing fails, deliver the
  plan in chat and link the local artifact.

# Working-tree safety

- Before editing, inspect relevant repository instructions and the working
  tree when existing changes could overlap the task.
- Treat all pre-existing changes as user or other-agent work. Preserve them
  and avoid overwriting, reverting, stashing, committing, or moving them.
- A dirty tree is not automatically a blocker. Continue when changes are
  unrelated and the requested work can be performed safely.
- Ask the user only when overlapping changes create a real ambiguity or when
  proceeding requires altering someone else's work.
- Never perform automatic worktree garbage collection. Do not remove another
  session's worktree, delete branches, or create cleanup stashes unless the
  user explicitly requests that cleanup and the targets have been verified.

# Branches and worktrees

- Use the current checkout by default unless the user requests isolation or
  concurrent work needs a separate worktree.
- Use supported client tools or conservative `git worktree` commands when
  creating worktrees. Never remove the worktree containing an active session.
- Opening a PR does not require deleting its worktree. Keep it available for
  follow-up work; clean up only when the user requests it.
- Never rewrite, discard, or force-push history without explicit authorization.

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

# Web previews over Tailscale

Felipe opens dev servers from another device on the tailnet
(`bass-pirarucu.ts.net`), so binding to `0.0.0.0` is necessary but rarely
sufficient: most modern dev servers validate the `Host` header and reject
tailnet hostnames until they are allowlisted.

- Vite / SvelteKit / Astro (Vite ≥ 6): `--host 0.0.0.0` plus
  `server: { allowedHosts: ['.bass-pirarucu.ts.net'] }` in `vite.config.ts`
  (the leading dot allows every machine on the tailnet).
- Next.js: `next dev -H 0.0.0.0` is enough. No dev-time host allowlist.
- Other stacks, same idea: webpack `devServer.allowedHosts`, Rails
  `config.hosts`, Django `ALLOWED_HOSTS`. Allow `.bass-pirarucu.ts.net`.
- Prefer committing the allowlist to the repo (it only affects dev servers)
  over uncommitted local edits, which silently vanish in fresh clones and
  worktrees. If the repo can't take the commit, apply it locally and say so.
- Hand over the URL as `http://<this-host>.bass-pirarucu.ts.net:<port>`,
  never `localhost`. Felipe is on another device.
