# Delegation from Codex

The model table, roles and effort rules are in "Picking the right model"
further down. This section is only the plumbing.

## Native Codex subagents

- Use native Codex subagents only when the user or applicable repository
  instructions authorize delegation or parallel agent work.
- Prefer native subagents for work that can proceed independently and has a
  concrete, bounded deliverable.
- Pick each subagent's model and reasoning level from the model section.
  Do not invent slugs the current Codex runtime doesn't list.
- Give every subagent a self-contained objective, relevant paths, constraints,
  expected output, and whether it may edit files.
- The primary agent owns the final result: inspect changes and verify claims
  rather than forwarding a subagent's output uncritically.

## Running Claude models as external workers

Claude models are not native Codex subagents. When a Claude perspective is
useful and delegation is authorized, run the installed Claude Code CLI as an
external worker from the relevant repository directory.

For read-only investigation or review, prefer non-interactive plan mode:

```sh
claude -p --model fable --effort high --permission-mode plan \
  --tools "Read,Grep,Glob" "<self-contained prompt>"
```

Choose the model explicitly: `sonnet`, `opus`, or `fable`. Choose effort
explicitly too; the model section sets it (`fable` is always `high`). Use
`--output-format json` when reliable machine parsing materially helps.

Each Claude prompt must include:

- the objective and concrete deliverable;
- the repository path and relevant files or context;
- applicable constraints and acceptance criteria;
- whether the task is read-only or may make edits;
- an instruction to preserve unrelated changes and avoid destructive actions;
- a request to report evidence, uncertainties, and verification performed.

For implementation, grant editing capability only when the user or task has
already authorized the underlying change. Prefer isolation with Claude's
`--worktree <name>` option. Do not use `--dangerously-skip-permissions` or
`--allow-dangerously-skip-permissions`. Inspect the resulting diff and run
appropriate verification before accepting it.

Claude CLI calls may require external network/auth access. Use the normal
approval mechanism when the execution environment requires it; do not work
around sandbox or permission failures.
