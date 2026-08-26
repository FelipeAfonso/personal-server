#!/usr/bin/env python3
"""Stop hook: refuse to end a turn whose reply skipped the unslop skill.

Scans the transcript for a Skill tool call with skill == "unslop" after the
last real user prompt. If none is found and the turn produced a non-trivial
amount of assistant text, emit a block decision so the model invokes the
skill and rewrites before the reply ships.

Fail-open by design: any parse problem, a missing transcript, or a missing
skill directory lets the turn end normally. stop_hook_active guards against
a block loop, so a turn is bounced at most once.
"""

import json
import os
import sys

# One-liner acks aren't worth a bounce; only gate replies with real prose.
MIN_TEXT_CHARS = 200

BLOCK_REASON = (
    "The unslop skill was not invoked this turn. Per the global writing rule, "
    'call Skill(skill: "unslop"), audit your reply against its pattern list, '
    "then send the cleaned-up final message."
)


def main() -> None:
    try:
        data = json.load(sys.stdin)
    except (json.JSONDecodeError, ValueError):
        return

    if data.get("stop_hook_active"):
        return

    if not os.path.isdir(os.path.expanduser("~/.claude/skills/unslop")):
        return

    path = data.get("transcript_path")
    if not path or not os.path.isfile(path):
        return

    entries = []
    try:
        with open(path, encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if line:
                    try:
                        entries.append(json.loads(line))
                    except json.JSONDecodeError:
                        pass
    except OSError:
        return

    # Last real user prompt: a user entry whose content is plain text,
    # not tool results flowing back to the model.
    last_user = None
    for i, entry in enumerate(entries):
        if entry.get("type") != "user":
            continue
        content = (entry.get("message") or {}).get("content")
        if isinstance(content, str):
            last_user = i
        elif isinstance(content, list) and not any(
            isinstance(b, dict) and b.get("type") == "tool_result" for b in content
        ):
            last_user = i
    if last_user is None:
        return

    text_chars = 0
    for entry in entries[last_user + 1 :]:
        if entry.get("type") != "assistant":
            continue
        for block in (entry.get("message") or {}).get("content") or []:
            if not isinstance(block, dict):
                continue
            if (
                block.get("type") == "tool_use"
                and block.get("name") == "Skill"
                and (block.get("input") or {}).get("skill") == "unslop"
            ):
                return
            if block.get("type") == "text":
                text_chars += len(block.get("text") or "")

    if text_chars < MIN_TEXT_CHARS:
        return

    print(json.dumps({"decision": "block", "reason": BLOCK_REASON}))


if __name__ == "__main__":
    main()
