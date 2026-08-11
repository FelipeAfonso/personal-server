# Model and delegation preferences

Use model quality intentionally. Intelligence is the ability to solve difficult
problems unsupervised; taste covers UI/UX, code quality, API design, and copy.
Cost is a tie-breaker only. For anything that ships, prefer intelligence, then
taste, then cost.

| model         | cost | intelligence | taste |
| ------------- | ---- | ------------ | ----- |
| gpt-5.6 terra | 9    | 8            | 6     |
| sonnet-5      | 5    | 5            | 7     |
| opus-5        | 5    | 8.5          | 8     |
| gpt-5.6 sol   | 3    | 8.5          | 8.5   |
| fable-5       | 2    | 9            | 9     |

- Use `gpt-5.6-terra` for clear-spec, mechanical, or bulk work.
- Use `gpt-5.6-sol` when a GPT model needs strong judgment or taste.
- Useful independent reviewers include fable-5, gpt-5.6-sol, opus-5, and,
  for a cheap extra perspective, gpt-5.6-terra.
- Never use Haiku or gpt-5.6 luna.
- These are defaults, not limits. If output misses the bar, redo or escalate
  without asking solely because a stronger model costs more.

## Native Codex subagents

- Use native Codex subagents only when the user or applicable repository
  instructions authorize delegation or parallel agent work.
- Prefer native subagents for work that can proceed independently and has a
  concrete, bounded deliverable.
- Available native model slugs and reasoning levels come from the current
  Codex runtime. Do not invent unsupported model names.
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
explicitly (`low`, `medium`, `high`, `xhigh`, or `max`) based on difficulty.
Use `--output-format json` when reliable machine parsing materially helps.

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

# Presenting plans

- Present plans directly and concisely in chat by default.
- If an applicable installed planning or visualization skill exists, follow
  it. Do not assume a particular skill or publishing CLI is installed.
- Include a local or hosted artifact only when it materially improves the
  plan or the user requests one. A publishing failure must not block delivery
  of the plan in chat.

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

# Branches, worktrees, commits, and pull requests

- Use the current checkout by default unless the user requests isolation or
  parallel work makes an isolated worktree necessary.
- When creating worktrees, use supported current tools or conservative
  `git worktree` commands. Never remove the worktree containing the active
  session.
- Do not assume every task requires a branch, commit, push, or pull request.
  Perform those actions only when requested or clearly included in the
  authorized workflow.
- If opening a pull request, determine the intended base branch and pass it
  explicitly. Verify tests, the pushed commit, and the final diff first.
- Never rewrite, discard, or force-push history without explicit authorization.

