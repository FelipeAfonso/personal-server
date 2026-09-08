# Writing: always run the unslop skill

Every piece of prose you produce for a human (chat replies, commit messages, PR descriptions, docs, plans, comments, copy) goes through the `unslop` skill before it ships. Load it, scan the text against its pattern list, rewrite, then self-audit. The tells that show up most in agent output, gone on sight: no em dashes (periods or commas instead), no "not just X but Y", no rule-of-three padding, no inline-header bullet lists that restate themselves, no chatbot sign-offs, sentence-case headings, plain words over "leverage"/"delve"/"crucial". Sounding like a person beats sounding polished. If the skill isn't installed on the machine you're on, apply those rules from memory anyway.

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

