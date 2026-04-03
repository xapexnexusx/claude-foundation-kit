---
name: debrief
description: "End-of-session protocol. Saves all state files, writes continuation prompt, logs session."
user-invocable: true
argument-hint: "[optional: brief summary of what this session accomplished]"
---

# Debrief Protocol

Save everything the next session needs to continue seamlessly.

## Current Timestamp
!`date "+%Y-%m-%dT%H:%M:%S%z"`

## Current System State
!`cat ~/.claude-state/system-state.json 2>/dev/null || echo '{}'`

## Current Last Session
!`cat ~/.claude-state/last-session.json 2>/dev/null || echo '{}'`

## Instructions

Write ALL of the following files. Every one is required.

### 1. continuation-prompt.md (THE BOOT FILE)
Write to `~/.claude-state/continuation-prompt.md`. This is the most critical file -- the next session reads it first.

Format:
```markdown
# CONTINUATION -- Session [N+1] Boot
**Updated:** [timestamp]
**Previous:** Session [N] ([name])
**Status:** [one-line system health]

## CRITICAL -- READ THIS FIRST
[2-3 sentences the next session absolutely must know]

## WHAT SESSION [N] DID
1. [Numbered list of accomplishments]

## FIRST THING -- Session [N+1]
[Exactly what to do on boot. Specific. Actionable. Ordered.]

## KEY REFERENCES
[File paths the next session will need]
```

### 2. last-session.json
Write to `~/.claude-state/last-session.json`:
```json
{
  "session_number": N,
  "session_name": "descriptive name",
  "timestamp": "ISO-8601",
  "tasks_completed": ["what got done"],
  "decisions_made": ["key decisions with brief rationale"],
  "next_actions": ["what next session should do FIRST"],
  "files_changed": ["paths of modified files"]
}
```

### 3. system-state.json
Update `~/.claude-state/system-state.json`:
- Increment version
- Update `last_updated` timestamp
- Update `session_count`
- Update `session_summary` with what this session did
- Add/update any sections that changed

### 4. Session Log
Append to `~/.claude-state/sessions/[YYYY-MM-DD].md`:
```markdown
## Session [N]: [Name]
**Time:** [timestamp]

### Built
- [what was created or modified]

### Decisions
- [key decisions with rationale]

### Next
- [priorities for next session]
```

Create the sessions directory if it doesn't exist: `mkdir -p ~/.claude-state/sessions/`

### 5. Lessons (if applicable)
If anything was learned this session, append to `~/.claude-state/lessons.md`.

### Completion
After writing all files, confirm:
- continuation-prompt.md written
- last-session.json written
- system-state.json updated
- Session log appended
- Next session priorities are clear
