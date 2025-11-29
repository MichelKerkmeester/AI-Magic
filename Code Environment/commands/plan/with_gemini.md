---
description: Create a detailed implementation plan using Gemini models via Copilot for parallel exploration with web research capabilities (OpenCode)
argument-hint: <task description> [mode:simple|mode:complex]
allowed-tools: Read, Write, Edit, Glob, Grep, Task, AskUserQuestion
agent: plan
---

# Implementation Plan with Gemini (OpenCode)

Create comprehensive implementation plans using Gemini models (via OpenCode Copilot) for parallel codebase exploration with potential web research capabilities to thoroughly analyze before any code changes.

**Platform**: OpenCode with Copilot integration
**Orchestrator**: Claude (main agent)
**Explorers**: Gemini 2.0/3.0 Pro agents via Copilot (parallel exploration)

---

## Purpose

Enter PLANNING MODE to create detailed, verified implementation plans. This command:
1. Analyzes task complexity and selects appropriate mode (simple or complex)
2. Spawns multiple Gemini-based agents in parallel via Copilot to discover codebase patterns
3. Leverages Gemini's potential web search and research capabilities
4. Synthesizes Gemini findings into a structured plan using YAML workflow
5. Requires user approval before implementation begins

**Key Difference from with_claude**:
- Uses **Gemini models via Copilot** for exploration instead of Claude models
- Provides alternative AI perspective on codebase patterns
- Gemini may have web search/research capabilities for current best practices
- Same parallel agent architecture as Claude Code

**Modes:**
- **Simple Mode** (<500 LOC): Single plan.md file using `simple_mode.yaml`
- **Complex Mode** (≥500 LOC): Multi-file plan/ directory (future - currently falls back to simple mode)

---

## Contract

**Inputs:** `$ARGUMENTS` — Task description (REQUIRED) + optional mode override
**Outputs:** Plan file at `specs/###-name/plan.md` + `STATUS=<OK|FAIL|CANCELLED>`

---

## Instructions

Execute the following workflow:

### Step 1: Parse Input & Detect Mode Override

1. **Extract task description from $ARGUMENTS**
2. **Check for explicit mode override:**
   - Pattern: `mode:simple` or `mode:complex` in arguments
   - If found: Use specified mode, skip auto-detection
   - If not found: Proceed to Step 2 for auto-detection

### Step 2: Auto-Detect Planning Mode

If no mode override specified, analyze task complexity:

3. **Estimate LOC from task description:**
   - Keywords: "small" = 100, "feature" = 200, "refactor" = 300, "system" = 500, "redesign" = 800
   - File count indicators: "all", "multiple", "across" = +200 LOC
   - Default: 300 LOC if unclear

4. **Calculate complexity score (0-100%):**
   - Domain count (35%): code, docs, git, testing, devops
   - File count (25%): estimated files modified
   - LOC estimate (15%): normalized 0-1
   - Parallel opportunity (20%): can tasks run in parallel?
   - Task type (5%): implementation complexity

5. **Select mode:**
   ```
   IF loc_estimate < 500:
     mode = "simple"
   ELSE IF loc_estimate >= 500 OR iterations >= 4:
     mode = "complex"  # Falls back to simple until Phase 5 implemented
   ELSE:
     mode = "simple"
   ```

### Step 3: Load & Execute YAML Workflow

6. **Read the appropriate YAML workflow prompt from OpenCode assets:**

   Asset path: `.opencode/command/plan/assets/`

   Based on the mode selected in Step 2:

   - **SIMPLE mode** (<500 LOC): Use the Read tool to load `.opencode/command/plan/assets/simple_mode.yaml` and execute all instructions in that file.

   - **COMPLEX mode** (≥500 LOC): Use the Read tool to load `.opencode/command/plan/assets/complex_mode.yaml`. Note: Complex mode is a stub as of Phase 1.5 and will notify user to fall back to simple mode.

