#!/usr/bin/env bash
# compact-verify.sh -- Post-compaction verification hook
# Event: PostCompact
# Purpose: Check if critical context survived context compression
#
# What it does:
#   1. Reads the compact summary to see what survived
#   2. Checks if continuation-prompt.md is fresh (written recently)
#   3. Writes a recovery hint if critical context appears lost

set -euo pipefail

INPUT=$(cat)
STATE_DIR="$HOME/.claude-state"
CONT_PROMPT="$STATE_DIR/continuation-prompt.md"
RECOVERY="$STATE_DIR/recovery-hint.md"
TIMESTAMP=$(date "+%Y-%m-%dT%H:%M:%S%z")

# Check if continuation prompt is fresh (modified within last 10 minutes)
PROMPT_FRESH=false
if [[ -f "$CONT_PROMPT" ]]; then
    if [[ "$(uname)" == "Darwin" ]]; then
        MOD_TIME=$(stat -f %m "$CONT_PROMPT")
    else
        MOD_TIME=$(stat -c %Y "$CONT_PROMPT")
    fi
    NOW=$(date +%s)
    AGE=$(( NOW - MOD_TIME ))
    if (( AGE < 600 )); then
        PROMPT_FRESH=true
    fi
fi

# If continuation prompt is stale, write a recovery hint
if [[ "$PROMPT_FRESH" != "true" ]]; then
    cat > "$RECOVERY" << EOF
# RECOVERY HINT
**Generated:** $TIMESTAMP
**Reason:** Context compression occurred and continuation-prompt.md appears stale.

## Action Required
The session's working memory was compressed. If context was lost:
1. Read ~/.claude-state/continuation-prompt.md for last known state
2. Read ~/.claude-state/last-session.json for session details
3. Check ~/.claude-state/sessions/ for recent session logs
4. Ask the user to re-state what they were working on
EOF
fi

echo '{"decision":"allow"}'
