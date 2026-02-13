---
type: discover
topic: "skill-enforcement-gaps"
status: active
created: "2026-02-13"
---

# Opportunity Snapshot: Skill Enforcement Gaps and Agent Discipline

## 1. Discovery Question

**Original:** Where do genie-team's skills and workflows fail to enforce discipline under pressure?

**Reframed:** When genies operate autonomously — especially in headless mode (ADR-001) — what gaps in skill enforcement allow them to silently cut corners on TDD, verification, or debugging?

## 2. Observed Behaviors / Signals

- Genie-team has 8 skills, but they vary widely in enforcement strength — from hard obligation language (MUST, NEVER, STOP) to soft guidance (should, can, silently skip)
- Only `tdd-discipline` includes an anti-pattern table with explicit stop directives; remaining enforcement skills state rules but don't anticipate the specific excuses an agent generates under context pressure
- Claude Code has a ~15k character budget for skill descriptions in the system prompt; skills exceeding this budget are **silently excluded**
- Skill descriptions that summarize workflow may cause Claude to follow the summary instead of reading the full skill content — a short-circuit reading problem
- Several genie-team patterns are missing entirely: no verification gate before completion claims, no structured debugging protocol, no skill-writing validation methodology
- Agents under context pressure generate predictable rationalizations ("tests after achieve same goal", "too simple to test", "this is different because...") — skills that don't anticipate these are vulnerable

## 3. Pain Points / Friction Areas

### 3.1 Inconsistent Rationalization Blocking

Genie-team's 8 skills vary widely in enforcement strength:

| Enforcement Level | Skills | Pattern |
|---|---|---|
| **Strong obligation** (MUST, NEVER, STOP) | `tdd-discipline`, `spec-awareness`, `architecture-awareness` | Anti-pattern tables, explicit stop directives |
| **Moderate guidance** (enforce, check) | `code-quality`, `conventional-commits`, `pattern-enforcement` | Checklists, safety rules, deviation handling |
| **Permissive** (can, should, silently skip) | `brand-awareness`, `problem-first` | Exception criteria, opt-in behavior |

Only `tdd-discipline` has an "Anti-Patterns to Catch" table that names specific failure modes and prescribes STOP responses. The remaining enforcement skills state rules but don't counter the specific excuses agents generate when taking shortcuts under pressure.

**Evidence:** Side-by-side comparison of all 8 skills confirms the differential is objectively measurable (see Gap Validation section below).

### 3.2 No Verification Gate

Genie-team enforces test-first via `tdd-discipline` but has no standalone gate preventing completion claims without fresh verification. An agent could:
1. Pass tests early in implementation
2. Make further changes (refactoring, cleanup, edge case fixes)
3. Claim "done" without re-running tests

The gap sits between `/deliver` (Crafter completes work) and `/discern` (Critic reviews). In headless autonomous execution (ADR-001), there's no human to ask "did you re-run the tests?"

### 3.3 No Debugging Protocol

When the Crafter encounters failures during `/deliver`, there's no structured debugging discipline. The agent improvises — sometimes productively, sometimes spiraling into repeated failed fix attempts. There is no escalation threshold (e.g., "3 failed attempts = stop and question assumptions").

### 3.4 Single-Pass Code Review

Genie-team's `/discern` (Critic genie) evaluates spec compliance and code quality in a single pass. Separating these into sequential stages — spec compliance first, then code quality — would catch requirement mismatches before investing in detailed style review.

### 3.5 Skill Description Short-Circuit Risk

Current skill description footprint: **1,942 characters total** (descriptions only) — well within the ~15k budget. However, total SKILL.md content is **~51KB across 8 files**. Descriptions already include trigger context ("Use when...") but several also embed functional summaries ("Enforces X", "Ensures Y") that could cause Claude to short-circuit and follow the summary instead of reading the full skill content.

### 3.6 No Skill-Writing Methodology

Genie-team creates skills by authoring markdown. There's no formal methodology for validating that a skill actually changes agent behavior. Every real session is the first test of whether a skill works as intended — testing in production.

### 3.7 Distribution Friction

Genie-team distributes via `install.sh`. Claude Code's native plugin system (`/plugin install`) offers discoverability, update convenience, and ecosystem integration — but requires a different distribution format.

## 4. JTBD / User Moments

