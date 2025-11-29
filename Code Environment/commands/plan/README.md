# Plan Commands Overview

Comprehensive planning commands using different AI exploration strategies via OpenCode Copilot.

---

## Available Commands

| Command | Platform | Explorer | Best For |
|---------|----------|----------|----------|
| `/plan:with_claude` | OpenCode | Claude agents (default) | General purpose, balanced exploration |
| `/plan:with_codex` | OpenCode | GPT-4o/5.1 via Copilot | Alternative AI perspective, GPT's pattern recognition |
| `/plan:with_gemini` | OpenCode | Gemini 2.0/3.0 Pro via Copilot | Alternative AI perspective, potential web research |

---

## Quick Decision Guide

### Exploration Strategy Selection

**Use `/plan:with_claude` when:**
- Default choice for most planning tasks
- Want proven Claude exploration quality
- Codebase is well-documented in code
- No need for alternative perspectives

**Use `/plan:with_codex` when:**
- Want GPT's perspective on code patterns
- GPT may excel at specific language patterns
- Comparing different planning approaches
- Have Copilot configured for GPT access

**Use `/plan:with_gemini` when:**
- Want Gemini's perspective on code patterns
- Implementing newer technologies
- Gemini's multimodal capabilities might help
- Potential web research needs (if enabled)
- Have Copilot configured for Gemini access

---

## Architecture Comparison

### with_claude (Claude agents)

```
Orchestrator: Claude
   ↓ spawns 4 parallel agents via Task tool
Explorers: Claude agents × 4 (Architecture, Feature, Dependency, Test)
   ↓ return findings (hypotheses, file paths, patterns)
Verification: Claude reads files, verifies hypotheses
   ↓
Plan Creation: Template-based plan.md generation
```

**Characteristics:**
- Proven exploration quality
- Fast parallel agent spawning
- 35-75 seconds typical duration

### with_codex (GPT via Copilot)

```
Orchestrator: Claude
   ↓ spawns 4 parallel agents via Task tool + Copilot
Explorers: GPT-4o/5.1 agents via Copilot × 4
   ↓ return findings (hypotheses, file paths, patterns)
Verification: Claude reads files, verifies hypotheses
   ↓
Plan Creation: Template-based plan.md generation
```

**Characteristics:**
- Alternative AI perspective (GPT)
- Same parallel architecture as Claude agents
- GPT strength in code pattern recognition
- 40-85 seconds typical duration

### with_gemini (Gemini via Copilot)

```
Orchestrator: Claude
   ↓ spawns 4 parallel agents via Task tool + Copilot
Explorers: Gemini 2.0/3.0 Pro agents via Copilot × 4
   ↓ return findings (hypotheses, file paths, patterns, potential web research)
Verification: Claude reads files, verifies hypotheses
   ↓
Plan Creation: Template-based plan.md generation
```

**Characteristics:**
- Alternative AI perspective (Gemini)
- Potential Google Search integration (if enabled in Copilot)
- Multimodal capabilities
- Same parallel architecture as Claude agents
- 45-90 seconds typical duration

---

## Common Features

All commands share these capabilities:

### 1. Mode Detection
- Automatic LOC estimation from task description
- Simple mode (<500 LOC) → single plan.md file
- Complex mode (≥500 LOC) → multi-file structure (future)
- Manual override: append `mode:simple` or `mode:complex`

### 2. Spec Folder Integration
- Works with spec folder system
- Respects `.spec-active` markers
- Integrates with workflows-save-context
- Compatible with `/spec_kit:implement`

### 3. Exploration Phases
1. **Task Understanding**: Parse input, validate description
2. **Spec Folder Setup**: Determine working folder
3. **Context Loading**: Load previous session memory (if exists)
4. **Parallel Exploration**: 4 specialized explorers (architecture model varies)
5. **Hypothesis Verification**: Read files, verify findings
6. **Plan Creation**: Template-based generation
7. **User Review**: Wait for confirmation
8. **Context Persistence**: Save session memory

### 4. Quality Guarantees
- All hypotheses verified by reading actual code
- File paths include line numbers
- No placeholder text in final plans
- Risk assessment documented
- Template compliance validated

---

## Usage Examples

### Basic Planning
```bash
# Default (Claude explorers)
/plan:with_claude Add user authentication with OAuth2

# GPT explorers via Copilot
/plan:with_codex Add user authentication with OAuth2

# Gemini explorers via Copilot
/plan:with_gemini Add user authentication with OAuth2
```

### Mode Override
```bash
# Force simple mode despite LOC estimate
/plan:with_claude "Large refactor (800 LOC)" mode:simple

# Explicit complex mode (future)
/plan:with_gemini "System redesign" mode:complex
```

