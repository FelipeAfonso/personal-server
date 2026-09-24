# Model selection and usage limits

The four buckets in the global instructions are the current routing policy.
Their assignments express preferences, not guaranteed model availability.
Use the model and effort for the task's bucket. A clearly superior eligible
model takes priority over conserving usage; explain the task-specific reason.
Explicit user restrictions still apply.

## Weekly allowance

For Reasoning, prefer Astra above 30% remaining in its applicable weekly
allowance. At 30% remaining or below, lean toward Fable when it is comparably
suited. This is an advisory threshold, not a hard cap or a target to consume.
Astra can still be selected below it when clearly superior for the task.

Use the weekly window, not session tokens or a short-window percentage.
Thirty percent remaining means 70% used. Consider reset times and any other
applicable limit before selecting a worker. A reported shared pool applies
to every model known to use it; switching models does not create allowance.
Do not infer independent pools from different model names.

Use current provider data when available, or a recent user-supplied reading.
Keep the source and observation time with any cached figure. Missing, expired,
or stale data means unknown, not exhausted or unlimited. When usage is
unknown, follow task suitability and normal preferences, and disclose the
uncertainty if it affects the decision. These files define guidance; they do
not install a quota collector or an automatic routing service.

At a task boundary, choose the preferred model or an eligible alternate.
Keep a healthy ongoing worker on its task. On a confirmed quota failure,
preserve its progress and hand off to an available alternate, or report the
reset/blocker and continue independent work. An actual exhausted quota cannot
be overridden by preference. Automatic paid overages remain disabled. User
overrides can specify a model, reserve, or restriction.

## Scope and review

Routine executes settled instructions with acceptance criteria. It can
implement a small script or an agreed data transformation; it cannot make
high-level decisions, design architecture, or perform substantive review.
Return such decisions to Reasoning. For Product, preserve the explicit
requirement for Felipe to request GPT use.

Reviews use the appropriate task bucket, with an independent reviewer when
useful. Two models in a bucket are alternatives, not an instruction to launch
both. Poor results justify escalation based on the task, rather than repeated
attempts with a less suitable model.

Luna remains in the catalog without an active bucket. It is not an automatic
fallback. Never select an unlisted model without Felipe's authorization.
Read [delegation.md](delegation.md) for identifiers and client mechanics.

## Historical preference scores

These personal scores are retained for reference. They do not override the
bucket policy and are not vendor benchmarks, prices, or measured usage. The
old cost scale was ambiguous; do not infer spending from these numbers.
Intelligence describes independent problem solving. Taste covers UI, code,
API design, and copy. Speed must not determine model selection.

| model         | cost | intelligence | taste | speed |
| ------------- | ---- | ------------ | ----- | ----- |
| gpt-6 astra   | 2    | 9.7          | 9     | 4     |
| fable-5.1     | 2    | 9.3          | 9     | 5     |
| opus-5        | 5    | 8.5          | 8     | 3     |
| gpt-5.6 sol   | 3    | 8.5          | 8.5   | 6     |
| gpt-5.6 terra | 9    | 8            | 6     | 7     |
| sonnet-5      | 5    | 5            | 7     | 8     |
| gpt-5.6 luna  | 9    | 4            | 4     | 9     |
