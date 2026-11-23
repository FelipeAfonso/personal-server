# Model selection and usage limits

The four buckets in the global instructions are the current routing policy.
Fable holds Reasoning and Product. Neon holds Implementation and Routine.
Use the model and effort for the task's bucket. Explicit user restrictions
still apply.

## Weekly allowance

Each model runs on its own subscription with its own weekly window: Fable on
the Anthropic one, Neon on the Google AI one through Antigravity. Use the
weekly window, not session tokens or a short-window percentage. Thirty
percent remaining means 70% used. Consider reset times and any other
applicable limit before selecting a worker. A reported shared pool applies to
every model known to use it; switching models does not create allowance.
Google reports one pool for all Gemini models.

Use current provider data when available, or a recent user-supplied reading.
`~/.agents/skills/pr-review/scripts/agent-usage` reads both weekly windows:
Anthropic's from a one-word Claude prompt, Google's from the Antigravity
CLI's `/usage` command, which runs no model. Keep the source and observation
time with any cached figure. Missing, expired, or stale data means unknown,
not exhausted or unlimited. When usage is unknown, follow the bucket table,
and disclose the uncertainty if it affects the decision.

PR review is the one automatic route. The `pr-review` skill sends reviews to
Fable. Neon at xhigh effort takes the review when 30% or less of the
Anthropic week remains, or when Fable does not finish. Other delegation
stays a judgment made with this guidance.

A low allowance does not move Reasoning or Product work to Neon. When the
Anthropic allowance is spent, wait for the reset or ask Felipe. When the
Google allowance is spent, Fable may take Implementation work that cannot
wait. Keep a healthy ongoing worker on its task. On a confirmed quota
failure, preserve its progress and hand off or report the reset time, then
continue independent work. Automatic paid overages remain disabled:
no API keys, and Antigravity's `useG1Credits` setting stays off. User
overrides can specify a model, reserve, or restriction.

## Scope and review

Routine executes settled instructions with acceptance criteria. It can
implement a small script or an agreed data transformation. Neon cannot make
high-level decisions, design architecture, or perform substantive review
outside the `pr-review` fallback. Return such decisions to Reasoning.

Reviews use the appropriate task bucket. Since Fable holds both review
buckets, independence comes from a fresh session that did not write the
change. Poor results from Neon justify moving the task to Fable, not
repeated attempts.

Never select an unlisted model without Felipe's authorization. Read
[delegation.md](delegation.md) for identifiers and client mechanics.
