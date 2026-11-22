---
name: pr-review
description: Review a pull request with an independent subscription model and post the findings on GitHub. Use after opening a PR, after each push that changes its code, and when the user asks for a PR review.
---

# PR review

Every PR gets one independent review before it is reported ready. This is the
review step that CodeRabbit and Greptile used to provide. It runs on the Claude
and Codex subscriptions.

## Run it

From a checkout of the PR's repository (use this skill's absolute path):

```bash
scripts/pr-review [PR number or URL] --builder <class that wrote the change>
```

With no PR argument it reviews the current branch's PR. It reads the PR head
in a temporary worktree, leaves your checkout alone, and posts one GitHub
review with inline comments. It takes a few minutes; run it as one command
and wait for it.

Exit status: `0` no findings, `1` findings posted, `2` the review did not run.
On `2`, read the message, fix the cause, and run it again. Do not report the
PR ready on an exit of `2`.

Options:

- `--builder opus` names the model class that wrote the change, so the same
  class does not review its own work. Pass your own class.
- `--job reasoning|product` overrides the automatic choice. The default is
  Product when most changed lines are UI files, otherwise Reasoning.
- `--effort xhigh` raises effort for a change with serious consequences.
- `--dry-run` prints the review without posting it.
- `--local [--base REF]` reviews committed work on `HEAD` before a PR exists,
  or in a repository that does not use PRs. It prints and posts nothing.
- `--force` reviews a head that already has a review.

## Which model reviews

The script follows the model buckets. Reasoning prefers Astra, then Fable.
Product prefers Fable, then Opus. Astra takes a Product review only when the
Anthropic allowance is low or no Anthropic reviewer finishes. It reads the weekly allowance
on both subscriptions first. A provider with 30% or less of its week left
moves behind one with more, and a spent allowance goes last. If the chosen
model fails, the next candidate runs. The posted review says which model ran
and why. Do not pick a reviewer by hand to save usage; the script already
weighs it.

`scripts/agent-usage` prints the same weekly readings as JSON. Use it when
usage affects any other model choice.

## After the review

Verify each finding against the source. Fix the real ones. Answer the rest
in the thread with a written reason, using the `leaving-pr-comments` skill.
After you push fixes, run the review again; it reviews each head once and
gives the reviewer the earlier threads, so answered points are not raised
twice. Stop when a review comes back with no findings you still owe a fix.

Keep the PR at the size its goal needs. Decline findings that ask for
unrelated work, and say why.

No review bot gates a PR now. With `babysit-pr`, wait on checks alone:
`pr-wait <pr> --until green`. The `ready` condition waits for a Greptile or
Macroscope review that will not arrive. `green` skips two checks that
`ready` made, so make them yourself before reporting the PR ready: the
latest head has a `pr-review` run, no review thread is unresolved, and the
branch is not behind its base.

## Limits

The reviewer reads only the temporary workspace and gets no network tools or
connected accounts. PR content can still
carry instructions aimed at a model, so the script refuses PRs from forks
unless `--allow-fork` is passed. Use that only for an author you trust.

The script needs `gh`, `git`, Python 3, and a signed-in `claude` or `codex`.
Tests: `python3 scripts/test_pr_review.py`.
