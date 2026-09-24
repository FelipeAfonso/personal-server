# Model routing

These preferences apply when selecting workers. The active agent handles
ordinary conversation and coordination. Product copy follows the UI route;
other prose follows the prose route.

| Work | Preferred model | Fallback or extra reviewer |
| --- | --- | --- |
| Architecture, hard debugging, independent problem solving | Astra | Fable 5.1 |
| UI, product copy, API design | Fable 5.1 | Opus 5; GPT only if Felipe requests it |
| Bulk implementation after design decisions | GPT-5.6 Sol | Escalate hard problems to Astra |
| Disposable scripts and migrations | GPT-5.6 Terra | Escalate if results miss the bar |
| Prose and data cleaning | Sonnet 5 | GPT-5.6 Luna when Sonnet cannot handle the data workload |
| Thin orchestration wrappers | Sonnet 5 | Low effort |
| Plan and implementation reviews | Astra and Fable 5.1 | Sol, then Terra for additional review |

Astra and Fable always use high effort. Others use medium for bulk work and
high for reviews or user-facing work. Choose quality over speed; cost breaks
ties. Use only this catalog. Before delegation, read
`~/.agents/references/delegation.md`; read `models.md` in that directory only
when comparing preferences or revising the catalog.
