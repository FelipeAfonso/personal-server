# Writing: always run the unslop skill

Every piece of prose you produce for a human (chat replies, commit messages, PR descriptions, docs, plans, comments, copy) goes through the `unslop` skill before it ships. Load it, scan the text against its pattern list, rewrite, then self-audit. The tells that show up most in agent output, gone on sight: no em dashes (periods or commas instead), no "not just X but Y", no rule-of-three padding, no inline-header bullet lists that restate themselves, no chatbot sign-offs, sentence-case headings, plain words over "leverage"/"delve"/"crucial". Sounding like a person beats sounding polished. If the skill isn't installed on the machine you're on, apply those rules from memory anyway.

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

## Subagents inside opencode

- opencode's own subagents (`@general`, `@explore`, or any agent defined in
  `opencode.json`) are the first choice for parallel or bounded work. Pick the
  model per agent with the `model` field (`anthropic/claude-...`,
  `openai/gpt-5.6-...`) instead of leaving it on the session default.
- Give every subagent a self-contained objective, relevant paths, constraints,
  expected output, and whether it may edit files.
- The primary agent owns the final result: inspect changes and verify claims
  rather than forwarding a subagent's output uncritically.

## Running the other CLIs as external workers

Both `claude` and `codex` are installed and authenticated. When a model or a
harness feature that opencode doesn't have is the right tool, shell out to it
from the relevant repository directory with a self-contained prompt.

Claude Code, read-only review or investigation:

```sh
claude -p --model fable --effort high --permission-mode plan \
  --tools "Read,Grep,Glob" "<self-contained prompt>"
```

Choose the model explicitly (`sonnet`, `opus`, or `fable`) and the effort
explicitly (`low` through `max`). Use `--output-format json` when you need to
parse the result. For edits, prefer `--worktree <name>` and never pass
`--dangerously-skip-permissions`.

Codex, read-only:

```sh
codex exec -m gpt-5.6-terra -s read-only "<self-contained prompt>"
```

Always pass `-m` (`gpt-5.6-terra` or `gpt-5.6-sol`); the CLI default is served
remotely and can change under you.

Each external prompt must include:

- the objective and concrete deliverable;
- the repository path and relevant files or context;
- applicable constraints and acceptance criteria;
- whether the task is read-only or may make edits;
- an instruction to preserve unrelated changes and avoid destructive actions;
- a request to report evidence, uncertainties, and verification performed.

Inspect the resulting diff and run appropriate verification before accepting
any external worker's output.

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

