#!/bin/bash

# ───────────────────────────────────────────────────────────────
# CDN VERSION REMINDER HOOK
# ───────────────────────────────────────────────────────────────
# Post-ToolUse hook that reminds to run CDN version updater
# after JavaScript file modifications
#
# Author: Auto-generated from spec 090-code-workflows-orchestrator-restructure
# Date: 2025-11-19
# Version: 1.0.0
#
# PERFORMANCE TARGET: <200ms (file path checks, pattern matching)
# COMPATIBILITY: Bash 3.2+ (macOS and Linux compatible)
#
# EXECUTION ORDER: PostToolUse hook (runs AFTER tool completion)
#   1. UserPromptSubmit hooks run FIRST (before processing user input)
#   2. PreToolUse hooks run SECOND (before tool execution, validation)
#   3. PostToolUse hooks run LAST (after tool completion, verification)
#   This hook: Reminds to update CDN version parameters after JS changes
#
# EXIT CODE CONVENTION:
#   0 = Allow (hook passed, continue execution)
#   1 = Block (hook failed, stop execution with warning)
#   2 = Error (reserved for critical failures)
# ───────────────────────────────────────────────────────────────

# Source output helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
HOOKS_DIR="$(cd "$SCRIPT_DIR/.." 2>/dev/null && pwd)"
source "$HOOKS_DIR/lib/output-helpers.sh" || exit 0

# Performance timing START
START_TIME=$(date +%s%N)

# Read JSON input from stdin
INPUT=$(cat)

# Extract tool information from JSON (support multiple payload shapes)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // .toolName // .tool // .name // empty' 2>/dev/null)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.filePath // .tool_input.file_path // .tool_input.path // .tool_input.notebook_path // .parameters.file_path // .parameters.filePath // .parameters.path // .parameters.notebook_path // empty' 2>/dev/null)

# If no tool or file path, allow it
if [ -z "$TOOL_NAME" ] || [ -z "$FILE_PATH" ]; then
  exit 0
fi

# ───────────────────────────────────────────────────────────────
# JAVASCRIPT FILE MODIFICATION DETECTION
# ───────────────────────────────────────────────────────────────

# Check if tool was Edit or Write
if [ "$TOOL_NAME" != "Edit" ] && [ "$TOOL_NAME" != "Write" ]; then
  exit 0
fi

# Check if file is a JavaScript file
if ! echo "$FILE_PATH" | grep -qE '\.js$'; then
  exit 0
fi

# Check if file is in src/2_javascript/ directory
if ! echo "$FILE_PATH" | grep -qE 'src/2_javascript/'; then
  exit 0
fi

# ───────────────────────────────────────────────────────────────
# REMINDER OUTPUT
# ───────────────────────────────────────────────────────────────

# Get relative file path for display
PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || (cd "$SCRIPT_DIR/../.." && pwd))
REL_FILE_PATH=${FILE_PATH#$PROJECT_ROOT/}

echo ""
echo "⚡ REMINDER: JavaScript file modified"
echo "───────────────────────────────────────────────────────────────"
echo "File: $REL_FILE_PATH"
echo ""
echo "After JavaScript changes, update HTML version parameters:"
echo ""
echo "  python3 .claude/hooks/scripts/update_html_versions.py"
echo ""
echo "This increments version numbers in HTML files (e.g., page_loader.js?v=1.0.2)"
echo "to force browsers to download fresh files instead of using cached versions."
echo ""
echo "Purpose: CDN cache-busting"
echo "See: workflows-code skill, Implementation Phase (Sections 1-3)"
echo "Reference: .claude/skills/workflows-code/references/implementation_workflows.md"
echo "───────────────────────────────────────────────────────────────"
echo ""

# Log reminder
LOG_DIR="$HOOKS_DIR/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/$(basename "$0" .sh).log"

{
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] CDN VERSION REMINDER"
  echo "Tool: $TOOL_NAME"
  echo "File: $REL_FILE_PATH"
  echo "Action: Modified JavaScript file in src/2_javascript/"
  echo "Reminder: Run update_html_versions.py script"
  echo "───────────────────────────────────────────────────────────────"
} >> "$LOG_FILE"

# Performance timing END
END_TIME=$(date +%s%N)
DURATION=$(( (END_TIME - START_TIME) / 1000000 ))
echo "[$(date '+%Y-%m-%d %H:%M:%S')] remind-cdn-versioning.sh ${DURATION}ms" >> "$SCRIPT_DIR/../logs/performance.log"

# Allow request to proceed
exit 0
