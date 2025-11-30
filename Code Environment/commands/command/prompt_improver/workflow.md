---
description: Enhance prompts using DEPTH framework with AI-guided analysis and quality scoring
argument-hint: "<prompt-text> [:quick|:improve|:refine]"
allowed-tools: Read, Write, AskUserQuestion
---

# Improve Prompt - DEPTH Framework

Transform raw prompts into optimized, framework-structured prompts using DEPTH methodology (Discover, Engineer, Prototype, Test, Harmonize).

## Input

```text
$ARGUMENTS
```

---

## Purpose

Apply systematic prompt enhancement with:
- **Framework selection** - Auto-select from 7 frameworks (RCAF, COSTAR, RACE, CIDI, TIDD-EC, CRISPE, CRAFT)
- **Quality scoring** - CLEAR evaluation (50-point scale)
- **Dual output** - SpecKit spec.md + YAML prompt for comprehensive documentation

---

## Contract

**Input:** `$ARGUMENTS` = prompt text + optional mode (`:quick`, `:improve`, `:refine`)

**Output:** Always creates spec folder with both files:
1. **spec.md** - SpecKit specification with enhanced prompt (Problem, Solution, Enhanced Prompt, Success Criteria)
2. **enhanced_prompt.yaml** - Machine-readable YAML for direct workflow integration

**Location:** User-selected spec folder (A/B/C/D choice following SpecKit workflow)

**Modes:**
- **:quick** - Fast enhancement (1-5 rounds, auto-framework, <10s)
- **:improve** - Full DEPTH (10 rounds, interactive framework selection)
- **:refine** - Polish existing prompt (preserve framework, focus on clarity)
- **Default** - Interactive mode with full user participation

**Status:** `STATUS=OK SPEC={folder} FILES={spec.md,enhanced_prompt.yaml}` or `STATUS=ERROR|CANCELLED`

---

## Instructions

### Phase 1: Parse Input

1. **Extract mode and prompt:**
   ```
   If $ARGUMENTS ends with :quick/:improve/:refine:
     mode = [detected mode]
     prompt_text = $ARGUMENTS minus mode flag
   Else:
     mode = "interactive"
     prompt_text = $ARGUMENTS
   ```

2. **Validate prompt:**
   - If empty: Use AskUserQuestion with options (paste text / describe intent / file path / cancel)
   - Store: `original_prompt`, `original_length`, `mode`, `timestamp_start`

3. **Spec folder selection (follows standard SpecKit workflow):**
   - Find next spec number: `ls -d specs/[0-9]*/ | sed 's/.*\/\([0-9]*\)-.*/\1/' | sort -n | tail -1`
   - Suggest name: `enhanced-prompt` or based on prompt content
   - Use AskUserQuestion with 4 options (A/B/C/D pattern from AGENTS.md):
     - **A)** Use existing spec folder (if .spec-active exists)
     - **B)** Create new spec folder: `specs/[###]-[suggested-name]/`
     - **C)** Update related spec (show any existing prompt-related specs)
     - **D)** Skip documentation (creates `.claude/.spec-skip` marker) - NOT RECOMMENDED
   - Store: `spec_folder_path`, `spec_folder_choice`

---

### Phase 2-5: Execute DEPTH Workflow

3. **Invoke workflow YAML** (search order: `.claude/commands/prompt_improver/assets/improve_prompt.yaml` → `.opencode/command/prompt_improver/assets/improve_prompt.yaml`) with:
   - `prompt_text`: Original prompt
   - `mode`: Detected mode
   - `rounds`: 1-5 (quick) or 10 (others)
   
   **Fallback logic:** If not found in `.claude/`, automatically search `.opencode/` folder.

4. **DEPTH phases execute autonomously:**
   - **D (Discover)**: Analyze intent, assess complexity (1-10), identify RICCE gaps
   - **E (Engineer)**: Select framework, apply cognitive rigor, restructure
   - **P (Prototype)**: Generate enhanced draft, validate RICCE (5/5)
   - **T (Test)**: Calculate CLEAR scores (original vs enhanced)
   - **H (Harmonize)**: Final polish, verify ≥40/50 target

5. **Framework selection logic** (auto or interactive based on complexity):
   - Complexity 1-4: Auto-select RCAF
   - Complexity 5-6: Prompt user (RCAF / COSTAR / TIDD-EC)
   - Complexity 7: Prompt user (RCAF streamlined / CRAFT comprehensive)
   - Complexity 8-10: Auto-select CRAFT

6. **Quality validation:**
   ```
   If enhanced_score >= 40 AND delta >= 5:
     Proceed to Phase 6
   Else if mode = "quick" AND enhanced_score > original_score:
     Proceed to Phase 6
   Else:
     AskUserQuestion: Retry refinement / Accept current / Cancel
   ```

---

### Phase 6: Dual Output Generation

**See workflow YAML Phase 6 for complete workflow (searched in `.claude/` then `.opencode/`).**

7. **Use spec folder from Phase 1 step 3:**
   ```
   # Spec folder already determined by user choice (A/B/C/D)
   base_path = {spec_folder_path from Phase 1}

   # If user selected D (skip), fall back to /export/
   If spec_folder_path is empty:
     base_path = /export/
     Use sequential numbering: [###]-enhanced-prompt/
   ```

