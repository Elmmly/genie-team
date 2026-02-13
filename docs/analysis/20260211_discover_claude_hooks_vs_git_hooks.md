---
type: discover
concept: quality-enforcement
topic: claude-hooks-vs-git-hooks-boundaries
status: active
created: 2026-02-11
author: scout
---

# Opportunity Snapshot: Claude Hooks vs Git Hooks for Deterministic Quality Outcomes

## 1. Discovery Question

**Original:** How might we use Claude hooks for improved deterministic outcomes for quality, spec & architecture alignment, lint, etc vs what belongs in git hooks?

**Reframed:** Where does AI-time enforcement (while Claude is generating) create higher-value quality outcomes than commit-time enforcement (when code is being saved), and how do we avoid duplicating concerns across both systems?

## 2. Observed Behaviors / Signals

### Current State: Two Hook Systems

**Git hooks (via pre-commit framework):**
- `.pre-commit-config.yaml` with 4 tiers of validation
- Tier 1: Syntax linters (YAML, JSON, trailing whitespace, shellcheck)
- Tier 2: Schema validation (frontmatter field/type checking)
- Tier 3: Cross-reference integrity (spec_ref, adr_refs point to real files)
- Tier 4: Source/installed copy sync (currently disabled)
- Runs at `git commit` time — after all work is done
- Fully deterministic — same input always produces same output
- `.github/workflows/lint.yml` runs these in CI too

**Claude hooks (3 existing scripts):**
- `track-command.sh` — UserPromptSubmit: captures slash command invocations, writes session state
- `reinject-context.sh` — SessionStart (compact|clear): re-injects session context after compaction
- `track-artifacts.sh` — PostToolUse (Write): tracks file paths written during session
- All are observational — none currently enforce or block anything

**Skills (8 active):**
- `spec-awareness` — Guides spec loading/writing behavior during commands
- `architecture-awareness` — Guides ADR and C4 diagram behavior
- `brand-awareness` — Guides brand consistency
- `code-quality` — Code quality standards
- `tdd-discipline` — Red-green-refactor enforcement
- `problem-first` — Problem-first framing
- `pattern-enforcement` — Project pattern adherence
- `conventional-commits` — Commit message format

### Key Observation: Skills Are Soft, Hooks Are Hard

Skills are prompt instructions — Claude follows them most of the time, but they're not deterministic. A skill says "you should load the spec" but can't guarantee Claude actually does. Git hooks are hard gates — code literally cannot be committed if validation fails. Claude hooks sit in between: they can be hard gates (exit 2 blocks the action) or soft signals (stdout adds context).

## 3. Pain Points / Friction Areas

### Pain Point 1: Spec Alignment Is Only Verified at Review Time

Today, spec compliance is checked during `/discern` (Critic reviews against ACs). But by then, the entire implementation is done. If the implementation drifted from the spec, the feedback loop is long — go back to Crafter, re-implement, re-review.

**Workaround:** The `spec-awareness` skill tells Crafter to "use spec ACs as TDD test targets," but this is a suggestion, not enforcement.

### Pain Point 2: Architecture Decisions Are Advisory

The `architecture-awareness` skill tells genies to "read ADRs" and "warn if violating an accepted decision." But there's no mechanism to verify at Write/Edit time that a code change actually follows an ADR.

### Pain Point 3: Document Trail Quality Is Only Checked at Commit Time

Pre-commit hooks catch broken cross-references and invalid frontmatter — but only when the user commits. During a long `/deliver` session, Claude might write 15 files with broken refs before the commit gate catches them.

### Pain Point 4: No Feedback Loop Between Test Results and Quality Gates

When Crafter runs tests and they fail, there's no hook that says "tests failed — don't proceed to the next phase." The TDD discipline is entirely prompt-driven.

### Pain Point 5: Post-Compaction Loss of Enforcement Context

After compaction, skills reload from prompts but the nuanced "remember to check ADR-015 for this specific implementation" context is lost. The `reinject-context.sh` hook partially addresses this but only for command/backlog context, not for enforcement state.

## 4. JTBD / User Moments

**Primary Job:** "When I'm running an autonomous genie session, I want deterministic quality enforcement at the moment problems are introduced so I can catch drift before it compounds into review failures."

**Secondary Job:** "When I commit work, I want validation that confirms the genie session produced structurally sound artifacts so I can trust the document trail."

