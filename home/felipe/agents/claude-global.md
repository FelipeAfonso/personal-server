# Reaching models from Claude Code

The model table, roles and effort rules are in "Picking the right model"
further down. This section is only the plumbing.

- Claude models run via the Agent/Workflow `model` parameter (`fable`,
  `opus`, `sonnet`). Always set `effort` too; never leave it on the default.
- gpt models are only reachable through the Codex CLI: run `codex exec -m
  <slug> -c model_reasoning_effort="<level>"` with a self-contained prompt
  (`-s read-only` for investigation and data analysis).
- Inside workflows and subagents the `model` parameter only takes Claude
  models, so wrap: spawn a thin agent with `model: 'sonnet', effort: 'low'`
  whose prompt writes a self-contained codex prompt, runs `codex exec` via
  Bash, and returns the output. Name the slug and the effort in the wrapper's
  prompt; it has no way to infer which gpt you meant.

Use the Skill tool to invoke `unslop` during each turn before the final reply.
The configured Stop hook checks that invocation. Follow the shared workflow
below for plans, working trees, and delivery.
