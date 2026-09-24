# Maintaining agent instructions

Read this when updating global instructions or debugging writing hooks.
The canonical shared sources are in personal-server's `home/felipe/agents/`.
Machine notes remain in each machine's configuration repository.

Each generated global file combines the client-specific file, `models.md`,
`workflow.md`, and the machine notes. Keep general policy in `workflow.md`,
short model routing in `models.md`, and procedures in `references/`. References
are installed under `~/.agents/references/` and read only when needed.

Edit repository sources, never generated files. From personal-server:

```sh
python3 scripts/sync-agent-prompts.py ../personal-desktop
python3 scripts/sync-agent-prompts.py ../personal-desktop --write
```

The first command checks for drift. The second copies shared files onto a
task branch and refuses to overwrite uncommitted changes. Inspect the diff
in both repositories, run their required checks, and follow each repository's
merge and deployment rules. The laptop can be synchronized with the same
command when its checkout is available and the task includes it.

Home Manager installs rlyeh's files during a system rebuild. On miskatonic,
`./export_current --agents-only` installs instructions, references, skills,
and hook scripts. It leaves unrelated desktop settings alone. Compare every
generated prompt with its source and check reference links after deployment.
Existing conversations may retain older instructions.

## Writing hooks

Claude's `~/.claude/settings.json` references two scripts. UserPromptSubmit
runs `~/.claude/hooks/unslop-reminder.sh`. Stop runs
`~/.claude/hooks/unslop-stop-gate.py`, which checks for an unslop Skill call
during the current turn. If it blocks a reply, invoke the skill and revise
the prose. Do not bypass the gate.

The scripts are repository-managed. The hooks block in settings.json is
maintained separately because Claude writes to that file at runtime. Preserve
unrelated settings when repairing it. Codex and OpenCode read the unslop
skill directly when they have no Skill tool; Claude's hook mechanics do not
apply to those clients.
