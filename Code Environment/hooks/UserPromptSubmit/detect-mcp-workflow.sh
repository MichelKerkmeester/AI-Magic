#!/bin/bash

# ───────────────────────────────────────────────────────────────
# MCP WORKFLOW DETECTION HOOK
# ───────────────────────────────────────────────────────────────
# UserPromptSubmit hook that detects multi-step MCP workflows
# and highlights Code Mode benefits for complex operations
#
# PERFORMANCE TARGET: <50ms (lightweight pattern matching)
# COMPATIBILITY: Bash 3.2+ (macOS and Linux compatible)
#
# EXECUTION ORDER: UserPromptSubmit hook (runs BEFORE user prompt processing)
#   1. UserPromptSubmit hooks run FIRST (before processing user input)
#   2. PreToolUse hooks run SECOND (before tool execution, validation)
#   3. PostToolUse hooks run LAST (after tool completion, verification)
#   This hook: Detects complex multi-platform workflows
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
# MULTI-PLATFORM DETECTION
# ───────────────────────────────────────────────────────────────

# Count mentions of each MCP platform
WEBFLOW_COUNT=$(echo "$PROMPT_LOWER" | grep -o "webflow" | wc -l | tr -d ' ')
FIGMA_COUNT=$(echo "$PROMPT_LOWER" | grep -o "figma" | wc -l | tr -d ' ')
CHROME_COUNT=$(echo "$PROMPT_LOWER" | grep -o "chrome" | wc -l | tr -d ' ')
SEMANTIC_COUNT=$(echo "$PROMPT_LOWER" | grep -o "semantic" | wc -l | tr -d ' ')

# Calculate total platforms mentioned
TOTAL_PLATFORMS=$((WEBFLOW_COUNT + FIGMA_COUNT + CHROME_COUNT + SEMANTIC_COUNT))

# Build list of detected platforms
DETECTED_PLATFORMS=""
[ "$WEBFLOW_COUNT" -gt 0 ] && DETECTED_PLATFORMS="${DETECTED_PLATFORMS}Webflow, "
[ "$FIGMA_COUNT" -gt 0 ] && DETECTED_PLATFORMS="${DETECTED_PLATFORMS}Figma, "
[ "$CHROME_COUNT" -gt 0 ] && DETECTED_PLATFORMS="${DETECTED_PLATFORMS}Chrome DevTools, "
[ "$SEMANTIC_COUNT" -gt 0 ] && DETECTED_PLATFORMS="${DETECTED_PLATFORMS}Semantic Search, "

# Remove trailing comma and space
DETECTED_PLATFORMS=$(echo "$DETECTED_PLATFORMS" | sed 's/, $//')

# ───────────────────────────────────────────────────────────────
# SEQUENTIAL OPERATION DETECTION
# ───────────────────────────────────────────────────────────────

# Keywords indicating sequential operations
SEQUENTIAL_KEYWORDS=(
  "first.*then"
  "then.*update"
  "then.*create"
  "after.*create"
  "after.*update"
  "next.*publish"
  "next.*update"
  "finally.*update"
  "and then"
)

HAS_SEQUENTIAL=false
for pattern in "${SEQUENTIAL_KEYWORDS[@]}"; do
  if echo "$PROMPT_LOWER" | grep -qE "$pattern"; then
    HAS_SEQUENTIAL=true
    break
  fi
done

# ───────────────────────────────────────────────────────────────
# CROSS-PLATFORM KEYWORDS
# ───────────────────────────────────────────────────────────────

# Keywords indicating data flow between platforms
CROSS_PLATFORM_KEYWORDS=(
  "from.*to"
  "into.*and"
  "between.*and"
  "integrate.*with"
  "sync.*with"
  "pipeline"
  "workflow"
  "automate"
  "automation"
)

HAS_CROSS_PLATFORM=false
for pattern in "${CROSS_PLATFORM_KEYWORDS[@]}"; do
  if echo "$PROMPT_LOWER" | grep -qE "$pattern"; then
    HAS_CROSS_PLATFORM=true
    break
  fi
done

# ───────────────────────────────────────────────────────────────
# DECISION LOGIC
# ───────────────────────────────────────────────────────────────

SHOULD_SUGGEST=false
WORKFLOW_TYPE=""

