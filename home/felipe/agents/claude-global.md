# Picking the right models for workflows and subagents

Rankings, higher = better. Cost reflects what I actually pay (OpenAI has really generous limits), not list price. Intelligence is how hard a problem you can hand the model unsupervised. Taste covers UI/UX, code quality, API design, and copy.

| model         | cost | intelligence | taste |
| ------------- | ---- | ------------ | ----- |
| gpt-5.6 terra | 9    | 8            | 6     |
| sonnet-5      | 5    | 5            | 7     |
| opus-5        | 5    | 8.5          | 8     |
| gpt-5.6 sol   | 3    | 8.5          | 8.5   |
| fable-5       | 2    | 9            | 9     |

How to apply:

- These are defaults, not limits. You have standing permission to override them: if a cheaper model's output doesn't meet the bar, rerun or redo the work with a smarter model without asking. Judge the output, not the price tag. Escalating costs less than shipping mediocre work.
- Cost is a tie-breaker only; when axes conflict for anything that ships, intelligence > taste > cost.
- Bulk/mechanical work (clear-spec implementation, data analysis, migrations): gpt-5.6 terra — it's effectively free. It sits below the taste bar, so keep it off anything user-facing.
- Anything user-facing (UI, copy, API design) needs taste >= 7. On the gpt side only gpt-5.6 sol clears that bar — it's the one expensive gpt, so spend it where taste and intelligence both matter, not on bulk.
- Reviews of plans/implementations: fable-5, gpt-5.6 sol, opus-5, optionally gpt-5.6 terra as a cheap extra independent perspective.
- Never use Haiku or gpt-5.6 luna.
- Claude models (sonnet-5, opus-5, fable-5) run via the Agent/Workflow `model` parameter.
- gpt models are only reachable through the Codex CLI: run `codex exec` with a self-contained prompt (`-s read-only` for investigation and data analysis).
- Always pass the model explicitly with `-m`: `gpt-5.6-terra` or `gpt-5.6-sol`. The CLI's default model is served from OpenAI rather than pinned in `~/.codex/config.toml`, so it can shift under you — never rely on it. To pin a default anyway, set `model = "<slug>"` at the top level of that config.

Using gpt models inside workflows and subagents (the `model` parameter only takes Claude models, so use a wrapper):

- Spawn a thin Claude wrapper agent with `model: 'sonnet', effort: 'low'` whose prompt instructs it to write a self-contained codex prompt, run `codex exec -m <slug>` via Bash, and return its output. Name the slug in the wrapper's prompt — it has no way to infer which gpt you meant.

# Presenting plans

When presenting a plan (plan mode or otherwise), invoke the
**`plan-html-workflow`** skill: write the plan as a self-contained HTML file in
the repo's `.plans/` directory and publish it with `bunx postplan upload`.
Don't only dump markdown into the chat. Reply with both the local path and the
hosted URL, plus a brief plain-text summary — never the URL alone.

The skill owns the details (CLI surface, storage convention, template,
component vocabulary). Two things worth knowing without opening it: the
installed `postplan` CLI has only `auth`/`whoami`/`upload`/`list` — no
`publish`/`init`/`new`, whatever same-named docs elsewhere claim — and drafts
are keyed by absolute file path, so re-uploading the same file updates one
stable URL. If publishing fails, fall back to markdown in the chat rather than
blocking on it.

# Worktree & branching discipline

Applies to every repo. Goal: a worktree exists only while an agent is actively
working in it, no two agents share a tree, and nothing non-trivial lands
without a PR. Chat sessions live in the main checkout; isolation is
agent-managed via EnterWorktree/ExitWorktree.

## Starting a task

- New task + dirty working tree: inspect first (`git status`, skim the diff),
  summarize what the dirt looks like (another agent's in-flight work / the
  user's manual edits / related to this task), then ask the user how to handle
  it: stash, commit as WIP, or build on top. Don't start work on a dirty tree
  without an answer.
- Follow-up prompts in the same session continue in place — no re-check.
- Then, for anything beyond a hotfix (see below), create an isolated worktree
  with EnterWorktree and work there.

## Worktree lifecycle

- Use EnterWorktree/ExitWorktree, not raw `git worktree` commands, for your
  own isolation — ExitWorktree restores the session's cwd before deleting, so
  the chat survives teardown.
- Tear down at PR-open: commit, push the branch, open the PR, verify the push
  landed, then `ExitWorktree(action: "remove", discard_changes: true)` — safe
  because everything is on the remote. A worktree must never outlive the
  active work in it.
- Later prompts about the same PR (review feedback, CodeRabbit rounds):
  `git worktree add .claude/worktrees/<name> <branch>`, then EnterWorktree
  with that path; apply, push, exit-remove again.
- Never remove the worktree your session was launched in (cwd is already a
  worktree and you never called EnterWorktree — e.g. t3code-*): deleting it
  bricks this chat. Leave it clean and pushed at PR-open; a later session's
  GC will reap it.

## Branch + PR

- All work happens on a branch and lands via PR. Base: `dev` if the repo has
  one, else `main`. Always pass the base explicitly
  (`gh pr create --base ...`) — repo default branches can't be trusted.
- Hotfix exception, may commit directly to the base branch in the main
  checkout, no worktree needed: single file, ≤ ~10 changed lines, no
  API/behavior-surface change, build and tests pass. When in doubt, it is not
  a hotfix — branch and PR it.

## Garbage collection (after planning, before starting work)

Run once per task, before touching code:

- `git worktree prune`, then look at every entry in `git worktree list`
  (harness-managed t3code-* trees included; never the main checkout or your
  own cwd). Removal is gated on staleness — deleting a session's home
  worktree bricks that chat, so give it a grace window:
  - staleness check (note: `find` here is bfs — it rejects fuzzy dates like
    `-newermt '3 days ago'`, use an ISO cutoff):
    `find <wt> -path '*/.git' -prune -o -type f -newermt "$(date -d '3 days ago' +%F)" -print -quit`
    — any output means the tree is fresh.
  - untouched > 3 days (latest file mtime): if dirty,
    `git stash push --include-untracked -m "gc: <branch> <date>"` from inside
    it first; then `git worktree remove` it. Report anything stashed and print
    the resurrect recipe (`git worktree add <path> <branch>`) in case that
    chat is ever needed again.
  - younger than 3 days: leave it — likely a live agent or a chat the user
    may still reply to. Mention it in one line.
- Delete local branches fully merged into the base branch.
- List any existing `gc:` stashes so they don't rot silently.

# Web previews over Tailscale

Felipe opens dev servers from another device on the tailnet
(`bass-pirarucu.ts.net`), so binding to `0.0.0.0` is necessary but rarely
sufficient: most modern dev servers validate the `Host` header and reject
tailnet hostnames until they are allowlisted.

- Vite / SvelteKit / Astro (Vite ≥ 6): `--host 0.0.0.0` plus
  `server: { allowedHosts: ['.bass-pirarucu.ts.net'] }` in `vite.config.ts`
  (the leading dot allows every machine on the tailnet).
- Next.js: `next dev -H 0.0.0.0` is enough — no dev-time host allowlist.
- Other stacks, same idea: webpack `devServer.allowedHosts`, Rails
  `config.hosts`, Django `ALLOWED_HOSTS` — allow `.bass-pirarucu.ts.net`.
- Prefer committing the allowlist to the repo (it only affects dev servers)
  over uncommitted local edits, which silently vanish in fresh clones and
  worktrees. If the repo can't take the commit, apply it locally and say so.
- Hand over the URL as `http://<this-host>.bass-pirarucu.ts.net:<port>`,
  never `localhost` — Felipe is on another device.
