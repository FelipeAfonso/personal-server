# Model buckets and expected usage

This describes Felipe's agreed routing policy as of September 24, 2026.
Usage estimates follow the assignments; they are not measured calls, tokens,
costs, or vendor capability claims. Actual usage depends on task mix, available
allowance, and task-specific model suitability.

| Bucket | Preferred | Alternate | Typical work |
| --- | --- | --- | --- |
| Reasoning | GPT-6 Astra, high | Fable 5.1, high | Architecture, high-level thinking, hard debugging, investigations, substantive technical review |
| Implementation | Opus 5, medium | GPT-5.6 Sol, high | Substantial coding, refactors, tests once design decisions are settled |
| Product | Fable 5.1, high | Opus 5, xhigh | UI implementation, UX, product copy, API design, user-facing review |
| Routine | Sonnet 5, medium | GPT-5.6 Terra, medium | Small implementations and transformations with settled instructions and acceptance criteria |

Opus is expected to carry most implementation volume under normal conditions.
Sol takes substantial coding work when it is more suitable or usage pressure
favors its pool. Astra handles difficult decisions and review; Fable carries
Product work and more Reasoning work when Astra's weekly allowance runs low.
Sonnet and Terra handle bounded execution. Sonnet wrappers may use low effort.
Luna has no active assignment or automatic fallback role.

Routine never takes high-level thinking or substantive review. It returns
unresolved decisions to Reasoning. Reviews use Reasoning or Product as needed;
two bucket members do not imply two mandatory reviewers.

Astra is preferred above 30% weekly allowance remaining. At 30% or below,
lean toward Fable when comparably suited. This threshold is soft: use a clearly
superior model regardless of remaining allowance unless the user explicitly
restricts it. Actual quota exhaustion requires an alternate or waiting.
Automatic paid overages remain disabled.

Effort follows the bucket, so Opus uses medium for Implementation and xhigh
for Product. Usage pressure guides selection; task suitability has priority.
Shared quota pools and stale readings need explicit handling. See
[models.md](models.md) for selection rules and [delegation.md](delegation.md)
for client mechanics. The current guidance does not install a routing service.
