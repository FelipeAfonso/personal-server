# Model buckets and expected usage

This describes Felipe's agreed routing policy as of November 23, 2026.
Buckets name model classes; each resolves to the newest available version.
Usage estimates follow the assignments; they are not measured calls, tokens,
costs, or vendor capability claims. Actual usage depends on task mix and
available allowance.

| Bucket | Model | Typical work |
| --- | --- | --- |
| Reasoning | Fable, high | Architecture, high-level thinking, hard debugging, investigations, substantive technical review |
| Product | Fable, high | UI implementation, UX, product copy, API design, user-facing review |
| Implementation | Neon, high | Substantial coding, refactors, tests once design decisions are settled |
| Routine | Neon, medium | Small implementations and transformations with settled instructions and acceptance criteria |

Neon is expected to carry most of the volume: implementation, routine
execution, and low-effort wrappers. Fable handles difficult decisions,
Product work, and review. OpenAI models, Opus, and Sonnet left the catalog
on November 23, 2026.

Neon never takes high-level thinking. It returns unresolved decisions to
Reasoning. Its one review role is the `pr-review` fallback at xhigh effort,
used when 30% or less of the Anthropic weekly allowance remains or Fable
does not finish.

Each model has its own subscription and weekly window. Actual quota
exhaustion means waiting, or Fable taking Implementation work that cannot
wait. Automatic paid overages and AI credits remain disabled.

Shared quota pools and stale readings need explicit handling. See
[models.md](models.md) for selection rules and [delegation.md](delegation.md)
for client mechanics. PR review is routed automatically by the `pr-review`
skill, which reads both weekly allowances; other work is routed by judgment.
