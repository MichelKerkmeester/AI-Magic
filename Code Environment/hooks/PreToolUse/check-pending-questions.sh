#!/bin/bash

# ───────────────────────────────────────────────────────────────
# CHECK PENDING QUESTIONS - PreToolUse Hook
# ───────────────────────────────────────────────────────────────
# STRICT MODE: Blocks ALL tool execution if a mandatory question
# is pending. Only AskUserQuestion is allowed (that's how user responds).
#
# Version: 1.0.0
# Created: 2025-11-25
#
# BEHAVIOR:
#   - When pending_question state exists:
#     - AskUserQuestion → ALLOW (clears pending state)
#     - All other tools → BLOCK with exit 1
#   - When no pending_question state:
#     - All tools → ALLOW
#
# STATE FILE: /tmp/claude_hooks_state/pending_question.json
# EXPIRY: 5 minutes (300 seconds)
#
# PERFORMANCE TARGET: <50ms
# COMPATIBILITY: Bash 3.2+ (macOS and Linux)
#
# EXIT CODE CONVENTION:
#   0 = Allow (tool execution proceeds)
#   1 = Block (tool execution stopped with user warning)
# ───────────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
HOOKS_DIR="$(cd "$SCRIPT_DIR/.." 2>/dev/null && pwd)"
LOG_DIR="$HOOKS_DIR/logs"
LOG_FILE="$LOG_DIR/check-pending-questions.log"

mkdir -p "$LOG_DIR" 2>/dev/null

# Source required libraries
source "$HOOKS_DIR/lib/shared-state.sh" 2>/dev/null || {
  # If shared-state.sh is missing, allow all tools (graceful degradation)
  exit 0
}

source "$HOOKS_DIR/lib/exit-codes.sh" 2>/dev/null || {
  # Fallback exit codes if library missing
  EXIT_ALLOW=0
  EXIT_BLOCK=1
}

source "$HOOKS_DIR/lib/output-helpers.sh" 2>/dev/null || {
  # Fallback output function if library missing
  print_error_box() {
    echo "❌ $1" >&2
    shift
    for line in "$@"; do
      echo "   $line" >&2
    done
  }
}

# Performance tracking
START_TIME=$(date +%s%N 2>/dev/null || date +%s)

# ───────────────────────────────────────────────────────────────
# READ INPUT
# ───────────────────────────────────────────────────────────────
INPUT=$(cat)

# Extract tool name from JSON input
TOOL_NAME=$(echo "$INPUT" | jq -r '.name // empty' 2>/dev/null)

# Early exit if no tool name (shouldn't happen, but be safe)
if [ -z "$TOOL_NAME" ]; then
  exit $EXIT_ALLOW
fi

# ───────────────────────────────────────────────────────────────
# ASKUSERQUESTION - ALWAYS ALLOWED
# ───────────────────────────────────────────────────────────────
# This is how the user responds to pending questions.
# When AskUserQuestion is used, clear the pending question state.
if [ "$TOOL_NAME" = "AskUserQuestion" ]; then
  # Clear pending question state (user is responding)
  clear_hook_state "pending_question" 2>/dev/null || true

  # Log the response
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] AskUserQuestion used - cleared pending_question state" >> "$LOG_FILE" 2>/dev/null

  exit $EXIT_ALLOW
fi

# ───────────────────────────────────────────────────────────────
# CHECK FOR PENDING QUESTION
# ───────────────────────────────────────────────────────────────
# Check if a mandatory question is pending (with 5-minute expiry)
QUESTION_EXPIRY=300  # 5 minutes in seconds

if has_hook_state "pending_question" "$QUESTION_EXPIRY"; then
  # Pending question exists and is not expired
  PENDING=$(read_hook_state "pending_question" "$QUESTION_EXPIRY" 2>/dev/null)

  # Extract question details for the error message
  QUESTION_TYPE=$(echo "$PENDING" | jq -r '.type // "UNKNOWN"' 2>/dev/null)
  QUESTION_TEXT=$(echo "$PENDING" | jq -r '.question // "Pending question"' 2>/dev/null)
  ASKED_AT=$(echo "$PENDING" | jq -r '.asked_at // "unknown"' 2>/dev/null)

  # Log the block
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] BLOCKED: $TOOL_NAME (pending: $QUESTION_TYPE)" >> "$LOG_FILE" 2>/dev/null

  # Output blocking message
  print_error_box "🔴 TOOL BLOCKED - Mandatory Question Pending" \
    "" \
    "Blocked Tool: $TOOL_NAME" \
    "Question Type: $QUESTION_TYPE" \
    "Asked At: $ASKED_AT" \
    "" \
    "Question: $QUESTION_TEXT" \
    "" \
    "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" \
    "YOU MUST answer the pending question before using any tools." \
    "" \
    "Use the AskUserQuestion tool to present options to the user." \
    "All tools are BLOCKED until the user responds." \
    "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  # Record performance
  END_TIME=$(date +%s%N 2>/dev/null || date +%s)
  if [[ "$START_TIME" =~ ^[0-9]+$ ]] && [[ "$END_TIME" =~ ^[0-9]+$ ]]; then
    DURATION=$(((END_TIME - START_TIME) / 1000000))
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] check-pending-questions.sh ${DURATION}ms (blocked: $TOOL_NAME)" >> "$HOOKS_DIR/logs/performance.log" 2>/dev/null
  fi

  exit $EXIT_BLOCK  # BLOCK tool execution
fi

# ───────────────────────────────────────────────────────────────
# NO PENDING QUESTION - ALLOW TOOL
# ───────────────────────────────────────────────────────────────
# Record performance (success case)
END_TIME=$(date +%s%N 2>/dev/null || date +%s)
if [[ "$START_TIME" =~ ^[0-9]+$ ]] && [[ "$END_TIME" =~ ^[0-9]+$ ]]; then
  DURATION=$(((END_TIME - START_TIME) / 1000000))
  # Only log if >10ms to avoid log spam
  if [ "$DURATION" -gt 10 ] 2>/dev/null; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] check-pending-questions.sh ${DURATION}ms (allowed: $TOOL_NAME)" >> "$HOOKS_DIR/logs/performance.log" 2>/dev/null
  fi
fi

exit $EXIT_ALLOW  # ALLOW tool execution
