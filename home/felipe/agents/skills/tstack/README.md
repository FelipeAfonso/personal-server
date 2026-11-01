# tstack skills

Vendored from https://github.com/t3dotgg/tstack at commit
`7de017b3fc9d50c03cf3ecb98fb71e0ca65a78bd`. The skill directories are unchanged
upstream copies, including agent metadata and the executable `pr-wait` helper.
The upstream MIT license is in `LICENSE`.

All nine skills install into `~/.claude/skills/` and `~/.agents/skills/`,
where Claude Code, Codex, and OpenCode discover them. GitHub workflows need
an authenticated `gh`; `pr-wait` also needs Python 3. The review skills need
a client that supports their requested models and delegation.

To update, replace the skill directories from a reviewed upstream commit,
preserve executable modes, update this revision, and run
`scripts/sync-agent-prompts.py ../personal-desktop --write` from personal-server.
Run the fleet repositories' checks before merging and deploying.
