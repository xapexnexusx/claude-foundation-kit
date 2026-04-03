#!/usr/bin/env bash
# tool-counter.sh -- Post-tool usage tracking hook
# Event: PostToolUse (all tools)
# Purpose: Track tool call count and warn when context compression approaches
#
# What it does:
#   1. Increments a per-session tool call counter
#   2. At 75 calls: gentle reminder to save state
#   3. At 120 calls: urgent warning
#   4. At 140+ calls: triggers emergency state save

set -euo pipefail

INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "default"')

# Use /tmp for the counter (resets on reboot, which is fine -- it's per-session)
COUNTER_FILE="/tmp/claude-tool-count-${SESSION_ID}"

# Increment counter
if [[ -f "$COUNTER_FILE" ]]; then
    COUNT=$(cat "$COUNTER_FILE")
    COUNT=$((COUNT + 1))
else
    COUNT=1
fi
echo "$COUNT" > "$COUNTER_FILE"

# Thresholds
if (( COUNT == 75 )); then
    echo "{\"decision\":\"allow\",\"message\":\"Tool call #75. Consider saving your work state soon (invoke state-update skill). Context compression may occur in the next 50-70 calls.\"}"
elif (( COUNT == 120 )); then
    echo "{\"decision\":\"allow\",\"message\":\"Tool call #120. Context compression is likely soon. Save state now if you haven't already. Run /debrief if wrapping up, or the pre-compact skill will fire automatically.\"}"
elif (( COUNT >= 140 )); then
    # Write emergency checkpoint
    STATE_DIR="$HOME/.claude-state"
    TIMESTAMP=$(date "+%Y-%m-%dT%H:%M:%S%z")

    if [[ -f "$STATE_DIR/last-session.json" ]]; then
        UPDATED=$(jq --arg ts "$TIMESTAMP" --arg tc "$COUNT" \
            '. + {"emergency_checkpoint": true, "emergency_checkpoint_at": $ts, "emergency_tool_count": ($tc | tonumber)}' \
            "$STATE_DIR/last-session.json")
        echo "$UPDATED" > "$STATE_DIR/last-session.json"
    fi

    echo "{\"decision\":\"allow\",\"message\":\"EMERGENCY: Tool call #$COUNT. Context compression is imminent. Writing emergency checkpoint to last-session.json.\"}"
else
    echo '{"decision":"allow"}'
fi
