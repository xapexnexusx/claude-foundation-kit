#!/usr/bin/env bash
# session-restore.sh -- Session context restoration hook
# Event: SessionStart (after clear)
# Purpose: Inject continuation context into fresh session after /clear
#
# What it does:
#   Reads continuation-prompt.md and injects it so the new session
#   has context about what was happening before the clear.

set -euo pipefail

CONT_PROMPT="$HOME/.claude-state/continuation-prompt.md"

if [[ -f "$CONT_PROMPT" ]]; then
    CONTENT=$(cat "$CONT_PROMPT")
    # Escape for JSON
    ESCAPED=$(echo "$CONTENT" | jq -Rs .)
    echo "{\"decision\":\"allow\",\"message\":$ESCAPED}"
else
    echo '{"decision":"allow","message":"No continuation prompt found. This appears to be a fresh start."}'
fi
