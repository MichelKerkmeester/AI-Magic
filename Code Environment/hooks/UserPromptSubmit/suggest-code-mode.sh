#!/bin/bash

# ───────────────────────────────────────────────────────────────
# CODE MODE SUGGESTION HOOK
# ───────────────────────────────────────────────────────────────
# UserPromptSubmit hook that reminds AI to use Code Mode for
# MCP tool operations (mandatory for optimal context efficiency)
#
# PERFORMANCE TARGET: <50ms (lightweight pattern matching)
# COMPATIBILITY: Bash 3.2+ (macOS and Linux compatible)
#
# EXECUTION ORDER: UserPromptSubmit hook (runs BEFORE user prompt processing)
#   1. UserPromptSubmit hooks run FIRST (before processing user input)
#   2. PreToolUse hooks run SECOND (before tool execution, validation)
#   3. PostToolUse hooks run LAST (after tool completion, verification)
#   This hook: Reminds AI to use Code Mode for all MCP tool calls
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

# CMS Operations (Webflow)
CMS_PATTERNS=(
  "webflow"
  "cms collection"
  "publish site"
  "update content"
  "webflow item"
  "cms item"
  "collection field"
  "webflow page"
  "webflow component"
)

# Design Tools (Figma)
DESIGN_PATTERNS=(
  "figma"
  "design file"
  "get component"
  "design system"
  "figma export"
  "design token"
  "figma comment"
  "team component"
)

# Browser Automation (Chrome DevTools)
BROWSER_PATTERNS=(
  "chrome devtools"
  "screenshot"
  "navigate page"
  "browser automation"
  "test page"
  "click element"
  "fill form"
  "evaluate script"
)

# Multi-Tool Workflows
WORKFLOW_PATTERNS=(
  "workflow"
  "pipeline"
  "integrate"
  "automate"
  "from.*to"
  "then update"
  "then create"
  "first.*then"
  "after.*update"
)

# ───────────────────────────────────────────────────────────────
# PATTERN DETECTION
# ───────────────────────────────────────────────────────────────

SHOULD_SUGGEST=false
DETECTED_CATEGORY=""

# Check CMS Operations
for pattern in "${CMS_PATTERNS[@]}"; do
  if echo "$PROMPT_LOWER" | grep -qE "$pattern"; then
    SHOULD_SUGGEST=true
    DETECTED_CATEGORY="CMS Operations (Webflow)"
    break
  fi
done

# Check Design Tools
if [ "$SHOULD_SUGGEST" = false ]; then
  for pattern in "${DESIGN_PATTERNS[@]}"; do
    if echo "$PROMPT_LOWER" | grep -qE "$pattern"; then
      SHOULD_SUGGEST=true
      DETECTED_CATEGORY="Design Tools (Figma)"
      break
    fi
  done
fi

# Check Browser Automation
if [ "$SHOULD_SUGGEST" = false ]; then
  for pattern in "${BROWSER_PATTERNS[@]}"; do
    if echo "$PROMPT_LOWER" | grep -qE "$pattern"; then
      SHOULD_SUGGEST=true
      DETECTED_CATEGORY="Browser Automation (Chrome DevTools)"
      break
    fi
  done
fi

# Check Multi-Tool Workflows
if [ "$SHOULD_SUGGEST" = false ]; then
  for pattern in "${WORKFLOW_PATTERNS[@]}"; do
    if echo "$PROMPT_LOWER" | grep -qE "$pattern"; then
      SHOULD_SUGGEST=true
      DETECTED_CATEGORY="Multi-Tool Workflow"
      break
    fi
  done
fi

# ───────────────────────────────────────────────────────────────
# OUTPUT SUGGESTION
# ───────────────────────────────────────────────────────────────

if [ "$SHOULD_SUGGEST" = true ]; then
  echo ""
  echo "🤖 CODE MODE REMINDER:"
  echo ""
  echo "This request involves MCP tool operations. Use Code Mode for optimal performance:"
  echo ""
  echo "  Pattern Detected: $DETECTED_CATEGORY"
  echo ""
  echo "  ⚡ Benefits:"
  echo "  • 68% fewer tokens consumed"
  echo "  • 98.7% reduction in context overhead"
  echo "  • 60% faster execution"
  echo "  • Single execution vs multiple round trips"
  echo ""

  # Category-specific examples
  case "$DETECTED_CATEGORY" in
    "CMS Operations (Webflow)")
      echo "  📖 Usage Pattern:"
      echo "  search_tools({ task_description: \"webflow cms collection\", limit: 10 });"
      echo ""
      echo "  call_tool_chain({"
      echo "    code: \`"
      echo "      const sites = await webflow.webflow_sites_list({});"
      echo "      const collections = await webflow.webflow_collections_list({"
      echo "        site_id: sites.sites[0].id"
      echo "      });"
      echo "      return { sites, collections };"
      echo "    \`"
      echo "  });"
      ;;

    "Design Tools (Figma)")
      echo "  📖 Usage Pattern:"
      echo "  search_tools({ task_description: \"figma design file\", limit: 10 });"
      echo ""
      echo "  call_tool_chain({"
      echo "    code: \`"
      echo "      const file = await figma.figma_get_file({ fileId: \"...\" });"
      echo "      return file;"
      echo "    \`"
      echo "  });"
      ;;

    "Browser Automation (Chrome DevTools)")
      echo "  📖 Usage Pattern:"
      echo "  search_tools({ task_description: \"chrome browser automation\", limit: 10 });"
      echo ""
      echo "  call_tool_chain({"
      echo "    code: \`"
      echo "      await chrome_devtools_1.chrome_devtools_navigate_page({ url: \"...\" });"
      echo "      const screenshot = await chrome_devtools_1.chrome_devtools_take_screenshot({});"
      echo "      return screenshot;"
      echo "    \`"
      echo "  });"
      ;;

    "Multi-Tool Workflow")
      echo "  📖 Multi-Step Workflow Pattern:"
      echo "  call_tool_chain({"
      echo "    code: \`"
      echo "      // 1. Get data from first platform"
      echo "      const data = await platform1.tool_name({...});"
      echo ""
      echo "      // 2. Process and create in second platform"
      echo "      const result = await platform2.tool_name({"
      echo "        field: data.value"
      echo "      });"
      echo ""
      echo "      // 3. Return combined results"
      echo "      return { data, result };"
      echo "    \`,"
      echo "    timeout: 60000  // Extended timeout for workflows"
      echo "  });"
      ;;
  esac

  echo ""
  echo "  🔧 Tool Naming Convention: {manual_name}.{manual_name}_{tool_name}"
  echo "  Example: webflow.webflow_sites_list(), figma.figma_get_file()"
  echo ""
  echo "📖 See: .claude/skills/mcp-code-mode/SKILL.md for complete guide"
  echo ""
  echo "⚠️  IMPORTANT: ALL MCP tools MUST be called via Code Mode"
  echo "              (98.7% overhead reduction, mandatory for this environment)"
  echo ""
fi

# Performance timing END
END_TIME=$(date +%s%N)
DURATION=$(( (END_TIME - START_TIME) / 1000000 ))
echo "[$(date '+%Y-%m-%d %H:%M:%S')] suggest-code-mode.sh ${DURATION}ms - Category: ${DETECTED_CATEGORY:-none}" >> "$HOOKS_DIR/logs/performance.log"

# Always allow the prompt to proceed
exit 0
