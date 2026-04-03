#!/usr/bin/env bash
# session-save.sh -- Session state preservation hook
# Events: SessionEnd (clear), PreCompact
# Purpose: Save critical state before context is lost
#
# Fires when:
#   - User runs /clear (SessionEnd)
#   - Context compression is about to happen (PreCompact)
#
# What it does:
#   1. Updates last-session.json with a cleared_at/compacted_at timestamp
#   2. Creates sessions directory if needed
#   3. Ensures continuation-prompt.md exists

set -euo pipefail

INPUT=$(cat)
EVENT=$(echo "$INPUT" | jq -r '.type // .event // "unknown"')

STATE_DIR="$HOME/.claude-state"
SESSIONS_DIR="$STATE_DIR/sessions"
TIMESTAMP=$(date "+%Y-%m-%dT%H:%M:%S%z")
TODAY=$(date "+%Y-%m-%d")

# Ensure directories exist
mkdir -p "$SESSIONS_DIR"

# Update last-session.json with preservation timestamp
LAST_SESSION="$STATE_DIR/last-session.json"
if [[ -f "$LAST_SESSION" ]]; then
    if echo "$EVENT" | grep -qi "compact"; then
        UPDATED=$(jq --arg ts "$TIMESTAMP" '. + {"compacted_at": $ts}' "$LAST_SESSION")
    else
        UPDATED=$(jq --arg ts "$TIMESTAMP" '. + {"cleared_at": $ts}' "$LAST_SESSION")
    fi
    echo "$UPDATED" > "$LAST_SESSION"
fi

# If no continuation-prompt.md exists, create a minimal one
CONT_PROMPT="$STATE_DIR/continuation-prompt.md"
if [[ ! -f "$CONT_PROMPT" ]]; then
    cat > "$CONT_PROMPT" << EOF
# CONTINUATION -- Recovery Boot
**Updated:** $TIMESTAMP
**Status:** Session ended without debrief. State may be incomplete.

## FIRST THING
1. Check ~/.claude-state/last-session.json for context
2. Check the session log at ~/.claude-state/sessions/$TODAY.md
3. Ask the user what they'd like to continue with
EOF
fi

echo '{"decision":"allow"}'
