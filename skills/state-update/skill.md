---
name: state-update
description: "Update state files after system changes. Internal skill."
user-invocable: false
---

# State Update

Triggered after any significant system change (new capability, config change, file structure change).

## Current State
!`cat ~/.claude-state/system-state.json 2>/dev/null || echo '{}'`

## Current Timestamp
!`date "+%Y-%m-%dT%H:%M:%S%z"`

## Instructions

1. **Update system-state.json:**
   - Increment `version` (e.g., "1.0" -> "1.1")
   - Set `last_updated` to current timestamp
   - Update `session_summary` to reflect what changed
   - Add/modify sections as needed for new capabilities or changes
   - Write to `~/.claude-state/system-state.json`

2. **Update last-session.json:**
   - Add the change to `tasks_completed`
   - Add any modified files to `files_changed`
   - Write to `~/.claude-state/last-session.json`

3. **Confirm** the updates were written successfully.

Keep updates minimal and accurate. Don't rewrite the entire file -- just update what changed.
