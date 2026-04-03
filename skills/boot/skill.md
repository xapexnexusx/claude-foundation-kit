---
name: boot
description: "Session initialization. Loads last session state, presents status, sets priorities."
user-invocable: true
---

# Boot Protocol

Load previous session context and establish priorities for this session.

## Current Timestamp
!`date "+%Y-%m-%dT%H:%M:%S%z"`

## System State
!`cat ~/.claude-state/system-state.json 2>/dev/null || echo '{"error": "No system-state.json found. Fresh install."}'`

## Last Session
!`cat ~/.claude-state/last-session.json 2>/dev/null || echo '{"error": "No last-session.json found. Fresh install."}'`

## Continuation Prompt
!`cat ~/.claude-state/continuation-prompt.md 2>/dev/null || echo 'No continuation prompt found. This appears to be the first session.'`

## Instructions

After loading the above context:

1. **Identify yourself by session number.** Increment `session_number` from last-session.json.
2. **Present a 3-line status:**
   - Line 1: Session number and name (infer from continuation prompt or make one)
   - Line 2: System state (healthy/issues)
   - Line 3: Top priority for this session
3. **State what you're going to work on** based on the `next_actions` from last-session.json and the continuation prompt.
4. If this is the first boot (no state files), welcome the user and explain the system briefly.

Keep the boot output concise. The user wants to get to work, not read a report.
