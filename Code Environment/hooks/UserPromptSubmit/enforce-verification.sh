#!/bin/bash

# ───────────────────────────────────────────────────────────────
# VERIFICATION ENFORCEMENT HOOK - "The Iron Law"
# ───────────────────────────────────────────────────────────────
# UserPromptSubmit hook that BLOCKS completion claims without verification
# NO COMPLETION CLAIMS WITHOUT FRESH BROWSER VERIFICATION EVIDENCE
#
# Behavior: exit 1 (BLOCKS) when completion claim detected without evidence
# Updated: 2025-11-19 (spec 094-skills-hooks-refinement)
# Version: 2.0.0
#
# PERFORMANCE TARGET: <50ms (lightweight pattern matching)
# COMPATIBILITY: Bash 3.2+ (macOS and Linux compatible)
#
# EXECUTION ORDER: UserPromptSubmit hook (runs BEFORE user prompt processing)
#   1. UserPromptSubmit hooks run FIRST (before processing user input)
#   2. PreToolUse hooks run SECOND (before tool execution, validation)
#   3. PostToolUse hooks run LAST (after tool completion, verification)
#   This hook: Blocks completion claims without browser verification evidence
#
# EXIT CODE CONVENTION:
#   0 = Allow (hook passed, continue execution)
#   1 = Block (hook failed, stop execution with warning)
#   2 = Error (reserved for critical failures)
# ───────────────────────────────────────────────────────────────

# Source output helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
source "$SCRIPT_DIR/../lib/output-helpers.sh" || exit 0

# Performance timing START
START_TIME=$(date +%s%N)

# Read JSON input from stdin
INPUT=$(cat)

# Extract the prompt from JSON
PROMPT=$(echo "$INPUT" | jq -r '.prompt // empty' 2>/dev/null)

# If no prompt found, allow it
if [ -z "$PROMPT" ]; then
  exit 0
fi

# Convert to lowercase for matching
PROMPT_LOWER=$(echo "$PROMPT" | tr '[:upper:]' '[:lower:]')

# ───────────────────────────────────────────────────────────────
# COMPLETION CLAIM DETECTION
# ───────────────────────────────────────────────────────────────

# Detect completion claims
detect_completion_claim() {
  local text="$1"

  # Completion claim patterns
  if echo "$text" | grep -qiE "(is|it's|looks|seems).*(complete|done|fixed|working|ready)"; then
    return 0
  fi

  if echo "$text" | grep -qiE "(animation|layout|video|form|feature).*(works|working|fixed)"; then
    return 0
  fi

  if echo "$text" | grep -qiE "^(done|ready|complete|fixed|working)"; then
    return 0
  fi

  if echo "$text" | grep -qiE "(all|everything).*(works|working|good|fixed)"; then
    return 0
  fi

  return 1
}

# Detect verification evidence
check_verification_evidence() {
  local text="$1"

  # Evidence patterns that indicate actual browser verification
  local evidence_count=0

  # Browser testing mentioned
  if echo "$text" | grep -qiE "tested in (chrome|firefox|safari|browser)"; then
    ((evidence_count++))
  fi

  # DevTools console mentioned
  if echo "$text" | grep -qiE "(devtools|console).*(clear|no errors)"; then
    ((evidence_count++))
  fi

  # Viewport sizes mentioned
  if echo "$text" | grep -qiE "(1920px|375px|768px|viewport|mobile|desktop).*test"; then
    ((evidence_count++))
  fi

  # Actual observation described
  if echo "$text" | grep -qiE "(saw|watched|observed|opened browser|refreshed page)"; then
    ((evidence_count++))
  fi

  # Need at least 2 evidence patterns for valid verification
  if [ $evidence_count -ge 2 ]; then
    return 0
  fi

  return 1
}

# ───────────────────────────────────────────────────────────────
# ENFORCEMENT LOGIC
# ───────────────────────────────────────────────────────────────

# Check if completion claim is present
if ! detect_completion_claim "$PROMPT_LOWER"; then
  # No completion claim, allow request
  exit 0
fi

# Completion claim detected - check for verification evidence
if check_verification_evidence "$PROMPT_LOWER"; then
  # Valid verification evidence found, allow request
  exit 0
fi

# VIOLATION: Completion claim WITHOUT verification evidence
echo ""
echo "🔴 BLOCKED - VERIFICATION REQUIRED (The Iron Law)"
echo "───────────────────────────────────────────────────────────────"
echo "Detected completion claim without browser verification evidence."
echo ""
echo "NO COMPLETION CLAIMS WITHOUT FRESH BROWSER VERIFICATION EVIDENCE"
echo ""
echo "Before claiming work is complete, you MUST:"
echo "  □ Open actual browser (Chrome minimum)"
echo "  □ Test at desktop viewport (1920px)"
echo "  □ Test at mobile viewport (375px)"
echo "  □ Check DevTools console (no errors)"
echo "  □ Describe what you saw in browser"
echo ""
echo "Claims like 'done', 'fixed', 'working', 'complete' require evidence:"
echo "  ✅ 'Tested in Chrome at 1920px and 375px, console clear, animation smooth'"
echo "  ❌ 'Animation code looks correct' (no browser test)"
echo "  ❌ 'Should work now' (no verification)"
echo ""
echo "→ ACTION REQUIRED: Verify in browser first, then resubmit with evidence"
echo ""
echo "See: workflows-code skill, Verification Phase (Sections 1-3, 5, 8)"
echo "Reference: .claude/skills/workflows-code/references/verification_workflows.md"
echo "───────────────────────────────────────────────────────────────"
echo ""

# Log enforcement
HOOKS_DIR="$(cd "$SCRIPT_DIR/.." 2>/dev/null && pwd)"
LOG_DIR="$HOOKS_DIR/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/$(basename "$0" .sh).log"

{
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] VERIFICATION ENFORCEMENT TRIGGERED"
  echo "Prompt (first 200 chars): ${PROMPT:0:200}..."
  echo "Reason: Completion claim without verification evidence"
  echo "───────────────────────────────────────────────────────────────"
} >> "$LOG_FILE"

# Performance timing END
END_TIME=$(date +%s%N)
DURATION=$(( (END_TIME - START_TIME) / 1000000 ))
echo "[$(date '+%Y-%m-%d %H:%M:%S')] enforce-verification.sh ${DURATION}ms BLOCKED" >> "$SCRIPT_DIR/../logs/performance.log"

# Block request - Iron Law enforcement
exit 1
