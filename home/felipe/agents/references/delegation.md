# Delegating work

Read this before starting a worker. Follow the active client's restrictions
on delegation and use only models it actually exposes. The routing table in
the global instructions expresses preferences, not a guarantee of availability.
If the preferred model is unavailable, try its listed fallback. If neither is
available, report the limitation rather than inventing a slug or silently
substituting a model outside the catalog.

Delegate independent work with a bounded deliverable. Give the worker the
objective, relevant paths, constraints, whether it may edit, and the expected
output. Require it to preserve unrelated work and report evidence,
uncertainties, and verification. Inspect its output before accepting it.
Workers cannot expand the original task's authorization.

Use separate worktrees for concurrent writers. Read-only workers can share a
checkout. Don't create thin wrapper agents when a direct CLI call suffices.
Set model and effort explicitly. Astra and Fable use high; other models use
medium for bulk work and high for review or user-facing work. Sonnet wrappers
use low. Choose quality over speed; escalate poor results without asking again.

## From Codex

Use native subagents when available and permitted. Claude models require the
Claude CLI. For read-only work:

```sh
claude -p --model fable --effort high --permission-mode plan \
  --tools "Read,Grep,Glob" "<self-contained prompt>"
```

Use `--output-format json` when the result needs parsing. For editing, use the
normal permissions and prefer `--worktree <name>` for isolation. Never pass
`--dangerously-skip-permissions` or `--allow-dangerously-skip-permissions`.

## From Claude

Use the client's supported Claude model and effort parameters. For GPT work,
call Codex directly through Bash:

```sh
codex exec -m gpt-6-astra -c model_reasoning_effort="high" -s read-only \
  "<self-contained prompt>"
```

For authorized editing, choose the appropriate writable sandbox and isolated
checkout. Never work around a permission failure.

## From OpenCode

Check `opencode models` before selecting a provider. Native workers may not
expose the preferred models. Use the Claude or Codex CLI when needed, following
the commands and permission boundaries above.

## Catalog identifiers

Claude CLI aliases: `fable`, `opus`, `sonnet`. The current preferences name
Fable 5.1, Opus 5, and Sonnet 5; verify the installed client's available models
when selecting a worker.

Codex identifiers: `gpt-6-astra`, `gpt-5.6-sol`, `gpt-5.6-terra`,
`gpt-5.6-luna`. Do not assume a listed identifier is exposed by every client.
