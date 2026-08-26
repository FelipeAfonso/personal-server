#!/usr/bin/env bash
# UserPromptSubmit hook: inject the unslop rule into context on every turn.
# The Stop gate (unslop-stop-gate.py) enforces compliance; this reminder makes
# the first attempt comply so the gate rarely has to bounce a reply.
cat <<'EOF'
{"hookSpecificOutput":{"hookEventName":"UserPromptSubmit","additionalContext":"Standing rule from Felipe's config: before writing this turn's final reply, invoke the unslop skill (Skill tool, skill: unslop) and audit all user-facing prose against its pattern list. A Stop hook verifies the invocation and bounces the reply if it is missing."},"suppressOutput":true}
EOF
