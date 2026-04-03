---
name: lesson-capture
description: "Capture a lesson learned or pattern discovered. Appends to lessons.md."
user-invocable: false
argument-hint: "[lesson description]"
---

# Lesson Capture

## Current Timestamp
!`date "+%Y-%m-%dT%H:%M:%S%z"`

## Recent Lessons
!`tail -20 ~/.claude-state/lessons.md 2>/dev/null || echo 'No lessons yet'`

## Instructions

Append the lesson to `~/.claude-state/lessons.md` at the TOP (below the header). Format:

```markdown
## [YYYY-MM-DD] LESSON TITLE
What happened, what was learned, what to do differently next time.
---
```

Guidelines:
- Be specific. "TypeScript builds fail silently when X" is useful. "Be careful with builds" is not.
- Include the context that makes the lesson actionable in a future session.
- Check recent lessons first to avoid duplicates.
- If this updates an existing lesson, edit that entry instead of creating a new one.
