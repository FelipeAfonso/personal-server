# tstack skills

Vendored from https://github.com/t3dotgg/tstack at commit
`7de017b3fc9d50c03cf3ecb98fb71e0ca65a78bd`. The skill directories are upstream
copies, including agent metadata and the executable `pr-wait` helper, with
three local changes made when OpenAI models left the catalog: `sol-loop` is
removed, `full-send` gets its feedback from `pr-review --local`, and
`babysit-pr` no longer mentions a Sol round. `council` still names three
providers because it runs only when Felipe asks for it.
The upstream MIT license is in `LICENSE`.

All eight skills install into `~/.claude/skills/`, `~/.agents/skills/`, and
`~/.gemini/config/skills/`, where Claude Code, OpenCode, and Antigravity
discover them. GitHub workflows need
an authenticated `gh`; `pr-wait` also needs Python 3. The review skills need
a client that supports their requested models and delegation.

To update, replace the skill directories from a reviewed upstream commit,
reapply the local changes above, preserve executable modes, update this revision, and run
`scripts/sync-agent-prompts.py ../personal-desktop --write` from personal-server.
Run the fleet repositories' checks before merging and deploying.
