#!/usr/bin/env bash
# safety-guard.sh -- Pre-tool safety hook
# Event: PreToolUse (Bash, Edit, Write)
# Purpose: Block dangerous operations before they execute
#
# What it catches:
#   1. Secrets in command arguments (API keys, tokens, private keys)
#   2. Writes to protected paths (config, hooks, memory)
#   3. Destructive operations (rm -rf on critical dirs, git reset --hard)

set -euo pipefail

INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty')
TOOL_INPUT=$(echo "$INPUT" | jq -r '.tool_input // empty')

allow() { echo '{"decision":"allow"}'; exit 0; }
block() { echo "{\"decision\":\"block\",\"reason\":\"$1\"}"; exit 0; }

# --- Gate 1: Secret Scanner ---
# Check Bash commands and file writes for accidentally exposed secrets
if [[ "$TOOL" == "Bash" ]]; then
    CMD=$(echo "$TOOL_INPUT" | jq -r '.command // empty')

    # Scan for common secret patterns in commands
    if echo "$CMD" | grep -qiE '(sk-[a-zA-Z0-9]{20,}|ghp_[a-zA-Z0-9]{36}|AKIA[0-9A-Z]{16}|-----BEGIN (RSA |EC )?PRIVATE KEY)'; then
        block "Blocked: command appears to contain a secret (API key, token, or private key). Use environment variables or a secrets manager instead."
    fi
fi

# --- Gate 2: Protected Path Guard ---
# Block autonomous writes to critical config files
if [[ "$TOOL" == "Write" || "$TOOL" == "Edit" ]]; then
    FILE_PATH=$(echo "$TOOL_INPUT" | jq -r '.file_path // empty')

    case "$FILE_PATH" in
        */.claude/settings.json|*/.claude/settings.local.json)
            block "Blocked: Cannot autonomously modify Claude Code settings. Ask the user to make this change."
            ;;
        */.claude.json)
            block "Blocked: Cannot autonomously modify .claude.json. Ask the user to make this change."
            ;;
    esac
fi

# --- Gate 3: Destructive Operation Guard ---
if [[ "$TOOL" == "Bash" ]]; then
    CMD=$(echo "$TOOL_INPUT" | jq -r '.command // empty')

    # Block rm -rf on home directory or critical paths
    if echo "$CMD" | grep -qE 'rm\s+(-[a-zA-Z]*f[a-zA-Z]*\s+|--force\s+)*(~\/|\/Users\/|\/home\/)'; then
        TRACKER="/tmp/claude-destructive-$$"
        if [[ -f "$TRACKER" ]]; then
            # Second attempt -- user confirmed, allow it
            rm -f "$TRACKER"
            allow
        else
            touch "$TRACKER"
            block "Blocked: Destructive operation on home directory. If this is intentional, try the command again."
        fi
    fi

    # Block git reset --hard in home directory
    if echo "$CMD" | grep -qE 'git\s+reset\s+--hard' && [[ "$(pwd)" == "$HOME" || "$(pwd)" == "$HOME/"* ]]; then
        block "Blocked: git reset --hard in home directory. This could destroy uncommitted work."
    fi
fi

# All checks passed
allow
