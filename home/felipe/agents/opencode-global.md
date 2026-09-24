# Delegation from opencode

The model table, roles and effort rules are in "Picking the right model"
further down. This section is only the plumbing.

Unless `opencode models` lists `anthropic/` or `openai/` providers on this
machine (on the fleet it usually only has `opencode-go`), opencode's native
subagents (`@general`, `@explore`, agents in `opencode.json`) can't reach the
models in the table. Use them only for tasks where the model doesn't matter.
For anything the table cares about, shell out to the other two CLIs from the
relevant repository directory with a self-contained prompt. Both are
installed and authenticated.

Claude Code, read-only review or investigation:

```sh
claude -p --model fable --effort high --permission-mode plan \
  --tools "Read,Grep,Glob" "<self-contained prompt>"
```

Choose the model explicitly (`sonnet`, `opus`, or `fable`) and the effort
explicitly. Use `--output-format json` when you need to parse the result. For
edits, prefer `--worktree <name>` and never pass
`--dangerously-skip-permissions`.

Codex, read-only:

```sh
codex exec -m gpt-6-astra -c model_reasoning_effort="high" -s read-only \
  "<self-contained prompt>"
```

Always pass `-m` and the effort override; the CLI default is served remotely
and can change under you.

Each external prompt must include:

- the objective and concrete deliverable;
- the repository path and relevant files or context;
- applicable constraints and acceptance criteria;
- whether the task is read-only or may make edits;
- an instruction to preserve unrelated changes and avoid destructive actions;
- a request to report evidence, uncertainties, and verification performed.

Inspect the resulting diff and run appropriate verification before accepting
any external worker's output.
