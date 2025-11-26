#!/bin/bash

# ───────────────────────────────────────────────────────────────
# DETECT-SCOPE-GROWTH.SH - Mid-Conversation Scope Detection
# ───────────────────────────────────────────────────────────────
# PostToolUse hook that monitors for scope expansion during
# implementation. Warns (advisory, not blocking) when scope
# grows significantly beyond initial estimate.
#
# Version: 1.0.0
# Created: 2025-11-25
# Spec: specs/002-speckit/008-validation-enforcement/
#
# TRIGGERS: After Edit/Write tool completions
# OUTPUT: Advisory warning when scope grows >50%
# BLOCKING: No - advisory only
# ───────────────────────────────────────────────────────────────

set -euo pipefail

# Performance: Early exit if not relevant tool
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOKS_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT_ROOT="$(dirname "$HOOKS_DIR")"
PROJECT_ROOT="${PROJECT_ROOT%/.claude}"

# Read tool input from stdin
INPUT=$(cat)

# Extract tool name
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // ""' 2>/dev/null)

# Only process after Edit/Write operations
if [[ ! "$TOOL_NAME" =~ ^(Edit|Write)$ ]]; then
  exit 0
fi

# Source shared state library
if [ -f "$HOOKS_DIR/lib/shared-state.sh" ]; then
  source "$HOOKS_DIR/lib/shared-state.sh"
else
  exit 0  # Can't check without state library
fi

# Read initial scope from state (set by enforce-spec-folder.sh)
initial_state=$(read_hook_state "initial_scope" 7200 2>/dev/null) || initial_state=""

# If no initial scope recorded, nothing to compare
if [ -z "$initial_state" ]; then
  exit 0
fi

# Extract initial values
initial_files=$(echo "$initial_state" | jq -r '.files_count // 0' 2>/dev/null) || initial_files=0
initial_level=$(echo "$initial_state" | jq -r '.level // 2' 2>/dev/null) || initial_level=2
spec_folder=$(echo "$initial_state" | jq -r '.spec_folder // ""' 2>/dev/null) || spec_folder=""

# Skip if no spec folder or invalid initial count
if [ -z "$spec_folder" ] || [ "$initial_files" -eq 0 ]; then
  exit 0
fi

# Count current files in spec folder
current_files=0
if [ -d "$spec_folder" ]; then
  current_files=$(find "$spec_folder" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
fi

# Calculate growth percentage
if [ "$initial_files" -gt 0 ] && [ "$current_files" -gt 0 ]; then
  growth_ratio=$((current_files * 100 / initial_files))

  # Detect significant scope growth (>150% = 50% growth)
  if [ "$growth_ratio" -gt 150 ]; then
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "⚠️  SCOPE GROWTH DETECTED (Advisory)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Initial files: $initial_files"
    echo "Current files: $current_files"
    echo "Growth: +$((growth_ratio - 100))%"
    echo ""
    echo "Consider:"
    if [ "$initial_level" -eq 1 ]; then
      echo "  • Upgrading to Level 2 (add plan.md)"
    fi
    if [ "$initial_level" -le 2 ]; then
      echo "  • Adding tasks.md for tracking"
      echo "  • Adding checklist.md for validation"
    fi
    echo ""
    echo "This is advisory only - continue if scope growth is expected."
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
  fi
fi

exit 0
