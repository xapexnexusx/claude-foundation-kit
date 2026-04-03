---
name: pre-compact
description: "Emergency state save before context compression. Prevents session amnesia."
user-invocable: false
---

# Pre-Compact Emergency Save

Context compression is about to happen. Save everything critical NOW.

## Current Timestamp
!`date "+%Y-%m-%dT%H:%M:%S%z"`

## Current Continuation Prompt
!`cat ~/.claude-state/continuation-prompt.md 2>/dev/null || echo 'none'`

## Current Last Session
!`cat ~/.claude-state/last-session.json 2>/dev/null || echo '{}'`

## Instructions

This fires before context compression wipes working memory. Act fast.

1. **Write continuation-prompt.md** with everything the post-compression session needs:
   - What was being worked on RIGHT NOW
   - What's already done
   - What's left to do
   - Key file paths and context
   - Any decisions made this session

2. **Update last-session.json** with current progress (even if mid-task).

3. **Append to session log** (`~/.claude-state/sessions/[YYYY-MM-DD].md`) with a note that this was a mid-session checkpoint.

The goal: if context compression loses everything, the continuation-prompt.md alone should be enough to pick up where you left off.
