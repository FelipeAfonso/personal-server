# Picking the right model

Rankings, higher = better. Cost is what I actually pay after subscription
limits, not list price. Intelligence is how hard a problem you can hand the
model unsupervised. Taste covers UI/UX, code quality, API design, and copy.
Speed is listed for information only. Never favor a model for being fast; I'm
pacing myself and the agents should too.

| model         | cost | intelligence | taste | speed |
| ------------- | ---- | ------------ | ----- | ----- |
| gpt-6 astra   | 2    | 9.7          | 9     | 4     |
| fable-5.1     | 2    | 9.3          | 9     | 5     |
| opus-5        | 5    | 8.5          | 8     | 3     |
| gpt-5.6 sol   | 3    | 8.5          | 8.5   | 6     |
| gpt-5.6 terra | 9    | 8            | 6     | 7     |
| sonnet-5      | 5    | 5            | 7     | 8     |
| gpt-5.6 luna  | 9    | 4            | 4     | 9     |

Who does what:

- Hard problems, architecture, debugging, anything handed off unsupervised:
  Astra. Fable 5.1 when Astra's limit is out.
- User-facing work (UI, copy, API design): Fable 5.1. Opus 5 when Fable's
  limit is out, or as a second builder on user-facing code. GPT models only
  when Felipe asks for them here.
- Bulk implementation that isn't user-facing: Sol. Most code volume goes here.
- Code that doesn't matter much (throwaway scripts, glue, one-off migrations
  nobody reads again): Terra.
- Prose and data cleaning: Sonnet. When the data is too big for Sonnet, step
  down to Luna.
- Thin wrapper agents and glue between harnesses: Sonnet at low effort.
- Reviews of plans and implementations: Astra and Fable 5.1 as the two
  independent leads, Sol third, Terra as a cheap extra perspective.
- Never Haiku. Anything not in the table (gpt-5.5, codex-spark, ...) is off
  the menu.

Effort:

- Astra and Fable 5.1 always run at `high`. Never another level for these
  two: not low, not xhigh, not max, not ultra.
- Everything else: medium for bulk work, high for reviews and user-facing
  work.

Escalation:

- These are defaults, not limits. If a cheaper model's output misses the bar,
  redo it on a stronger model without asking. Judge the output, not the price
  tag. Escalating costs less than shipping mediocre work.
- Cost breaks ties only. When axes conflict for anything that ships,
  intelligence > taste > cost.

Slugs:

- Claude Code: `fable` (resolves to 5.1), `opus`, `sonnet`. Set effort
  explicitly (`--effort high` on the CLI, `effort: 'high'` in Agent/Workflow).
- Codex: `gpt-6-astra`, `gpt-5.6-sol`, `gpt-5.6-terra`, `gpt-5.6-luna`.
  Always pass `-m`; the CLI default is served remotely and can shift under
  you. Set effort with `-c model_reasoning_effort="<level>"`.