7. **YAML workflow executes automatically with Gemini model override:**

   The loaded YAML prompt contains the complete 8-phase workflow:
   - **Phases 1-3**: Task Understanding, Spec Folder Setup, Context Loading
   - **Phases 4-5**: Parallel Exploration (4 Gemini agents via Copilot), Hypothesis Verification (Claude)
   - **Phase 6**: Plan Creation (simple_mode or complex_mode)
   - **Phases 7-8**: User Review & Confirmation, Context Persistence

   **CRITICAL OVERRIDE for Phase 4 (Parallel Exploration):**

   When spawning the 4 Explore agents, use Gemini models via Copilot instead of Claude:

   ```yaml
   Task({
     subagent_type: "Explore",
     model: "gemini-2.0-pro",  # Or "gemini-3.0-pro" if available via Copilot
     description: "Architecture exploration",
     prompt: "[exploration prompt from YAML]"
   })
   ```

   **Spawn all 4 agents in parallel** (single message with 4 Task calls):
   - Architecture Explorer (Gemini)
   - Feature Explorer (Gemini)
   - Dependency Explorer (Gemini)
   - Test Explorer (Gemini)

   **Model Selection:**
   - Use Gemini 2.0 Pro by default (capable, multimodal)
   - Use Gemini 3.0 Pro if available and configured in Copilot
   - OpenCode routes to appropriate Gemini model via Copilot integration

   **Gemini Capabilities:**
   - May leverage Google Search for supplementary information (if enabled)
   - Multimodal understanding (code + documentation)
   - Different training data and strengths than Claude/GPT

   All phases execute sequentially: 1 → 2 → 3 → 4 (Gemini) → 5 (Claude verifies) → 6 → 7 → 8

   **Expected outputs:**
   - Simple mode: `specs/###-name/plan.md` (500-2000 lines)
   - Complex mode (future): `specs/###-name/plan/` directory with manifest

### Step 4: Monitor Progress

8. **Display phase progress to user:**
   ```
   🔍 Planning Mode Activated (Gemini Explorer via Copilot)

   Task: {task_description}
   Mode: {SIMPLE/COMPLEX} ({loc_estimate} LOC estimated)
   Explorer Model: Gemini 2.0 Pro via Copilot

   📋 Phase 1: Task Understanding & Session Initialization...
   📁 Phase 2: Spec Folder Setup...
   🧠 Phase 3: Context Loading...
   📊 Phase 4: Parallel Exploration (4 Gemini agents via Copilot)...
   🔬 Phase 5: Hypothesis Verification (Claude review)...
   📝 Phase 6: Plan Creation...
   👤 Phase 7: User Review & Confirmation...
   💾 Phase 8: Context Persistence...
   ```

---

## Failure Recovery

| Failure Type                | Recovery Action                                          |
| --------------------------- | -------------------------------------------------------- |
| Copilot unavailable         | Fall back to with_claude command                         |
| Gemini model not accessible | Fall back to default Claude explorers                    |
| Task unclear                | Use AskUserQuestion to clarify (handled in YAML Phase 1) |
| Explore agents find nothing | Expand search scope (handled in YAML Phase 4)            |
| Conflicting findings        | Document both perspectives, ask user (YAML Phase 5)      |
| User rejects plan           | Revise based on feedback, resubmit (YAML Phase 7)        |
| Cannot create plan file     | Check permissions, use alternative path (YAML Phase 6)   |
| YAML prompt not found       | Return error with installation suggestion                |

---

## Error Handling

| Condition              | Action                                                                                  |
| ---------------------- | --------------------------------------------------------------------------------------- |
| Empty `$ARGUMENTS`     | Prompt: "Please describe the task you want to plan"                                     |
| Invalid mode override  | Ignore, proceed with auto-detection                                                     |
| YAML file missing      | Return error: "Workflow file missing at .opencode/command/plan/assets/{mode}_mode.yaml" |
| Explore agents timeout | Continue with available results (handled in YAML)                                       |
| Plan file exists       | Ask to overwrite or create new version (handled in YAML Phase 6)                        |
| Copilot not configured | Error: "OpenCode Copilot not configured. Run setup or use /plan:with_claude"            |

---

## Example Usage

### Basic Planning (Auto-Detect Mode)
```bash
/plan:with_gemini Add user authentication with OAuth2
# Uses Gemini 2.0 Pro agents via Copilot for exploration
```

### Explicit Simple Mode
```bash
/plan:with_gemini "Refactor authentication (800 LOC)" mode:simple
# Forces SIMPLE mode despite LOC estimate
```

