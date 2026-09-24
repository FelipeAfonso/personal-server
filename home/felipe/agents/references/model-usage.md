# Current model catalog and expected usage

This describes Felipe's configured assignments as of September 24, 2026,
before the next preference update. Usage estimates follow those assignments;
they are not measured calls, tokens, costs, or vendor capability claims.
Actual usage depends on task mix, delegation permissions, and model access.

| Model | Assigned work | Expected usage |
| --- | --- | --- |
| GPT-6 Astra | Architecture, difficult debugging, independent investigation, and lead review | High involvement across substantial tasks. Longer reasoning and review sessions; less routine implementation volume than Sol. |
| Fable 5.1 | UI, product copy, API design, independent lead review, and fallback for Astra | High on product work and substantive reviews. Can become the main builder during a UI-heavy phase or when Astra is unavailable. |
| GPT-5.6 Sol | Bulk implementation once design decisions are settled; additional review | Expected to produce the largest share of code on implementation-heavy work. Long hands-on sessions across backend changes, refactors, and related tests. |
| Opus 5 | Fallback or second builder for Fable's user-facing work | Occasional under normal conditions. Usage rises when Fable is unavailable or a second builder is useful. |
| Sonnet 5 | General prose, data cleaning, and thin orchestration wrappers | Moderate, with potentially frequent short jobs. Writing and cleanup batches can be longer; wrappers should remain small. |
| GPT-5.6 Terra | Disposable scripts, one-off migrations, and optional additional review | Low to moderate, usually bounded jobs. It should not inherit difficult work merely because the result is a script. |
| GPT-5.6 Luna | Data-cleaning fallback when Sonnet cannot handle the workload | Rare and conditional. The preference does not establish a larger context window or guarantee that a particular dataset fits. |

Astra and Fable always use high effort. The other models use medium for bulk
work and high for reviews or user-facing work. Sonnet wrappers use low.

The active conversation model handles ordinary replies and coordination.
Model routing governs workers selected for task deliverables. Product copy
uses the Fable route; general documents use the Sonnet route. Disposable task
scripts go to Terra, while thin wrappers coordinating other models go to
Sonnet. Hard problems go to Astra regardless of file type.

For an implementation-heavy period, expect Sol to dominate code volume,
with Astra and Fable contributing decisions and review. For a product-design
period, Fable's share rises. A document or data-cleanup period shifts work
toward Sonnet. The routing policy alone does not support numerical percentages.

The preference scores are preserved in [models.md](models.md). Their cost
scale needs clarification before using those numbers to estimate spend.
Model identifiers and access checks are in [delegation.md](delegation.md).
