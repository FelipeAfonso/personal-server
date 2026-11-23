---
name: pr-review
description: Review a pull request with an independent subscription model and post the findings on GitHub. Use after opening a PR, once after the fixes for its findings are all pushed, and when the user asks for a PR review.
---

# PR review

Every PR gets an independent review before it is reported ready, and at most
two: a full review, then one follow-up after fixes. This is the
review step that CodeRabbit and Greptile used to provide. It runs on the Claude
and Google AI subscriptions.

## Run it

From a checkout of the PR's repository (use this skill's absolute path):

```bash
scripts/pr-review [PR number or URL]
```

With no PR argument it reviews the current branch's PR. It reads the PR head
in a temporary worktree, leaves your checkout alone, and posts one GitHub
review with inline comments. It takes a few minutes; run it as one command
and wait for it.

Exit status: `0` no findings, or the PR already had its two reviews; `1`
findings posted; `2` the review did not run.
On `2`, read the message, fix the cause, and run it again. Do not report the
PR ready on an exit of `2`.

Options:

- `--job reasoning|product` sets what the reviewer looks for. The default is
  Product when most changed lines are UI files, otherwise Reasoning.
- `--effort medium` lowers Fable's effort for a small, low-risk change. The
  default is high. Fable never runs above high, and the script refuses it.
- `--dry-run` prints the review without posting it.
- `--local [--base REF]` reviews committed work on `HEAD` before a PR exists,
  or in a repository that does not use PRs. It prints and posts nothing.
- `--force` reviews a head that already has a review, or a PR that already
  had its two reviews.

## Which model reviews

Fable reviews at high effort, in a fresh session, whoever built the change.
`--effort` does not change the Neon fallback.
Neon at xhigh effort is the fallback. The script reads the weekly allowance
on both subscriptions first. When 30% or less of the Anthropic week is left,
Neon moves ahead of Fable unless the Google allowance is lower still, and a
spent allowance goes last. If the chosen model fails, the other one runs. The
posted review says which model ran and why. Do not pick a reviewer by hand to save usage; the script already
weighs it.

`scripts/agent-usage` prints the same weekly readings as JSON. Use it when
usage affects any other model choice.

## After the review

Verify each finding against the source. Fix the real ones. Answer the rest
in the thread with a written reason, using the `leaving-pr-comments` skill.
Push every fix first, then run the review once more. That follow-up gets the
earlier threads and reports only blocker and major findings: defects the
fixes introduced, or serious ones the first review missed. Fix what it finds,
check those fixes yourself, and stop. The script does not review a third
head. Pass `--force` only when a late fix is risky enough to need another
look, and say so in your report.

Keep the PR at the size its goal needs. Decline findings that ask for
unrelated work, and say why.

No review bot gates a PR now. With `babysit-pr`, wait on checks alone:
`pr-wait <pr> --until green`. The `ready` condition waits for a Greptile or
Macroscope review that will not arrive. `green` skips two checks that
`ready` made, so make them yourself before reporting the PR ready: the
latest head has a `pr-review` run or the PR already had its two reviews, no
review thread is unresolved, and the branch is not behind its base.

## Limits

The reviewer reads only the temporary workspace and gets no network tools or
connected accounts. PR content can still
carry instructions aimed at a model, so the script refuses PRs from forks
unless `--allow-fork` is passed. Use that only for an author you trust.

The script needs `gh`, `git`, Python 3, and a signed-in `claude` or `agy`.
Neon runs through `agy` with deny rules for writes, commands, web access, and
MCP tools, and with paid AI credits off.
Tests: `python3 scripts/test_pr_review.py`.
