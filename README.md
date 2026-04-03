# Jarvis -- Claude Code Foundation Kit

A clean, extensible foundation for persistent Claude Code sessions. Gives Claude a name (Jarvis), a personality (direct, no-bullshit), memory across conversations, session continuity, and safety guardrails. Rename it, reshape it, make it yours.

## What This Gives You

**Session Continuity** -- Claude remembers what happened last session and picks up where you left off.
- `/boot` loads previous session state and priorities
- `/debrief` saves everything before you close
- Automatic state preservation when context compression happens

**Memory** -- Claude builds up knowledge about you, your projects, and your preferences over time using its built-in auto-memory system.

**Safety Hooks** -- Automatic guardrails that run before dangerous operations:
- Blocks accidentally exposed secrets in commands
- Protects critical config files from autonomous modification
- Catches destructive operations (rm -rf, git reset --hard) with confirmation
- Warns when context compression is approaching

**Extensibility** -- Clean foundation to add your own skills, hooks, and workflows.

## Quick Start

```bash
# Clone or download this kit, then:
bash setup.sh

# Open Claude Code and boot up:
/boot
```

## Skills (Slash Commands)

| Command | What It Does |
|---------|-------------|
| `/boot` | Load last session, present status, set priorities |
| `/dash` | Quick health check (cheap -- reads pre-loaded JSON) |
| `/debrief` | End session: save state, write continuation prompt, log session |

**Internal skills** (auto-invoked by the system, not typed manually):
- `state-update` -- Updates state files after system changes
- `pre-compact` -- Saves state before context compression
- `lesson-capture` -- Records lessons learned

## Trigger Words

Type these anywhere and Claude will invoke the corresponding skill:
- **BOOT** -- runs `/boot`
- **STATUS** or **DASH** -- runs `/dash`
- **DEBRIEF** -- runs `/debrief`

## File Layout

```
~/.claude-state/              # Persistent state (the "brain")
  system-state.json           # System registry
  last-session.json           # Session handoff data
  continuation-prompt.md      # THE boot file (next session reads this first)
  lessons.md                  # Accumulated lessons
  decisions.md                # Decision rationale log
  sessions/                   # Daily session logs (YYYY-MM-DD.md)

~/.claude/skills/             # Skills (slash commands)
  boot/skill.md
  debrief/skill.md
  dash/skill.md
  state-update/skill.md
  pre-compact/skill.md
  lesson-capture/skill.md

~/.claude/hooks/              # Auto-firing shell scripts
  safety-guard.sh             # Pre-tool: blocks secrets, protects paths
  session-save.sh             # SessionEnd/PreCompact: saves state
  session-restore.sh          # SessionStart: restores context after /clear
  compact-verify.sh           # PostCompact: checks context survived
  tool-counter.sh             # PostTool: tracks usage, warns on compression

~/CLAUDE.md                   # Core directives (customize this!)
```

## How It Works

### The Persistence Loop

```
Session Start ──> /boot reads continuation-prompt.md
                     │
                     ▼
              You work with Claude
                     │
                     ▼
              /debrief writes:
              - continuation-prompt.md (for next boot)
              - last-session.json (structured handoff)
              - system-state.json (registry update)
              - session log entry
                     │
                     ▼
Session End ──> Hooks save emergency state if you forget /debrief
```

### Context Compression Protection

Claude Code has a finite context window. When it fills up, older context gets compressed (summarized). This can lose important details. The kit protects against this:

1. **tool-counter.sh** tracks how many tool calls have been made and warns at 75, 120, and 140
2. **session-save.sh** fires automatically on PreCompact to save state
3. **compact-verify.sh** fires after compression to check if critical context survived
4. **pre-compact skill** gives Claude instructions for what to save

### Safety Hooks

Every Bash command, file edit, and file write passes through `safety-guard.sh` first:
- Regex scan for API keys, tokens, and private keys
- Protected path check (won't autonomously edit settings.json, .claude.json)
- Destructive operation guard (requires you to try twice for rm -rf, resets)

## Customizing

### Add Your Own Skills

Create `~/.claude/skills/my-skill/skill.md`:
```yaml
---
name: my-skill
description: "What this skill does"
user-invocable: true
---

# My Skill

## Live Data Injection
!`cat some-file.json`

## Instructions
Tell Claude what to do with the data above.
```

### Add Trigger Words

Edit `~/CLAUDE.md` and add rows to the trigger word table.

### Add More Hooks

1. Write a script in `~/.claude/hooks/`
2. Add it to `~/.claude/settings.json` under the appropriate event
3. Hook events: `UserPromptSubmit`, `PreToolUse`, `PostToolUse`, `Stop`, `PreCompact`, `PostCompact`, `SessionStart`, `SessionEnd`, `SubagentStart`, `SubagentStop`

### Modify Response Style

Edit the `RESPONSE FORMAT` section of `~/CLAUDE.md`. This is where you'd add personality, tone preferences, or domain-specific instructions.

## Env Vars (in settings.json)

| Variable | Value | What It Does |
|----------|-------|-------------|
| `CLAUDE_CODE_EFFORT_LEVEL` | `max` | Maximum reasoning effort per turn |
| `CLAUDE_CODE_DISABLE_PRECOMPACT_SKIP` | `1` | Ensures PreCompact hooks always fire |
| `CLAUDE_CODE_RESUME_INTERRUPTED_TURN` | `1` | Auto-resumes after crash |

## Troubleshooting

**Skills not showing up?** Make sure each skill is at `~/.claude/skills/<name>/skill.md` (exact structure matters).

**Hooks not firing?** Check `~/.claude/settings.json` has the hooks configured. Run `cat ~/.claude/settings.json | jq .hooks` to verify.

**State files empty?** Run `/debrief` to populate them, or `/boot` to check what exists.

**Context getting compressed too fast?** Avoid reading large files in full. Use `offset` and `limit` parameters. Delegate bulk reading to agents.
