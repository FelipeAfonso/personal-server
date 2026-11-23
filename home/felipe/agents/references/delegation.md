# Delegating work

Read this before starting a worker. Follow the active client's restrictions
on delegation and use only models it actually exposes. The routing table in
the global instructions expresses preferences, not a guarantee of availability.
If the bucket's model is unavailable, report the limitation rather than
inventing a slug or silently substituting a model outside the catalog.

Delegate independent work with a bounded deliverable. Give the worker the
objective, relevant paths, constraints, whether it may edit, and the expected
output. Require it to preserve unrelated work and report evidence,
uncertainties, and verification. Inspect its output before accepting it.
Workers cannot expand the original task's authorization.

Use separate worktrees for concurrent writers. Read-only workers can share a
checkout. Don't create thin wrapper agents when a direct CLI call suffices.
Select a bucket and set its model and effort explicitly. Use the current
bucket table in the global instructions; do not infer effort from the model's
name or apply a blanket setting. Fable uses high. Neon uses high for
Implementation and medium for Routine. Neon wrappers may use low.

Neon workers only implement settled instructions. Give them acceptance
criteria and return unresolved decisions to Reasoning. Use Reasoning for
substantive technical review and Product for user-facing review; both are
Fable, in a session that did not write the change.

Check recent usage when it could affect model selection:
`~/.agents/skills/pr-review/scripts/agent-usage` prints the weekly allowance
used on both subscriptions. Read `~/.agents/references/models.md` for shared
pools, stale readings, and exhaustion. Choose at task boundaries; keep a
healthy worker on its task. Never switch to paid overages automatically.

## From Claude

Use the client's supported Claude model and effort parameters for Fable. In
T3 Code, start Neon with `delegate_task` on the Antigravity provider. Anywhere
else, call the Antigravity CLI through Bash. Put `-p` last, because it takes
the next argument as the prompt:

```sh
agy --model <newest neon id for the effort> --output-format json \
  --settings '{"useG1Credits":false,"permissions":{"deny":["write_file(*)","command(*)","read_url(*)","execute_url(*)","mcp(*)"]}}' \
  -p "<self-contained prompt>" </dev/null
```

That form reads files only. A headless run cannot answer permission prompts: an
action that needs approval is denied and can end the run with no answer. So
state the access in `--settings`. For editing, use `--mode accept-edits` in an
isolated checkout and allow the commands the task needs, for example
`{"useG1Credits":false,"permissions":{"allow":["command(git)","command(npm test)"]}}`.
Always keep `"useG1Credits": false`, so a spent allowance stops the run
instead of spending paid credits. Never pass `--dangerously-skip-permissions`, and
never work around a permission failure.

## From Antigravity or OpenCode

Use native subagents when available and permitted. Check `opencode models`
before selecting a provider there; native workers may not expose the catalog
models. Fable requires the Claude CLI. For read-only work:

```sh
claude -p --model fable --effort high --permission-mode plan \
  --tools "Read,Grep,Glob" "<self-contained prompt>"
```

Use `--output-format json` when the result needs parsing. For editing, use the
normal permissions and prefer `--worktree <name>` for isolation. Never pass
`--dangerously-skip-permissions` or `--allow-dangerously-skip-permissions`.

## Catalog identifiers

The catalog names two model classes: Fable and Neon. Always resolve a class
to its newest generally available version; do not pin an older version unless
Felipe asks for one.

The Claude CLI alias `fable` already resolves to the newest Fable, so pass the
alias rather than a full model name.

Antigravity ids follow `gemini-<version>-neon-<effort>`, for example
`gemini-4-neon-high`. List them with `agy models` and pick the highest version
at the bucket's effort. T3 Code lists the same model as `gemini-4-neon` with a
separate `thought_level` option. If `agy models` asks for a sign-in, report
that; only Felipe can sign in. Do not assume a listed identifier is exposed
by every client. If a required effort level is unavailable, report that
limitation rather than silently lowering it.