### Comparison Strategy
For critical features, consider running multiple commands:
```bash
# Get Claude perspective
/plan:with_claude Implement real-time collaboration

# Compare with GPT perspective
/plan:with_codex Implement real-time collaboration

# Validate with Gemini (+ potential web research)
/plan:with_gemini Implement real-time collaboration
```

Then review all three plans to identify:
- Differences in approach
- Overlooked integration points
- Alternative implementation strategies
- Current best practices (Gemini with search)

---

## Installation Requirements

### OpenCode (with_claude)
**Requirements:**
- OpenCode CLI
- Task tool support

**Validation:**
```bash
# Should work in OpenCode environment
/plan:with_claude test task
```

### OpenCode (with_codex)
**Requirements:**
- OpenCode CLI
- OpenCode Copilot integration enabled
- GitHub Copilot subscription (for GPT model access)
- Proper model routing configuration

**Validation:**
```bash
# Verify Copilot integration and GPT model access
# Test with simple task
/plan:with_codex test task
```

### OpenCode (with_gemini)
**Requirements:**
- OpenCode CLI
- OpenCode Copilot integration enabled
- Copilot subscription with Gemini model access
- Proper model routing configuration

**Validation:**
```bash
# Verify Copilot integration and Gemini model access
# Test with simple task
/plan:with_gemini test task
```

---

## Performance Benchmarks

| Command | Typical Duration | Maximum |
|---------|-----------------|---------|
| with_claude | 35-75 seconds | 90 seconds |
| with_codex | 40-85 seconds | 100 seconds |
| with_gemini | 45-90 seconds | 110 seconds |

**Factors affecting duration:**
- Codebase size
- Number of files to explore
- Model response times via Copilot
- Web research depth (Gemini, if enabled)

---

## Troubleshooting

### Error: GPT model not accessible via Copilot
**Problem:** `with_codex` command fails to spawn GPT agents

**Solutions:**
1. Verify OpenCode Copilot integration is enabled
2. Check GitHub Copilot subscription includes GPT model access
3. Review model routing configuration in OpenCode
4. Use `/plan:with_claude` as fallback

### Error: Gemini model not accessible via Copilot
**Problem:** `with_gemini` command fails to spawn Gemini agents

**Solutions:**
1. Verify OpenCode Copilot integration is enabled
2. Check Copilot subscription includes Gemini model access
3. Review model routing configuration in OpenCode
4. Use `/plan:with_claude` as fallback

### Exploration timeout
**Problem:** Agents exceed timeout

**Solutions:**
1. Command automatically uses partial results
2. Gaps documented in plan
3. Manual exploration recommended for missing areas

### Task tool unavailable
**Problem:** Cannot spawn exploration agents

**Solutions:**
1. Command falls back to manual exploration
2. Use Glob/Grep directly
3. Inline planning without exploration

---

## File Structure

```
.opencode/command/plan/         # OpenCode
├── README.md                   # This file
├── with_claude.md              # Claude-based exploration (default)
├── with_codex.md               # GPT via Copilot exploration
├── with_gemini.md              # Gemini via Copilot exploration
└── assets/
    ├── simple_mode.yaml        # Simple mode workflow
    ├── complex_mode.yaml       # Complex mode workflow (stub)
    ├── base_phases.yaml        # Shared phases 1-3, 7-8
    └── exploration.yaml        # Phases 4-5
```

---

## Future Enhancements

### Planned Features
1. **Complex Mode Implementation**
   - Multi-file plan/ directory structure
   - Manifest.json for navigation
   - Section-specific files
   - Target: Features >500 LOC

2. **Hybrid Exploration**
   - Combine multiple explorers (Claude + GPT + Gemini)
   - Aggregate findings from all three
   - Identify consensus and conflicts
   - Best-of-all-worlds planning

3. **Adaptive Mode Selection**
   - Learn from historical planning sessions
   - Refine LOC estimation
   - Adjust complexity scoring
   - Auto-select optimal exploration strategy

---

## Support

**Issues:**
- Model errors: Check Copilot configuration and subscription
- Timeout issues: May need to adjust task complexity estimation
- Agent spawning: Verify Copilot integration is working

**Best Practices:**
1. Start with default (`/plan:with_claude`)
2. Use alternative explorers for second opinions
3. Combine findings when critical decisions needed
4. Always review and edit generated plans
5. Save session memory for future reference

---

**Last Updated:** 2025-11-29
**Version:** 2.0.0 (Corrected Architecture)
**Compatibility:** OpenCode with Copilot integration

**Key Change from v1.0:** Codex and Gemini commands now use Task tool with Copilot model routing instead of CLI skills, matching the parallel agent architecture.