**Tertiary Job:** "When a genie writes or edits a file, I want immediate feedback about spec/architecture alignment so the genie can self-correct in the same turn."

## 5. Assumptions & Evidence

| Assumption | Type | Confidence | Evidence For | Evidence Against |
|------------|------|------------|--------------|------------------|
| Claude hooks can block file writes effectively | feasibility | high | Claude Code docs confirm PreToolUse can deny Write/Edit with exit 2 | None — well-documented feature |
| Real-time enforcement reduces review failures | value | medium | Shorter feedback loops are generally better (CI/CD principles) | Could slow down generation significantly |
| Spec alignment can be checked deterministically | feasibility | medium | Frontmatter fields are parseable; AC ids can be grepped in test files | Semantic alignment (does the code actually implement the AC?) requires LLM judgment |
| Prompt-based hooks can do semantic validation | feasibility | high | Claude Code supports `type: "prompt"` hooks using Haiku for judgment | Adds latency and cost per tool use |
| Git hooks remain necessary even with Claude hooks | viability | high | CI pipelines, manual edits, non-Claude commits all bypass Claude hooks | None |
| Users want real-time enforcement during autonomous sessions | value | high | The discovery request explicitly asks for "improved deterministic outcomes" | Some users may prefer speed over safety |
| Hook-level enforcement complements skill-level guidance | value | high | Skills guide behavior; hooks verify outcomes — different layers | Could create friction if hooks are too strict |

## 6. Technical Signals

- **Feasibility:** straightforward for structural checks, moderate for semantic checks
- **Constraints:**
  - Command hooks must be fast (block tool execution)
  - Prompt/agent hooks add ~1-5s latency per invocation
  - Hooks have no shared state between invocations (stateless)
  - Hook scripts receive JSON stdin with tool_name and tool_input
  - PreToolUse can modify tool input (e.g., fix a file path before write)
  - PostToolUse can provide feedback but can't undo the action
  - Stop hooks can block session completion (force re-check)
- **Needs Architect spike:** no — capabilities are well-documented

## 7. Opportunity Areas (Unshaped)

### Opportunity Area A: Write-Time Structural Validation

**Problem territory:** When Claude writes a markdown file to `docs/`, the document might have broken frontmatter, missing required fields, or broken cross-references. Today this is only caught at commit time.

Claude hook approach: A PreToolUse hook on Write/Edit that validates frontmatter before the file is written. Could deny the write and tell Claude what's wrong, letting it self-correct immediately.

### Opportunity Area B: Spec-Driven Test Verification

**Problem territory:** After Crafter writes tests (RED phase), there's no verification that test descriptions actually reference spec ACs. The TDD discipline skill says to do it, but doesn't verify.

Claude hook approach: A PostToolUse hook on Write (matching test file patterns) that checks test descriptions contain expected AC ids from the active spec. Provides feedback to Claude if ACs are missing test coverage.

### Opportunity Area C: Architecture Alignment Gate

**Problem territory:** When Claude edits or creates source code files, there's no check that the code respects ADR constraints (e.g., "auth must stay in its own service boundary").

Claude hook approach: A prompt-based or agent-based PreToolUse hook that reads relevant ADRs and asks "does this file change respect ADR-NNN?" More expensive but catches architectural drift in real-time.

### Opportunity Area D: Phase Gate Enforcement

**Problem territory:** The 7 D's workflow assumes genies follow phase transitions properly (shaped → designed → implemented → reviewed). But nothing prevents Crafter from writing code when the backlog item is still in `shaped` status.

Claude hook approach: A PreToolUse hook that checks backlog item status before allowing source code writes during `/deliver`. If status isn't `designed`, deny the write.

### Opportunity Area E: Post-Session Quality Summary

**Problem territory:** When a long autonomous session ends, the user has no summary of whether quality standards were maintained throughout.

Claude hook approach: A Stop hook that runs a quality report — checks all files written during the session for frontmatter validity, cross-reference integrity, and test coverage metrics.

## 8. Boundary Analysis: What Belongs Where

### Principle: **Claude Hooks Enforce During Generation; Git Hooks Verify Before Persistence**