**Primary Job:** "When I'm running genies autonomously or in long sessions, I want discipline enforcement that holds up under context pressure so that agents don't silently cut corners on TDD, verification, or debugging."

**Secondary Job:** "When I'm creating or evolving genie-team skills, I want a validated methodology so that I can confirm new skills actually change agent behavior."

**Tertiary Job:** "When I'm distributing genie-team to new projects, I want frictionless installation so that users can adopt without running shell scripts."

## 5. Assumptions & Evidence

| Assumption | Type | Confidence | Evidence For | Evidence Against |
|---|---|---|---|---|
| Agents rationalize away discipline under context pressure | Feasibility | **High** | Predictable rationalizations are well-documented in LLM agent research; obligation language (MUST, STOP) is more effective than suggestion language (should, consider) | No genie-team-specific measurement exists |
| Excuse/reality tables reduce discipline violations | Feasibility | **Moderate** | `tdd-discipline` with its anti-pattern table is the strongest enforcement skill; weaker skills lack this pattern | No controlled study; efficacy may vary by model |
| Skill descriptions cause short-circuit reading if too functional | Usability | **Moderate** | Known failure mode where Claude follows description summaries instead of reading full skill content | Genie-team descriptions already include trigger context; may not be affected |
| Two-stage review catches more issues than single-pass | Value | **Moderate** | Common in human code review — spec compliance first is cheaper than finding requirement gaps after style review | Single-pass may be sufficient for well-shaped work with clear ACs |
| Plugin marketplace would increase adoption | Viability | **Low** | Standard distribution channel for Claude Code extensions | Genie-team's audience may prefer git-based distribution; plugin system is relatively new |
| Verification gate prevents "done without testing" | Value | **Moderate** | Common agent failure mode — treating early test passes as permanent proof of correctness | Genie-team's TDD discipline + Critic review may already catch this |

## 6. Technical Signals

- **Feasibility:** Straightforward for most opportunities — they're markdown prompt engineering changes, not code
- **Constraints:** Skill character budget (~15k) means we can't add unlimited new skills without measuring impact. Current descriptions total ~2k chars, leaving significant headroom, but full skill content at ~51KB may already approach limits depending on how Claude Code loads them
- **Needs Architect spike:** Yes — for skill character budget measurement (how does Claude Code actually load skills? Descriptions only? Full content?)

## 7. Opportunity Areas (Unshaped)

### A. Discipline Hardening

The gap between genie-team's strongest skill (`tdd-discipline` with STOP directives) and weakest (`problem-first` with exception criteria) represents inconsistent enforcement. Agents under pressure will find and exploit the weakest link.

**Problem territory:** How do we bring all enforcement skills to consistent rationalization-blocking strength without making permissive skills (brand-awareness) inappropriately rigid?

### B. Completion Integrity

No mechanism prevents an agent from claiming completion without fresh verification. The gap sits between `/deliver` (Crafter completes work) and `/discern` (Critic reviews). If the Crafter says "done" without re-running tests, the Critic may not catch stale results.

**Problem territory:** Where in the workflow should a verification gate live — in the Crafter's delivery, in a standalone skill, or at the `/discern` handoff boundary?

### C. Debugging Discipline

When agents encounter failures during implementation, they improvise. Sometimes this works; sometimes it produces spiraling fix attempts. There's no structured escalation path (e.g., "3 failed attempts = stop and escalate").

**Problem territory:** Should debugging discipline live as a skill (always-on for all genies), in the Crafter's agent definition, or as a rule?

### D. Review Depth

Single-pass review means spec compliance and code quality compete for attention. For well-shaped work this may be fine; for complex deliveries it may miss requirement gaps obscured by detailed style review.

**Problem territory:** Is genie-team's single-pass review actually failing, or is this a solution to a problem we don't have? Would two-stage review add value or just latency?

### E. Distribution Channel

`install.sh` works but requires running shell scripts. Plugin marketplace offers discoverability, updates, and ecosystem integration — but it's a different distribution model.

**Problem territory:** Is the friction of `install.sh` actually blocking adoption, or would a plugin format just be a convenience improvement?

### F. Skill Authoring Quality

No validation methodology for skills means we're testing in production — every real session is the first test of whether a skill works as intended. This is especially risky for high-enforcement skills where a failure means silent discipline breakdown.

