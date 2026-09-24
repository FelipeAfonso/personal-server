---
name: plan-html-workflow
description: Create standalone HTML plans in a repo's .plans directory when the user requests HTML or a visual artifact would materially help. Supports publishing with postplan when a hosted link is requested or required by the repository workflow. Ordinary chat plans do not need this skill.
---

# Plan HTML workflow

Adapted from the `plan-html-workflow` skill in `AadiJo/postplan` (itself adapted
from the MIT-licensed `html-it` skill by RoboNuggets and Thariq Shihipar's
"Using Claude Code: The unreasonable effectiveness of HTML"). Rewritten for the
npm `postplan` CLI (postplan.dev, maintained by t3dotgg) — the upstream skill
targets a same-named but different project, and its `postplan init` / `new` /
`publish` commands do not exist here.

## When to use

Keep ordinary plans in chat. Use this skill for a requested HTML plan or when
an artifact adds useful visual or interactive content. Creating a local file
does not require publishing it. Upload only when the user requests a hosted
link or the repository workflow includes publishing.

## The CLI

Installed commands are only `auth`, `whoami`, `upload`, `list`. There is no
`init`, `new`, `publish`, `config set`, or project slug — don't invent them.

```sh
bunx postplan upload <file.html> --description "<one-line summary>"
```

- Drafts are keyed by **absolute file path** in `~/.postplan/drafts.json`.
  Re-uploading the same path updates that draft in place: same URL, version
  bumped. A stable `.plans/` path is what makes plan revisions land on one URL.
- `--new` forces a separate draft, `--draft <id>` targets an existing one.
- Upload prints `URL`, `Raw HTML`, `Draft ID`, `Version`. The `URL` line
  (`https://<id>.postplan.dev`) is what you give the user.
- `<title>` becomes the draft name in `bunx postplan list` and the dashboard —
  set a real one, not "Plan".
- Auth is already configured; `bunx postplan whoami` verifies, `bunx postplan
  auth login` re-establishes.
- Hosted pages are readable by anyone with the URL — no auth on the public
  page. Keep credentials and genuinely sensitive material out of the HTML.

## Storage rule

Durable plans go in the current repo's `.plans/` directory:

```txt
.plans/yyyy-mm-dd_snake_case_name.html
```

`mkdir -p .plans` if it doesn't exist. No project slug in the path — the
repository is the boundary. If the repo doesn't already ignore `.plans/`, ask
the user once whether to commit plans or gitignore them; don't decide silently.

## Style rule

Start from `assets/plan-template.html` and read `references/components.md`
before creating or heavily editing a plan that needs structured components.
Keep the `pp-*` class names exact.

- dark mode only; keep the `#111212` page background from the template
- narrow readable body width, large plain title, one short summary near the top,
  small metadata line, sections separated by thin dividers
- standardized components for callouts, section navigation, stats, facts,
  badges, tables, code blocks, and interactive controls
- syntax-highlighted `pre > code`; add `language-*` when the language is known
- no decorative cards, pills, glows, gradients, fake app previews, or
  ornamental labels
- **single self-contained file** — inline all CSS and JS, no remote CSS, fonts,
  scripts, or images unless the user explicitly asks. postplan.dev serves the
  file verbatim with no injected chrome, so the document is the whole page: it
  must stand alone, and there is no host top bar to leave room for or duplicate.

## Content rule

Prefer HTML over Markdown when the output is substantial, visual, comparative,
interactive, or meant to be shared. Use the lowest useful level:

1. Static document: plans, specs, reports, postmortems, PR explainers.
2. Visual artifact: comparison tables, SVG flows, annotated snippets,
   architecture maps.
3. Interactive artifact: toggles, sliders, filters, editable text, live
   previews.
4. Throwaway tool: triage boards, config editors, prompt tuners, annotation
   tools.

If the request involves comparing options, tuning assumptions, ranking,
budgeting, capacity planning, risk scoring, prioritization, thresholds, or
"what if" decisions, treat it as at least level 3 and include a small working
interactive section unless the user asked for a static document. Don't merely
describe a control that should exist later — build the lightweight model into
the file. For level 3 or 4, include an export action (`Copy as JSON`, `Copy as
prompt`, `Copy as Markdown`) so the user's interaction can feed the next step.

## Workflow

1. `mkdir -p .plans` in the current repo if needed.
2. Copy `assets/plan-template.html` to
   `.plans/yyyy-mm-dd_snake_case_name.html` and fill in the `{{title}}`,
   `{{summary}}`, `{{date}}`, `{{localPath}}` placeholders.
3. Write the actual content: context, recommendation, implementation steps,
   risks, verification, open questions. Add visual structure only when it
   carries information. Avoid walls of prose — dense sections become tables,
   diagrams, or short lists.
4. When publishing is requested or required, run `bunx postplan upload .plans/<file>.html --description "<one-line summary>"`.
5. After publishing, put the returned URL into the `Plan links` section's
   `data-postplan-hosted` cell (replacing `pending publish`) and re-upload so
   the hosted page carries its own link.
6. Reply with the local file link and a brief summary. Include the hosted URL
   if published. For a local artifact, leave the hosted link out of the file.

On revision, edit the same file. If it was published, re-upload the same path
to keep its URL.

If upload fails, don't hide the plan: give the local file link, say briefly why
publishing failed, include the command to rerun, and fall back to a markdown
summary in the chat rather than blocking.
