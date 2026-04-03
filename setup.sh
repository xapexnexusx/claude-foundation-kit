#!/usr/bin/env bash
# Claude Code Foundation Kit -- Setup Script
# Installs skills, hooks, state files, and configures settings.json
#
# Usage:
#   bash setup.sh           # Safe mode -- won't overwrite existing files
#   bash setup.sh --force   # Full install -- overwrites everything
#
# For a fresh Claude Code install, use --force.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
STATE_DIR="$HOME/.claude-state"
SKILLS_DIR="$CLAUDE_DIR/skills"
HOOKS_DIR="$CLAUDE_DIR/hooks"
SETTINGS="$CLAUDE_DIR/settings.json"

FORCE=false
if [[ "${1:-}" == "--force" ]]; then
    FORCE=true
fi

echo "=== Jarvis -- Claude Code Foundation Kit ==="
if $FORCE; then
    echo "Mode: FULL INSTALL (overwriting existing files)"
else
    echo "Mode: Safe (skipping existing files. Use --force to overwrite)"
fi
echo ""

# --- Create directories ---
echo "[1/6] Creating directories..."
mkdir -p "$STATE_DIR/sessions"
mkdir -p "$SKILLS_DIR"
mkdir -p "$HOOKS_DIR"
mkdir -p "$CLAUDE_DIR/projects"
echo "  OK"

# --- Install state files ---
echo "[2/6] Installing state files..."
for f in system-state.json last-session.json continuation-prompt.md lessons.md decisions.md; do
    TARGET="$STATE_DIR/$f"
    if $FORCE || [[ ! -f "$TARGET" ]]; then
        cp "$SCRIPT_DIR/state/$f" "$TARGET"
        echo "  Installed: $TARGET"
    else
        echo "  Exists (skipped): $TARGET"
    fi
done

# --- Install skills ---
echo "[3/6] Installing skills..."
for skill_dir in "$SCRIPT_DIR/skills"/*/; do
    SKILL_NAME=$(basename "$skill_dir")
    TARGET_DIR="$SKILLS_DIR/$SKILL_NAME"
    mkdir -p "$TARGET_DIR"
    if $FORCE || [[ ! -f "$TARGET_DIR/skill.md" ]]; then
        cp "$skill_dir/skill.md" "$TARGET_DIR/skill.md"
        echo "  Installed: /$SKILL_NAME"
    else
        echo "  Exists (skipped): /$SKILL_NAME"
    fi
done

# --- Install hooks ---
echo "[4/6] Installing hooks..."
for hook in "$SCRIPT_DIR/hooks"/*.sh; do
    HOOK_NAME=$(basename "$hook")
    TARGET="$HOOKS_DIR/$HOOK_NAME"
    if $FORCE || [[ ! -f "$TARGET" ]]; then
        cp "$hook" "$TARGET"
        chmod +x "$TARGET"
        echo "  Installed: $HOOK_NAME"
    else
        echo "  Exists (skipped): $HOOK_NAME"
    fi
done

# --- Configure settings.json ---
echo "[5/6] Configuring settings.json..."

# Our hooks and env config as a JSON string
FOUNDATION_CONFIG='{
  "env": {
    "CLAUDE_CODE_EFFORT_LEVEL": "max",
    "CLAUDE_CODE_DISABLE_PRECOMPACT_SKIP": "1",
    "CLAUDE_CODE_RESUME_INTERRUPTED_TURN": "1"
  },
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [{ "type": "command", "command": "bash ~/.claude/hooks/safety-guard.sh" }]
      },
      {
        "matcher": "Edit",
        "hooks": [{ "type": "command", "command": "bash ~/.claude/hooks/safety-guard.sh" }]
      },
      {
        "matcher": "Write",
        "hooks": [{ "type": "command", "command": "bash ~/.claude/hooks/safety-guard.sh" }]
      }
    ],
    "PostToolUse": [
      {
        "hooks": [{ "type": "command", "command": "bash ~/.claude/hooks/tool-counter.sh" }]
      }
    ],
    "SessionEnd": [
      {
        "matcher": "clear",
        "hooks": [{ "type": "command", "command": "bash ~/.claude/hooks/session-save.sh" }]
      }
    ],
    "SessionStart": [
      {
        "matcher": "clear",
        "hooks": [{ "type": "command", "command": "bash ~/.claude/hooks/session-restore.sh" }]
      }
    ],
    "PreCompact": [
      {
        "hooks": [{ "type": "command", "command": "bash ~/.claude/hooks/session-save.sh" }]
      }
    ],
    "PostCompact": [
      {
        "hooks": [{ "type": "command", "command": "bash ~/.claude/hooks/compact-verify.sh" }]
      }
    ]
  }
}'

if $FORCE || [[ ! -f "$SETTINGS" ]]; then
    # Fresh write (or forced overwrite)
    echo "$FOUNDATION_CONFIG" | jq '.' > "$SETTINGS"
    echo "  Installed: $SETTINGS"
elif ! command -v jq &>/dev/null; then
    echo "  settings.json exists but jq is not installed. Cannot auto-merge."
    echo "  Install jq (brew install jq) and re-run, or use --force to overwrite."
else
    # Merge into existing settings.json
    cp "$SETTINGS" "$SETTINGS.backup"
    echo "  Backed up existing settings to settings.json.backup"

    EXISTING=$(cat "$SETTINGS")
    MERGED=$(echo "$EXISTING" | jq --argjson new "$FOUNDATION_CONFIG" '
      .env = (($new.env // {}) + (.env // {})) |
      .hooks = (
        (.hooks // {}) as $existing_hooks |
        ($new.hooks // {}) as $new_hooks |
        ($existing_hooks | keys) + ($new_hooks | keys) | unique |
        map(. as $key | {
          ($key): (
            ($existing_hooks[$key] // []) +
            ([$new_hooks[$key] // [] | .[] |
              select(
                . as $new_hook |
                ($existing_hooks[$key] // []) |
                all(.hooks[0].command != $new_hook.hooks[0].command)
              )
            ])
          )
        }) | add // {}
      )
    ')

    echo "$MERGED" | jq '.' > "$SETTINGS"
    echo "  Merged hooks and env vars into existing settings.json"
fi

# --- Install CLAUDE.md ---
echo "[6/6] Installing CLAUDE.md..."
if $FORCE || [[ ! -f "$HOME/CLAUDE.md" ]]; then
    cp "$SCRIPT_DIR/CLAUDE.md" "$HOME/CLAUDE.md"
    echo "  Installed: ~/CLAUDE.md"
else
    echo "  ~/CLAUDE.md already exists (skipped). Use --force to overwrite."
fi

echo ""
echo "=== Installation Complete ==="
echo ""
echo "What's installed:"
echo "  State files:  $STATE_DIR/"
echo "  Skills:       $SKILLS_DIR/ (boot, debrief, dash, state-update, pre-compact, lesson-capture)"
echo "  Hooks:        $HOOKS_DIR/ (safety-guard, session-save, session-restore, compact-verify, tool-counter)"
echo "  Directives:   ~/CLAUDE.md"
echo ""
echo "Next steps:"
echo "  1. Open Claude Code and type: /boot"
echo "  2. Customize ~/CLAUDE.md with your preferences"
echo "  3. Start building -- the system learns and persists as you work"
echo "  4. End sessions with: DEBRIEF"
echo ""
echo "Memory system:"
echo "  Claude Code's built-in auto-memory will create MEMORY.md in"
echo "  ~/.claude/projects/<your-project>/memory/ as you work."
echo "  The kit includes an empty template at $SCRIPT_DIR/memory/MEMORY.md"
echo "  for reference."