**Problem territory:** How do we validate that a skill actually changes agent behavior before shipping it?

## 8. Gap Validation Results (2026-02-13)

All four opportunity areas were independently validated against genie-team's actual codebase:

### A. Rationalization Blocking — CONFIRMED GAP

Validated by reading all enforcement skills side-by-side:
- `tdd-discipline`: **No gap** — already has MUST/NEVER/STOP language, phase gates, anti-pattern table
- `code-quality`: **HIGH gap** — no STOP language, post-hoc checklist only, allows "I'll fix it later"
- `pattern-enforcement`: **MEDIUM gap** — explicitly allows justified deviations (lines 90-95), no MUST follow
- `problem-first`: **MEDIUM gap** — escape hatch "When to Proceed Without Reframing" (lines 75-80) is exploitable
- Critic agent does NOT check for process discipline violations — only outcomes (test coverage, not TDD compliance)

The differential is objectively measurable, not just perceived.

### B. Verification Gate — CONFIRMED GAP

Validated by tracing the completion path through Crafter → execution report → Critic:
- TDD discipline enforces RED→GREEN but NOT "re-verify GREEN after REFACTOR"
- Execution report schema requires `test_results` but has **no freshness mechanism** (no timestamp for test execution vs last code change)
- Critic CAN run tests (has Bash tool) but the agent definition says to "parse" and "extract" existing test_results
- `/deliver` command shows test running in examples but doesn't enforce it
- **Critical in headless mode:** No human to ask "did you re-run the tests?"

### C. Systematic Debugging — CONFIRMED GAP

Validated by searching for debugging protocols across all agents, commands, rules, and skills:
- Zero matches for attempt counting, escalation thresholds, or root cause protocols
- TDD discipline assumes implementation will eventually succeed — no protocol for when it doesn't
- `/deliver` says "fix before proceeding" — that's the entire guidance
- `/diagnose` is codebase health scanning, NOT in-flight debugging
- Crafter's routing table has generic "Blockers require escalation" but no definition of what constitutes a blocker vs. a debuggable issue

### D. Skill Description Short-Circuit — UNCERTAIN (worth doing, urgency unclear)

Validated by reading all 8 skill descriptions and analyzing Claude Code's skill loading:
- 7/8 skills have functional summaries ("Enforces X", "Ensures Y") — the pattern known to cause short-circuit reading
- **Key uncertainty:** How does Claude Code load skills? If full content is always in context, rewriting descriptions is a hygiene improvement, not a behavioral fix
- No project documentation on Claude Code's skill loading mechanism
- Low cost (~30 min to rewrite 8 descriptions), low risk — worth doing regardless of uncertainty

### Remaining Evidence Gaps

- **No measurement of current discipline violations** — baseline unknown
- **No skill loading analysis** — determines description audit urgency
- **No review effectiveness data** — single-pass vs two-stage `/discern`
- **No cross-model validation** — do rationalization-blocking patterns work equally on haiku vs sonnet?

## 9. Routing Recommendation

- [x] **Ready for Shaper** — Problem territories A, B, C are well-understood and actionable
- [x] **Needs Architect Spike** — Skill character budget measurement (territory A prerequisite)
- [ ] **Continue Discovery** — Evidence gaps for territories D, E, F suggest more data before shaping

**Rationale:** Three opportunity areas (discipline hardening, completion integrity, debugging discipline) are clear problems validated against the codebase. They can be shaped immediately. The skill character budget needs a quick Architect spike to confirm feasibility before adding new skills. Review depth, distribution, and skill authoring methodology need more evidence of actual problems before investment.

### Recommended Sequence

1. `/spike` — Skill character budget: how does Claude Code load skills, and are we near the limit?
2. `/define` — Discipline hardening: add rationalization blocking across enforcement skills
3. `/define` — Verification gate: mandatory fresh verification before completion claims
4. `/define` — Systematic debugging: structured root cause protocol for implementation failures
5. Evidence gathering — Monitor `/discern` outcomes to assess whether two-stage review adds value

### Architecture Context

- **ADR-001 (Thin Orchestrator)** — Relevant because headless/autonomous execution is where discipline enforcement matters most. Agents running via `claude -p` have no human to catch corner-cutting.
- **ADR-002 (Designer Integration)** — Demonstrates the commands + skill + agent pattern that new capabilities should follow.
