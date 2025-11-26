#!/bin/bash

# ───────────────────────────────────────────────────────────────
# TASK DISPATCH ANNOUNCEMENT HOOK
# ───────────────────────────────────────────────────────────────
# PreToolUse hook that displays agent launch information before
# Task tool executes. Provides visibility into sub-agent dispatch.
#
# DISPLAY LOGIC (Expandable Default):
#   - 1-2 agents: Compact single-line format
#   - 3+ agents OR error: Full verbose box
#
# PERFORMANCE TARGET: <30ms
# COMPATIBILITY: Bash 3.2+ (macOS and Linux compatible)
#
# EXIT CODE: Always 0 (informational only, never blocks Task tool)
# ───────────────────────────────────────────────────────────────

# Script setup
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
HOOKS_DIR="$(cd "$SCRIPT_DIR/.." 2>/dev/null && pwd)"

# Source libraries (silent failures - hook should not block on missing libs)
source "$HOOKS_DIR/lib/output-helpers.sh" 2>/dev/null || true
source "$HOOKS_DIR/lib/agent-tracking.sh" 2>/dev/null || true

# Logging
LOG_FILE="$HOOKS_DIR/logs/task-dispatch.log"

# Performance timing
START_TIME=$(date +%s%N 2>/dev/null || date +%s)

# Read JSON input from stdin
INPUT=$(cat)

# Extract tool name
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null)

# Only process Task tool calls
if [ "$TOOL_NAME" != "Task" ]; then
  exit 0
fi

# Extract Task tool parameters
DESCRIPTION=$(echo "$INPUT" | jq -r '.tool_input.description // "Sub-agent"' 2>/dev/null)
MODEL=$(echo "$INPUT" | jq -r '.tool_input.model // "inherit"' 2>/dev/null)
TIMEOUT=$(echo "$INPUT" | jq -r '.tool_input.timeout // 300000' 2>/dev/null)
SUBAGENT_TYPE=$(echo "$INPUT" | jq -r '.tool_input.subagent_type // "general-purpose"' 2>/dev/null)
PROMPT=$(echo "$INPUT" | jq -r '.tool_input.prompt // ""' 2>/dev/null)

# Generate agent ID and track
AGENT_ID=$(generate_agent_id 2>/dev/null || echo "agent_$(date +%s)")
start_agent_tracking "$AGENT_ID" "$DESCRIPTION" "$MODEL" "$TIMEOUT" 2>/dev/null || true

# Get current session agent count for display logic
AGENT_COUNT=$(get_agent_count 2>/dev/null)
# Ensure AGENT_COUNT is a valid number (default to 1)
if ! [[ "$AGENT_COUNT" =~ ^[0-9]+$ ]]; then
  AGENT_COUNT=1
fi

# Convert timeout to human-readable
format_timeout() {
  local ms="$1"
  local seconds=$((ms / 1000))
  if [ "$seconds" -ge 60 ]; then
    echo "$((seconds / 60)) min"
  else
    echo "${seconds}s"
  fi
}

TIMEOUT_HUMAN=$(format_timeout "$TIMEOUT")

# Truncate description if too long (max 50 chars for compact)
truncate_text() {
  local text="$1"
  local max="$2"
  if [ ${#text} -gt $max ]; then
    echo "${text:0:$((max-3))}..."
  else
    echo "$text"
  fi
}

DESC_SHORT=$(truncate_text "$DESCRIPTION" 50)

# ───────────────────────────────────────────────────────────────
# DISPLAY OUTPUT
# ───────────────────────────────────────────────────────────────

# Display logic: Compact for 1-2 agents, Verbose for 3+
if [ "$AGENT_COUNT" -lt 3 ]; then
  # ─────────────────────────────────────────────────────────────
  # COMPACT FORMAT (1-2 agents)
  # ─────────────────────────────────────────────────────────────
  {
    echo ""
    echo "🚀 Launching: ${SUBAGENT_TYPE} (${MODEL}) → \"${DESC_SHORT}\""
    echo ""
  } >&2

else
  # ─────────────────────────────────────────────────────────────
  # VERBOSE FORMAT (3+ agents)
  # ─────────────────────────────────────────────────────────────

  # Truncate prompt for preview (first 100 chars)
  PROMPT_PREVIEW=$(echo "$PROMPT" | head -c 100 | tr '\n' ' ')
  if [ ${#PROMPT} -gt 100 ]; then
    PROMPT_PREVIEW="${PROMPT_PREVIEW}..."
  fi

  {
    echo ""
    echo "┌─────────────────────────────────────────────────────────────┐"
    echo "│ 🚀 PARALLEL DISPATCH (Agent #${AGENT_COUNT})                          │"
    echo "├─────────────────────────────────────────────────────────────┤"
    printf "│ %-59s │\n" "${AGENT_COUNT}. ${SUBAGENT_TYPE} (${MODEL}, ${TIMEOUT_HUMAN})"
    printf "│    └─ %-54s │\n" "\"${DESC_SHORT}\""
    echo "│                                                             │"
    if [ -n "$PROMPT_PREVIEW" ]; then
      echo "│ Task Preview:                                               │"
      printf "│ > %-57s │\n" "$PROMPT_PREVIEW"
      echo "│                                                             │"
    fi
    echo "│ ⏳ Executing...                                             │"
    echo "└─────────────────────────────────────────────────────────────┘"
    echo ""
  } >&2
fi

# Log for debugging
mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null
{
  END_TIME=$(date +%s%N 2>/dev/null || date +%s)
  if [ ${#START_TIME} -gt 10 ]; then
    DURATION=$(( (END_TIME - START_TIME) / 1000000 ))
  else
    DURATION=0
  fi
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] DISPATCH agent=$AGENT_ID type=$SUBAGENT_TYPE model=$MODEL count=$AGENT_COUNT duration=${DURATION}ms"
} >> "$LOG_FILE" 2>/dev/null

# Store agent_id for PostToolUse hook to find
# Use a simple mapping file since we can't modify the tool input
echo "$DESCRIPTION|$AGENT_ID" >> "/tmp/claude_hooks_state/agent_description_map.txt" 2>/dev/null

# Always allow Task tool to proceed
exit 0
