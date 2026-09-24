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
python3 scripts/sync-agent-prompts.py ../personal-laptop
python3 scripts/sync-agent-prompts.py ../personal-laptop --write
```

Run without `--write` to check for drift. Add `--write` to copy shared files
onto a task branch; the script refuses to overwrite uncommitted changes.
Inspect the diff in every affected repository, run its required checks, and
follow its merge and deployment rules. Sync every fleet repo included in the
task, even when its machine is offline. Report pending machine deployments.

Home Manager installs rlyeh's files during a system rebuild. On miskatonic
and yuggoth, `./export_current --agents-only` installs instructions, references,
skills, and hook scripts. It leaves unrelated machine settings alone. Compare every
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
