# Model preference notes

These are Felipe's personal scores, preserved before the next preference
update. They are not vendor benchmarks, prices, or observed usage. The old
notes said "higher = better" while also describing cost as money paid after
subscription limits. The cost scale is ambiguous; use the routing decisions
in the global instructions until Felipe clarifies it.

Intelligence describes independent problem solving. Taste covers UI, code,
API design, and copy. Speed is recorded for reference and must not determine
model selection. Prefer intelligence, then taste, then cost.

| model         | cost | intelligence | taste | speed |
| ------------- | ---- | ------------ | ----- | ----- |
| gpt-6 astra   | 2    | 9.7          | 9     | 4     |
| fable-5.1     | 2    | 9.3          | 9     | 5     |
| opus-5        | 5    | 8.5          | 8     | 3     |
| gpt-5.6 sol   | 3    | 8.5          | 8.5   | 6     |
| gpt-5.6 terra | 9    | 8            | 6     | 7     |
| sonnet-5      | 5    | 5            | 7     | 8     |
| gpt-5.6 luna  | 9    | 4            | 4     | 9     |

The allowed catalog is limited to these seven models. Haiku and unlisted
models are excluded. Read `~/.agents/references/delegation.md` for invocation
and availability checks. The routing policy applies to delegated work;
the active agent handles ordinary conversation and task coordination.