# Multi-platform workflow (2+ platforms)
if [ "$TOTAL_PLATFORMS" -ge 2 ]; then
  SHOULD_SUGGEST=true
  WORKFLOW_TYPE="Multi-Platform Workflow"
fi

# Sequential operations with single platform
if [ "$SHOULD_SUGGEST" = false ] && [ "$HAS_SEQUENTIAL" = true ] && [ "$TOTAL_PLATFORMS" -ge 1 ]; then
  SHOULD_SUGGEST=true
  WORKFLOW_TYPE="Sequential Multi-Step Operations"
fi

# Cross-platform integration keywords
if [ "$SHOULD_SUGGEST" = false ] && [ "$HAS_CROSS_PLATFORM" = true ] && [ "$TOTAL_PLATFORMS" -ge 1 ]; then
  SHOULD_SUGGEST=true
  WORKFLOW_TYPE="Cross-Platform Integration"
fi

# ───────────────────────────────────────────────────────────────
# OUTPUT SUGGESTION
# ───────────────────────────────────────────────────────────────

if [ "$SHOULD_SUGGEST" = true ]; then
  echo ""
  echo "🔄 MULTI-STEP WORKFLOW DETECTED:"
  echo ""
  echo "This request involves multiple MCP operations or platforms."
  echo ""

  if [ -n "$DETECTED_PLATFORMS" ]; then
    echo "  Platforms Detected: [$DETECTED_PLATFORMS]"
  fi

  echo "  Workflow Type: $WORKFLOW_TYPE"
  echo ""
  echo "  ⚡ Code Mode Advantages for Workflows:"
  echo "  • State persistence across ALL operations"
  echo "  • Single execution (no context switching)"
  echo "  • 5× faster than separate tool calls"
  echo "  • Automatic error handling and rollback"
  echo "  • 98.7% reduction in context overhead"
  echo ""

  # Determine which example to show based on detected platforms
  if [ "$FIGMA_COUNT" -gt 0 ] && [ "$WEBFLOW_COUNT" -gt 0 ]; then
    # Figma + Webflow workflow
    echo "  📖 Example: Design-to-CMS Workflow"
    echo "  call_tool_chain({"
    echo "    code: \`"
    echo "      // 1. Get Figma design data"
    echo "      console.log('Fetching Figma design...');"
    echo "      const design = await figma.figma_get_file({ fileId: 'abc123' });"
    echo "      const componentCount = design.document.children.length;"
    echo ""
    echo "      // 2. Update Webflow CMS with design data"
    echo "      console.log('Updating Webflow CMS...');"
    echo "      const sites = await webflow.webflow_sites_list({});"
    echo "      const item = await webflow.webflow_items_create_item({"
    echo "        collectionId: '...',"
    echo "        fields: {"
    echo "          name: design.name,"
    echo "          components: componentCount"
    echo "        }"
    echo "      });"
    echo ""
    echo "      // 3. Return combined results"
    echo "      return {"
    echo "        design: { name: design.name, components: componentCount },"
    echo "        webflowItem: { id: item.id }"
    echo "      };"
    echo "    \`,"
    echo "    timeout: 60000  // Extended timeout for multi-step workflows"
    echo "  });"

  elif [ "$WEBFLOW_COUNT" -gt 0 ] && [ "$CHROME_COUNT" -gt 0 ]; then
    # Webflow + Chrome workflow
    echo "  📖 Example: CMS + Browser Testing Workflow"
    echo "  call_tool_chain({"
    echo "    code: \`"
    echo "      // 1. Get Webflow site URL"
    echo "      const sites = await webflow.webflow_sites_list({});"
    echo "      const siteUrl = sites.sites[0].previewUrl;"
    echo ""
    echo "      // 2. Navigate and screenshot with Chrome DevTools"
    echo "      await chrome_devtools_1.chrome_devtools_navigate_page({ url: siteUrl });"
    echo "      const screenshot = await chrome_devtools_1.chrome_devtools_take_screenshot({});"
    echo ""
    echo "      return { siteUrl, screenshot };"
    echo "    \`,"
    echo "    timeout: 60000"
    echo "  });"

  elif [ "$TOTAL_PLATFORMS" -ge 3 ]; then
    # Complex multi-platform workflow
    echo "  📖 Example: Complex Multi-Platform Workflow"
    echo "  call_tool_chain({"
    echo "    code: \`"
    echo "      // 1. Fetch from first platform"
    echo "      const data1 = await platform1.platform1_get_data({...});"
    echo ""
    echo "      // 2. Create in second platform using data from first"
    echo "      const data2 = await platform2.platform2_create_item({"
    echo "        field: data1.value"
    echo "      });"
    echo ""
    echo "      // 3. Update third platform with combined data"
    echo "      await platform3.platform3_update_item({"
    echo "        data1_id: data1.id,"
    echo "        data2_id: data2.id"
    echo "      });"
    echo ""
    echo "      return { success: true, data1, data2 };"
    echo "    \`,"
    echo "    timeout: 90000  // Generous timeout for complex workflows"
    echo "  });"

  elif [ "$HAS_SEQUENTIAL" = true ]; then
    # Sequential operations (single platform)
    echo "  📖 Example: Sequential Operations Workflow"
    echo "  call_tool_chain({"
    echo "    code: \`"
    echo "      // Sequential operations with state persistence"
    echo "      const step1 = await platform.platform_operation_1({...});"
    echo "      console.log('Step 1 complete:', step1.id);"
    echo ""
    echo "      const step2 = await platform.platform_operation_2({"
    echo "        reference_id: step1.id  // Use data from step 1"
    echo "      });"
    echo "      console.log('Step 2 complete:', step2.id);"
    echo ""
    echo "      const step3 = await platform.platform_operation_3({"
    echo "        step1_id: step1.id,"
    echo "        step2_id: step2.id"
    echo "      });"
    echo ""
    echo "      return { step1, step2, step3 };"
    echo "    \`,"
    echo "    timeout: 60000"
    echo "  });"

  else
    # Generic workflow example
    echo "  📖 Example: Multi-Step Workflow Pattern"
    echo "  call_tool_chain({"
    echo "    code: \`"
    echo "      try {"
    echo "        // Step 1: Initial operation"
    echo "        const result1 = await platform.platform_operation_1({...});"
    echo ""
    echo "        // Step 2: Dependent operation"
    echo "        const result2 = await platform.platform_operation_2({"
    echo "          input: result1.output"
    echo "        });"
    echo ""
    echo "        // Step 3: Final operation"
    echo "        const result3 = await platform.platform_operation_3({"
    echo "          data: { result1, result2 }"
    echo "        });"
    echo ""
    echo "        return { success: true, results: [result1, result2, result3] };"
    echo ""
    echo "      } catch (error) {"
    echo "        console.error('Workflow failed:', error.message);"
    echo "        return { success: false, error: error.message };"
    echo "      }"
    echo "    \`,"
    echo "    timeout: 60000"
    echo "  });"
  fi

  echo ""
  echo "  💡 Workflow Benefits:"
  echo "  • All operations share the same execution context"
  echo "  • No data serialization between steps"
  echo "  • Automatic variable scoping and state management"
  echo "  • Single try/catch for the entire workflow"
  echo "  • Console logging tracks progress across all steps"
  echo ""
  echo "  🔧 Tool Naming: {manual_name}.{manual_name}_{tool_name}"
  echo "  Timeout: Use 60000-90000ms for complex workflows"
  echo ""
  echo "📖 See: .claude/skills/mcp-code-mode/SKILL.md (Section 4: Usage Examples)"
  echo ""
  echo "⚠️  Multi-step workflows benefit MOST from Code Mode"
  echo "    (5× faster, automatic state persistence, error handling)"
  echo ""
fi

# Performance timing END
END_TIME=$(date +%s%N)
DURATION=$(( (END_TIME - START_TIME) / 1000000 ))

# Log with workflow detection details
if [ "$SHOULD_SUGGEST" = true ]; then
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] detect-mcp-workflow.sh ${DURATION}ms - Detected: $WORKFLOW_TYPE (Platforms: $TOTAL_PLATFORMS)" >> "$HOOKS_DIR/logs/performance.log"
else
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] detect-mcp-workflow.sh ${DURATION}ms - No workflow detected" >> "$HOOKS_DIR/logs/performance.log"
fi

# Always allow the prompt to proceed
exit 0