| Concern | Claude Hook (Generation-Time) | Git Hook (Commit-Time) | Both? |
|---------|-------------------------------|------------------------|-------|
| YAML frontmatter syntax | PreToolUse on Write — fast, prevents bad writes | pre-commit Tier 1 — catches manual edits | Yes, complementary |
| Frontmatter schema validation | PreToolUse on Write — prevents invalid docs | pre-commit Tier 2 — catches non-Claude changes | Yes, complementary |
| Cross-reference integrity | PostToolUse on Write — feedback on broken refs | pre-commit Tier 3 — hard gate before commit | Yes, complementary |
| Spec AC coverage in tests | PostToolUse on Write (test files) — real-time feedback | Not currently checked | Claude hook only |
| ADR compliance | Prompt-based PreToolUse — semantic check | Not feasible deterministically | Claude hook only |
| Phase gate (status checks) | PreToolUse on Write/Edit — structural check | Not relevant (git doesn't know about phases) | Claude hook only |
| Trailing whitespace / EOF | Not worth the latency | pre-commit standard hook | Git hook only |
| JSON/YAML syntax | Not worth the latency for non-doc files | pre-commit standard hook | Git hook only |
| shellcheck | Not worth the latency | pre-commit standard hook | Git hook only |
| Source/installed sync | Not applicable during generation | pre-commit Tier 4 | Git hook only |
| Conventional commit format | Already a skill | Could add commitlint | Optional overlap |
| TDD phase discipline | Stop hook — verify tests before proceeding | Not feasible | Claude hook only |
| Post-session quality report | Stop hook — summary report | Not applicable | Claude hook only |

### Tier Model for Claude Hooks

Mirroring the git hook tier model:

| Tier | Type | Latency | Examples |
|------|------|---------|----------|
| **C1: Structural gates** | command (shell) | <100ms | Frontmatter syntax, required fields, broken refs, phase gate |
| **C2: Coverage checks** | command (shell) | <200ms | Spec AC test coverage, artifact tracking completeness |
| **C3: Semantic alignment** | prompt (Haiku) | 1-5s | ADR compliance, spec behavioral alignment |
| **C4: Session quality** | command (shell) | <500ms | Stop hook — end-of-session quality report |

### What NOT to Put in Claude Hooks

- **Formatting/linting** — Too noisy, too frequent. Let git hooks handle trailing whitespace, shellcheck, JSON syntax. Claude hooks should focus on high-value, AI-specific enforcement.
- **Style opinions** — Skills handle these as guidance. Don't block writes over naming conventions.
- **Anything that duplicates git CI** — Git hooks and CI are the last line of defense. Claude hooks are the first line. Don't create identical gates in both places — let each layer focus on its strength.

## 9. Evidence Gaps

- **Latency impact:** How much does a PreToolUse command hook add to each Write operation? Need to benchmark with realistic scripts.
- **False positive rate:** Will structural validation hooks block legitimate writes too often? Need to prototype and measure.
- **Prompt hook accuracy:** Can Haiku reliably assess ADR compliance in 1-5 seconds? Need to test with real ADRs and code changes.
- **Stop hook reliability:** Does the Stop hook fire reliably in all session end scenarios (including crashes, timeouts)?
- **Autonomous session impact:** In headless mode, do hooks work the same way? (PermissionRequest hooks don't fire in headless mode — PreToolUse does.)

## 10. Routing Recommendation

- [x] **Ready for Shaper** — Problem well-understood, multiple opportunity areas identified
- [ ] Continue Discovery — More exploration needed
- [ ] Needs Architect Spike — Technical feasibility unclear
- [ ] Needs Navigator Decision — Strategic question

**Rationale:** The boundary between Claude hooks and git hooks is clear: Claude hooks enforce during AI generation (catching drift early), git hooks enforce at commit time (catching everything else). The opportunity areas are concrete and shapeable. The technical feasibility is well-documented — Claude Code's hook system supports all the patterns needed.

**Recommended shaping order:**
1. **Opportunity A** (write-time structural validation) — highest value, lowest risk, most deterministic. Reuses existing pre-commit hook logic.
2. **Opportunity E** (post-session quality summary) — high value for autonomous sessions, low risk.
3. **Opportunity B** (spec-driven test verification) — moderate value, straightforward implementation.
4. **Opportunity D** (phase gate enforcement) — moderate value, simple structural check.
5. **Opportunity C** (architecture alignment gate) — highest value but highest cost/risk due to LLM judgment dependency.
