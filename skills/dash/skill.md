---
name: dash
description: "Quick system health dashboard. Cheap check from pre-loaded state."
user-invocable: true
---

# Dashboard

## Current Timestamp
!`date "+%Y-%m-%dT%H:%M:%S%z"`

## System State
!`cat ~/.claude-state/system-state.json 2>/dev/null || echo '{"error": "No system-state.json found"}'`

## Last Session
!`cat ~/.claude-state/last-session.json 2>/dev/null || echo '{"error": "No last-session.json found"}'`

## Continuation Prompt (first 20 lines)
!`head -20 ~/.claude-state/continuation-prompt.md 2>/dev/null || echo 'No continuation prompt found'`

## Recent Lessons (last 5)
!`tail -30 ~/.claude-state/lessons.md 2>/dev/null || echo 'No lessons file found'`

## Instructions

Present a concise dashboard:

```
SESSION [N] | [status] | [date]
Last: [what happened]
Next: [top priority]
Lessons: [count or "none yet"]
```

Keep it to 5 lines max. This is a quick health check, not a report.
If anything looks stale (last_updated > 24h ago), flag it.
