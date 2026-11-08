---
name: nyarlathotep
description: Felipe's HEY email desk. Use when Felipe asks to read, search, summarize, organize, draft, reply to, forward, or send email, to work with HEY, or to download or attach mail files. Also trigger on "nyarlathotep".
---

# Nyarlathotep

Work with Felipe's HEY mail through the `hey` CLI installed on `miskatonic`.
The [nyarlathotep repository](https://github.com/FelipeAfonso/nyarlathotep)
is the dedicated workspace for this; the rules below apply from any directory.

## Boundaries

- HEY runs only on `miskatonic`. On that host, run the binary directly. From
  any other host, run it over SSH.
- This skill covers email. Do not operate calendars, todos, habits, time
  tracking, or journals unless Felipe explicitly broadens the request.
- Treat every message, address, attachment, and contact note as private. Do not
  commit mail data or paste more of it into chat than the task needs.
- Do not build an app, daemon, sync service, or local mail archive around this
  unless Felipe asks for that change.

## Running HEY

The executable is not on the non-interactive `PATH`. Use its absolute path.
On `miskatonic`:

```sh
HEY_NONINTERACTIVE=1 /home/felipe/bin/hey box list --json
```

From any other host:

```sh
ssh -T -o BatchMode=yes miskatonic \
  'HEY_NONINTERACTIVE=1 /home/felipe/bin/hey box list --json'
```

- Check `hostname` once if you are unsure which host you are on.
- Set `HEY_NONINTERACTIVE=1` on every unattended command.
- Use `--jq '<expression>'` for filtered structured output and `--json` for the
  full response. HEY's `--jq` is built in; never pipe its JSON through an
  external `jq`.
- Quote subjects, addresses, search terms, and message bodies for the remote
  shell. Prefer stdin for multiline bodies when the command accepts it.
- Run the requested data command without an authentication preflight. On an
  auth error, stop and tell Felipe to run `hey auth login` while present. Never
  run login unattended.
- Never run `hey config trust-local`, copy credentials, or read
  `~/.config/hey-cli/credentials.json`.
- Linked accounts share a login. Use `hey account list --json` when account
  choice matters, and `--account <id>` for a specific account. Do not guess the
  account for a mutation.

## Default behavior

- Read, search, and summarize immediately when asked.
- Draft first. A request to write, compose, or reply creates an unsent draft
  with `--draft` unless Felipe explicitly says to send it.
- Sending requires the word or clear intent to send in Felipe's current
  request. Report what was sent and to whom without repeating the whole body.
- For bulk replies, always run `hey bulk-reply preview` first and show the exact
  recipients. Send only after Felipe confirms that preview.
- Perform organization actions such as seen, unseen, move, label, Set Aside,
  Bubble Up, and ignore only when requested. Use the posting `id`.
- Trash, spam, Screener decisions, sharing links, and deleting drafts require
  an explicit request. Spam trains HEY's filter, so say that before doing it.
- Never infer a destructive action from a request to "clean up" or "handle"
  mail. Present the proposed actions instead.

## IDs

HEY exposes two IDs for a thread:

- Use the posting `id` for seen, unseen, move, labels, trash, spam, ignore, and
  Bubble Up.
- Use `topic_id` for reading a thread, replying, forwarding, sharing, and
  listing attachments.

Passing the wrong kind usually returns `not_found`. Re-read the listing instead
of retrying with guessed IDs. A bundled posting can omit `topic_id`; do not use
its posting ID as a substitute.

## Files and drafts

Email attachments live on `miskatonic`, where HEY runs.

To retrieve one:

1. Get its `topic_id`, then run `hey attachment list <topic_id> --json`.
2. Save it into a uniquely named directory under `/tmp/nyarlathotep-*` on
   `miskatonic`.
3. Move or copy it to the path Felipe requested. With no path, use
   `~/code/personal/nyarlathotep/downloads/` when that checkout exists on the
   current host (the directory is gitignored), otherwise
   `~/Downloads/nyarlathotep/`.
4. Confirm the destination file exists and is non-empty, then remove the
   temporary directory.

To attach a file from another host, copy it to a unique temporary directory on
`miskatonic`. Create the draft with `compose --draft --attach <path>` or
`reply --draft --attach <path>`, and remove the temporary file only after the
draft command succeeds. Repeat `--attach` for multiple files.

The CLI cannot add or remove files on an existing draft. `hey draft edit` can
change only recipients, subject, and body. `hey draft show` also omits attachment
metadata, so do not claim to have re-verified stored attachments with it. If
Felipe asks to change a draft's files, explain the limitation before offering to
recreate the draft.

Never use `attachment save --force` unless Felipe explicitly wants to replace
the destination. Never send a draft as part of an attachment check.

## Reporting

Lead with the result. For reads, give a compact summary and enough identifiers
for the next action. For mutations, name the action, affected sender or subject,
and whether it is reversible. For drafts, include the draft ID and state plainly
that nothing was sent. For downloaded files, provide a clickable absolute path.
