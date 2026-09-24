# Model buckets

Choose a bucket for each delegated task. The active agent handles ordinary
conversation and coordination. Effort belongs to the bucket assignment.

| Bucket | Work | Preferred | Alternate |
| --- | --- | --- | --- |
| Reasoning | Architecture, high-level thinking, hard debugging, investigations | GPT-6 Astra, high | Fable 5.1, high |
| Implementation | Substantial coding, refactors, tests after design decisions | Opus 5, medium | GPT-5.6 Sol, high |
| Product | UI implementation, UX, product copy, API design | Fable 5.1, high | Opus 5, xhigh |
| Routine | Small implementations and transformations with settled instructions | Sonnet 5, medium | GPT-5.6 Terra, medium |

Routine must not choose architecture, resolve design tradeoffs, or perform
substantive review. Give it clear instructions and acceptance criteria. Return
unresolved decisions to Reasoning. Thin orchestration wrappers may use Sonnet
at low effort.

Prefer Astra for Reasoning while more than 30% of its applicable weekly
allowance remains. At 30% remaining or below, lean toward Fable when it can
handle the task comparably. This is a soft preference: use a clearly superior
model regardless of remaining allowance, with a brief task-specific reason.
Explicit user restrictions take precedence. Actual quota exhaustion requires
an available alternate or waiting; automatic paid overages are disabled.

Reviews use Reasoning or Product as appropriate, preferably with a different
reviewer from the builder. Match review effort to the consequences of the
change. Do not launch both models merely because a bucket has two entries.

Choose quality over speed. Use the configured catalog; GPT for Product still
requires Felipe's request. Before delegation, read
`~/.agents/references/delegation.md`. Read `models.md` in that directory when
usage pressure affects selection or when revising the catalog. Luna has no
active bucket and is not an automatic fallback.
