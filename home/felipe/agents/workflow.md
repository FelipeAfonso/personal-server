# Working together

Carry an authorized task through its required verification and delivery.
Authorization persists within its agreed scope. Prepare a concrete result
before asking for any remaining approval; do not ask again for approval
already given. Ask when a missing decision blocks progress, and continue
independent work while waiting.

Delegate bounded work when it helps complete the authorized task and the
active client's rules permit it. Model routing does not require a worker for
every task. Review effort should match the consequences of the change.

Run unslop before sending human-facing prose. Invoke it through the Skill
tool when available; otherwise read `~/.agents/skills/unslop/SKILL.md`, falling
back to `~/.claude/skills/unslop/SKILL.md`. Read once per conversation and
apply it throughout. If both paths are missing, use plain language, avoid em
dashes and canned phrases, and audit the text yourself.

Present plans in chat. Create a separate artifact when requested or useful;
publish only when requested or included in the repository workflow.

# Repository work

Read repository instructions and inspect the working tree before editing.
Preserve unrelated changes. Ask only when overlapping work creates a real
ambiguity. Use the current checkout unless concurrent work requires isolation.
Never remove an active session's worktree. Do not clean up other worktrees
or rewrite history without explicit authorization.

Implementation includes a task branch, commit, push, and PR unless the user
or repository specifies another delivery workflow. Use the repository's
specified base, otherwise `dev` if present, otherwise its default branch.
Verify the remote base and pass it explicitly. Follow-ups continue on the
same task branch. Merge and deployment require their own authorization.

Run the repository's required checks and verify the behavior you changed.
Inspect the final diff and confirm the pushed commit matches the local one.
Do not invent test results or treat pending CI as passed.

# Completion and references

For implementation, report what changed, validation, and the delivery link or
remaining blocker. For investigations, give findings, evidence, and unresolved
questions. Previews need a reachable URL and process lifetime details.

Read only the references relevant to the current action, under
`~/.agents/references/`:

- `delegation.md` before launching a worker.
- `tools.md` when a required integration or skill is unavailable or failing.
- `previews.md` before starting a preview or persistent process.
- `fleet.md` before remote-machine or network administration.
- `maintenance.md` when changing global instructions or debugging writing hooks.

Treat installed tools and authentication as things to verify when needed.
Do not run broad capability checks for unrelated tasks.
