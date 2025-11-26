#!/bin/bash

# ───────────────────────────────────────────────────────────────
# SEMANTIC SEARCH SUGGESTION HOOK
# ───────────────────────────────────────────────────────────────
# Pre-UserPromptSubmit hook that reminds AI to use semantic search
# MCP tools when analyzing or exploring code
#
# PERFORMANCE TARGET: <50ms (lightweight pattern matching)
# COMPATIBILITY: Bash 3.2+ (macOS and Linux compatible)
#
# EXECUTION ORDER: UserPromptSubmit hook (runs BEFORE user prompt processing)
#   1. UserPromptSubmit hooks run FIRST (before processing user input)
#   2. PreToolUse hooks run SECOND (before tool execution, validation)
#   3. PostToolUse hooks run LAST (after tool completion, verification)
#   This hook: Reminds AI to use semantic search for code exploration
#
# EXIT CODE CONVENTION:
#   0 = Allow (hook passed, continue execution)
#   1 = Block (hook failed, stop execution with warning)
#   2 = Error (reserved for critical failures)
# ───────────────────────────────────────────────────────────────

# Source output helpers (completely silent on success)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
HOOKS_DIR="$(cd "$SCRIPT_DIR/.." 2>/dev/null && pwd)"
source "$HOOKS_DIR/lib/output-helpers.sh" || exit 0

# Logging configuration
LOG_DIR="$HOOKS_DIR/logs"
LOG_FILE="$LOG_DIR/$(basename "$0" .sh).log"

# Performance timing START
START_TIME=$(date +%s%N)

# Read JSON input from stdin
INPUT=$(cat)

# Extract the prompt from JSON (silent on error)
PROMPT=$(echo "$INPUT" | jq -r '.prompt // empty' 2>/dev/null)

# If no prompt found, allow it
if [ -z "$PROMPT" ]; then
  exit 0
fi

# Convert prompt to lowercase for case-insensitive matching
PROMPT_LOWER=$(echo "$PROMPT" | tr '[:upper:]' '[:lower:]')

# ───────────────────────────────────────────────────────────────
# TRIGGER PATTERNS
# ───────────────────────────────────────────────────────────────

# Keywords that suggest semantic search would be useful
CODE_EXPLORATION_KEYWORDS=(
  "find.*code"
  "find.*implementation"
  "find.*function"
  "find.*component"
  "where.*implement"
  "where.*handle"
  "where.*defined"
  "where is"
  "locate.*code"
  "locate.*function"
  "search.*codebase"
  "explore.*code"
  "how.*implement"
  "show.*implementation"
  "what.*handles"
  "which.*file"
  "which.*component"
  "look for"
  "understand.*code"
  "analyze.*code"
  "explain.*implementation"
)

# Check if prompt matches any exploration pattern
SHOULD_SUGGEST=false

for pattern in "${CODE_EXPLORATION_KEYWORDS[@]}"; do
  if echo "$PROMPT_LOWER" | grep -qE "$pattern"; then
    SHOULD_SUGGEST=true
    break
  fi
done

# ───────────────────────────────────────────────────────────────
# OUTPUT SUGGESTION
# ───────────────────────────────────────────────────────────────

if [ "$SHOULD_SUGGEST" = true ]; then
  echo "💡 Code exploration detected: Use semantic search MCP via Code Mode for intent-based discovery"
  echo "   📖 Docs: .claude/skills/mcp-semantic-search/SKILL.md & mcp-code-mode/SKILL.md"
fi

# Performance timing END
END_TIME=$(date +%s%N)
DURATION=$(( (END_TIME - START_TIME) / 1000000 ))
echo "[$(date '+%Y-%m-%d %H:%M:%S')] suggest-semantic-search.sh ${DURATION}ms" >> "$HOOKS_DIR/logs/performance.log"

# Always allow the prompt to proceed
exit 0
