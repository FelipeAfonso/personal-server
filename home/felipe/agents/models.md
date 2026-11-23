# Model buckets

Choose a bucket for each delegated task. The active agent handles ordinary
conversation and coordination. Effort belongs to the bucket assignment.
Each entry names a model class, not a version. Use the newest generally
available model in that class that the client exposes.

| Bucket | Work | Model |
| --- | --- | --- |
| Reasoning | Architecture, high-level thinking, hard debugging, investigations | Fable, high |
| Product | UI implementation, UX, product copy, API design | Fable, high |
| Implementation | Substantial coding, refactors, tests after design decisions | Neon, high |
| Routine | Small implementations and transformations with settled instructions | Neon, medium |

The catalog has two models: Anthropic's Fable and Google's Gemini Neon. Fable
takes the complex work and Neon takes everything below it. Do not select
Opus, Sonnet, any OpenAI model, or another Gemini model without Felipe's
request.

Neon must not choose architecture or resolve design tradeoffs. Give it clear
instructions and acceptance criteria. Return unresolved decisions to
Reasoning. Thin orchestration wrappers may use Neon at low effort. When Neon
does poorly on a clear brief, move the task to Fable instead of retrying.

Fable runs at high or medium effort, never xhigh or above, whatever the
task or client.

Reviews use Reasoning or Product as appropriate, so Fable reviews, in a fresh
session when it also built the change. Match review effort to the consequences
of the change, within that limit. `pr-review` may hand a review to Neon at xhigh effort when 30%
or less of the Anthropic weekly allowance remains, or when Fable does not
finish. That is the only automatic route from a Fable bucket to Neon.

Choose quality over speed. Both models run on subscriptions. An exhausted
allowance means waiting or using the other model where it suits the task;
automatic paid overages and AI credits are disabled. Before delegation, read
`~/.agents/references/delegation.md`. Read `models.md` in that directory when
usage pressure affects selection or when revising the catalog.