8. **Write both output files to spec folder:**
   - **File 1 - spec.md** (SpecKit specification format):
     - Front matter with metadata
     - Problem statement (why enhancement needed)
     - Solution (DEPTH methodology summary)
     - Framework applied (description and rationale)
     - Enhanced Prompt (full formatted text)
     - Success Criteria (CLEAR scores, RICCE validation)
     - Usage instructions

   - **File 2 - enhanced_prompt.yaml** (machine-readable):
     - Metadata section (framework, complexity, scores, timestamps)
     - Framework-specific prompt components
     - Usage examples for Python/Node.js

9. **Report success:**
   ```
   ✅ Enhanced prompt created successfully!

   📁 Spec folder: {spec_folder_path}
   📄 Files created:
   - spec.md (SpecKit specification)
   - enhanced_prompt.yaml (machine-readable)

   📊 Quality:
   - Original CLEAR Score: {original_score}/50
   - Enhanced CLEAR Score: {enhanced_score}/50
   - Improvement: +{delta} points

   🔧 Framework: {framework_name}

   STATUS=OK SPEC={spec_folder_path} FILES=spec.md,enhanced_prompt.yaml
   ```

---

## CLEAR Scoring (50 points)

| Dimension       | Weight | Max | Description                          |
|-----------------|--------|-----|--------------------------------------|
| Correctness (C) | 20%    | 10  | Accuracy, terminology                |
| Logic (L)       | 20%    | 10  | Reasoning structure, coherence       |
| Expression (E)  | 30%    | 15  | Clarity, precision, readability      |
| Arrangement (A) | 20%    | 10  | Organization, hierarchy              |
| Reusability (R) | 10%    | 5   | Adaptability, modularity             |

**Target:** ≥40/50 overall, ≥8/10 per dimension (≥12/15 for Expression)

---

## RICCE Validation

Enhanced prompt must contain:
- ✅ **Role** - Clearly defined persona/expertise
- ✅ **Instructions** - Unambiguous tasks/steps
- ✅ **Context** - Relevant background info
- ✅ **Constraints** - Explicit boundaries/requirements
- ✅ **Examples** - Concrete demonstrations (or N/A if not applicable)

---

## Framework Quick Reference

| Framework | Components | Best For | Complexity |
|-----------|-----------|----------|------------|
| **RCAF** | role, context, action, format | General-purpose | 1-6 |
| **COSTAR** | context, objective, style, tone, audience, response | Communication | 5-6 |
| **RACE** | role, action, context, examples | Rapid prototyping | 3-5 |
| **CIDI** | context, instructions, details, input | Creative/ideation | 4-6 |
| **TIDD-EC** | task, instructions, details, deliverables, examples, constraints | Technical specs | 5-7 |
| **CRISPE** | capacity, role, insight, statement, personality, experiment | System prompts | 4-6 |
| **CRAFT** | context, role, action, format, target | Multi-stakeholder | 7-10 |

---

## Error Recovery

| Condition | Action |
|-----------|--------|
| Empty prompt | AskUserQuestion with 4 options → Retry |
| Score below target | Prompt: retry / accept / cancel |
| Framework timeout | Default to RCAF → Notify → Continue |
| YAML not found | Search `.claude/commands/` first, then `.opencode/command/` → Error if both fail |
| Write permission denied | Output to chat → Suggest manual save |

---

## Examples

### Quick Mode
```bash
/prompt_improver:workflow:quick "Analyze user feedback"
```
Output: 3-5 rounds, RCAF framework, ~5 seconds

### Interactive Mode
```bash
/prompt_improver:workflow "Review code for architecture and performance"
```
Output: 10 rounds, user selects framework (complexity 5-6), ~12 seconds

### Refine Mode
```bash
/prompt_improver:workflow:refine "Role: Data scientist. Task: Analyze IoT sensor data..."
```
Output: Preserves existing framework, polishes clarity, ~9 seconds

---

## Critical Rules

- ✅ Execute full DEPTH (10 rounds) unless :quick mode
- ✅ Calculate CLEAR scores rigorously (no fabrication)
- ✅ Generate BOTH files (analysis.md + prompt.yaml)
- ✅ Replace all placeholders in YAML (no `{ACTUAL_*}` text in output)
- ✅ Validate RICCE completeness (5/5 or 4/5 with N/A)
- ❌ NEVER skip framework selection rationale
- ❌ NEVER leave placeholder text in YAML output
- ❌ NEVER proceed with <40/50 without user confirmation

---

## Notes

**Dual-Output Architecture:**
- `prompt_analysis.md` = Human review (quality assessment, RICCE, framework rationale)
- `enhanced_prompt.yaml` = Machine import (direct use in workflows/tools)
- Both files reference each other for traceability

**Integration:**
- Saves to active spec folder if available (`.claude/.spec-active.$$` or `.opencode/.spec-active.$$`)
- Falls back to `/export/` with sequential numbering
- YAML format enables direct import: `yaml.safe_load(open('enhanced_prompt.yaml'))`

**Workflow Details:**
- Complete implementation: `improve_prompt.yaml` (in `.claude/commands/` or `.opencode/command/`)
- Phase 6 (Dual Output): Steps 13-17 with atomic write guarantees
- Framework templates: All 7 frameworks fully specified