---

## Example Output

```
🔍 Planning Mode Activated (Gemini Explorer via Copilot)

Task: Add user authentication with OAuth2
Mode: SIMPLE (300 LOC estimated)
Explorer Model: Gemini 2.0 Pro via Copilot

📋 Phase 1: Task Understanding & Session Initialization
  ✓ Task parsed: Implement OAuth2 authentication flow
  ✓ SESSION_ID extracted: abc123

📁 Phase 2: Spec Folder Setup
  ✓ Creating new spec folder: specs/042-oauth2-auth/
  ✓ Marker set: .spec-active.abc123

🧠 Phase 3: Context Loading
  ℹ No previous memory files found - starting fresh

📊 Phase 4: Parallel Exploration (4 Gemini agents via Copilot)
  ├─ Architecture Explorer (Gemini 2.0): analyzing project structure...
  ├─ Feature Explorer (Gemini 2.0): finding auth patterns...
  ├─ Dependency Explorer (Gemini 2.0): mapping imports...
  └─ Test Explorer (Gemini 2.0): reviewing test infrastructure...
  ✅ Exploration Complete (31 files identified)

🔬 Phase 5: Hypothesis Verification (Claude review)
  ├─ Verifying Gemini hypotheses...
  ├─ Cross-referencing agent findings...
  └─ Building complete mental model...
  ✅ Verification Complete

📝 Phase 6: Plan Creation
  ✓ Plan file created: specs/042-oauth2-auth/plan.md

👤 Phase 7: User Review & Confirmation
  Please review and confirm to proceed.
  [User confirms]
  ✓ Plan re-read (no edits)

💾 Phase 8: Context Persistence
  ✓ Context saved: specs/042-oauth2-auth/memory/29-11-25_14-30__oauth2-auth.md

STATUS=OK ACTION=plan_created PATH=specs/042-oauth2-auth/plan.md
```

---

## Notes

- **Gemini via Copilot Integration:**
  - Uses OpenCode's Copilot integration for Gemini model access
  - Spawns agents via Task tool with Gemini model specification
  - Same parallel architecture as Claude Code (4 agents in single message)
  - Gemini provides alternative AI perspective on code patterns

- **Model Hierarchy:**
  - Orchestrator: Claude (task understanding, verification, synthesis)
  - Explore Agents: Gemini 2.0/3.0 Pro via Copilot (fast parallel discovery)
  - Task tool routes to Gemini via OpenCode's Copilot configuration

- **Why Gemini for Exploration:**
  - Alternative AI perspective on code patterns
  - Potential Google Search integration (if enabled in Copilot config)
  - Multimodal understanding capabilities
  - Different training data and strengths than Claude/GPT
  - May excel at newer technologies where web research helps
  - Parallel execution keeps total time low

- **Performance:**
  - Exploration: ~20-40 seconds (4 Gemini agents via Copilot)
  - Verification: ~15-30 seconds (Claude)
  - Plan creation: ~10-20 seconds
  - **Total**: ~45-90 seconds

- **When to Use:**
  - Want alternative AI perspective on codebase
  - Implementing newer technologies where Gemini might excel
  - Gemini's multimodal capabilities might provide unique insights
  - Comparing different planning approaches
  - Have OpenCode with Copilot configured for Gemini access

- **Integration:**
  - Works with spec folder system (Phase 2)
  - Memory context enables session continuity (Phases 3 & 8)
  - Plans feed into `/spec_kit:implement` workflow
  - Can be used alongside `/plan:with_claude` or `/plan:with_codex` for comparison

- **Copilot Requirements:**
  - OpenCode with Copilot integration enabled
  - Copilot subscription with Gemini model access
  - Proper model routing configuration in OpenCode
  - Optional: Google Search integration for enhanced research

- **Potential Web Research:**
  - Gemini may leverage Google Search (if configured in Copilot)
  - Can research current best practices and documentation
  - Validates patterns against industry standards
  - Finds relevant examples and resources
  - Web findings are always verified against actual codebase

---

**Remember**: This command uses Gemini models via Copilot for exploration, providing an alternative perspective to Claude-based planning with potential web research capabilities. Gemini findings (including any web research) are always verified by Claude reading actual code before inclusion in plans.
