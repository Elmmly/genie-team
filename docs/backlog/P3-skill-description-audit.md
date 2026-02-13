---
spec_version: "1.0"
type: shaped-work
id: skill-description-audit
title: "Audit Skill Descriptions to Prevent Short-Circuit Reading"
status: shaped
created: "2026-02-13"
appetite: small
priority: P3
target_project: genie-team
author: shaper
depends_on: []
tags: [skills, optimization, descriptions, meta]
acceptance_criteria:
  - id: AC-1
    description: "All 8 skill descriptions (plus any new skills from concurrent work) have been audited for functional summaries that could cause short-circuit reading"
    status: pending
  - id: AC-2
    description: >-
      Descriptions that embed functional summaries ('Ensures X', 'Enforces Y and Z') have
      been rewritten to focus on activation context ('Use when...') without summarizing what
      the skill does
    status: pending
  - id: AC-3
    description: "No skill description exceeds 200 characters — keeping them trigger-focused and concise"
    status: pending
  - id: AC-4
    description: "Total combined skill description character count is measured and documented, confirming all skills fit within Claude Code's ~15k character budget for the system prompt skill listing"
    status: pending
  - id: AC-5
    description: "Source skills in skills/ directory are updated and synced to .claude/skills/ via install.sh"
    status: pending
---

# Shaped Work Contract: Audit Skill Descriptions to Prevent Short-Circuit Reading

## Problem

Skill descriptions that summarize what the skill does — rather than only describing when to
activate — can cause Claude to follow the summary instead of reading the full skill content.

Example:
- **Bad:** "Dispatches subagent per task with code review" — Claude does ONE review based on the description
- **Good:** "Use when executing independent tasks" — Claude reads the full skill for details

The principle: descriptions should describe **when to activate** (trigger context), never
**what the skill does** (functional summary). When Claude reads a functional summary and thinks
it "knows" what the skill does, it may skip the full SKILL.md content — missing the anti-pattern
tables, RED flags, and detailed guidance.

**Current state:** Genie-team's 8 skill descriptions total ~1,942 characters (well within budget).
All include trigger context ("Use when...") but several also embed functional summaries:

| Skill | Issue |
|---|---|
| `code-quality` | "Ensures error handling, no hardcoded values, proper patterns, and security considerations" — summarizes what it enforces |
| `tdd-discipline` | "Ensures tests are written before implementation" — summarizes the key rule |
| `pattern-enforcement` | "Ensures consistency with established patterns" — summarizes the outcome |

**Evidence:** 7 of 8 skill descriptions contain functional summaries alongside their trigger
context. Whether this is actively causing short-circuit reading in genie-team is uncertain
(see `docs/analysis/20260213_discover_skill_enforcement_gaps.md`, Section 8D), but the fix
is low-cost and low-risk.

## Appetite & Boundaries

- **Appetite:** Small (half day) — reviewing and rewriting 8 short description strings
- **No-gos:**
  - Do NOT change skill content or behavior — descriptions only
  - Do NOT change skill frontmatter fields other than `description`
  - Do NOT change command or agent descriptions (different mechanism)
- **Fixed elements:**
  - Descriptions must still be accurate about activation context
  - Must measure and document total character footprint

## Goals & Outcomes

Claude reliably reads full skill content instead of short-circuiting on description summaries.
Skills trigger correctly based on context, and agents follow the detailed guidance inside each
skill rather than approximating from the description.

## Risks & Assumptions

| Assumption | Type | Fastest Test |
|---|---|---|
| Claude actually short-circuits on functional descriptions | feasibility | Known failure mode with skill descriptions; test with before/after comparison |
| Shorter trigger-only descriptions improve skill usage | usability | Compare agent behavior before/after on same task |
| ~15k char budget applies to genie-team's Claude Code version | feasibility | Check Claude Code documentation or test empirically |

## Solution Sketch

For each skill, rewrite description from:
```
"Enforces X when Y. Ensures A, B, and C."
```
To:
```
"Use when Y or when A, B, C are mentioned."
```

Example transformations:
- `code-quality`: "Enforces code quality standards when writing or editing code..." → "Use when writing, editing, or reviewing code."
- `tdd-discipline`: "Enforces test-driven development with Red-Green-Refactor cycle..." → "Use when writing new code, implementing features, or fixing bugs."
- `pattern-enforcement`: "Enforces project patterns and architecture conventions..." → "Use when designing, implementing, or reviewing code structure."

## Options

| Option | Pros | Cons | Recommendation |
|---|---|---|---|
| Rewrite all 8 descriptions | Consistent, comprehensive | Tiny risk of breaking working triggers | **Recommended** |
| Rewrite only the 3 worst offenders | Lower risk | Inconsistent, leaves potential issues | Not recommended |

## Routing

- [x] **Crafter** — Small appetite, well-understood changes
- [ ] **Architect** — Not needed

---

# Design Spike: Validate Short-Circuit Reading Claims

**Date:** 2026-02-13
**Conducted by:** Architect
**Method:** Claude Code documentation research + genie-team codebase analysis

## Finding 1: Claude Code Uses Two-Phase Skill Loading (Confirmed by Multiple Sources)

Claude Code's documented skill loading mechanism uses progressive disclosure:

1. **Session start:** Skill *descriptions only* are injected into the system prompt (~30-50 tokens per skill)
2. **On invocation:** Full SKILL.md content loads into the conversation

> "In a regular session, skill descriptions are loaded into context so Claude knows what's
> available, but full skill content only loads when invoked."
> — [Claude Code skills documentation](https://code.claude.com/docs/en/skills)

Claude makes skill invocation decisions **exclusively based on descriptions** using LLM
semantic reasoning — no regex, no keyword matching. This is confirmed across multiple
independent analyses of the skill loading mechanism.

## Finding 2: Subagent-Preloaded Skills Bypass the Two-Phase Model Entirely

When a skill is listed in a subagent's `skills:` array, **full content is preloaded at subagent
startup**. The description is irrelevant — the complete SKILL.md is always in context.

Genie-team's subagent skill assignments:

| Genie | Preloaded Skills |
|---|---|
| **Crafter** | spec-awareness, architecture-awareness, code-quality, tdd-discipline, pattern-enforcement |
| **Critic** | spec-awareness, architecture-awareness, brand-awareness, code-quality |
| **Architect** | spec-awareness, architecture-awareness, pattern-enforcement |
| **Tidier** | spec-awareness, code-quality, pattern-enforcement |
| **Scout** | spec-awareness, problem-first |
| **Shaper** | spec-awareness, problem-first |
| **Designer** | spec-awareness, brand-awareness |

**All 8 skills are preloaded in at least one subagent.** When a genie runs via `/deliver`,
`/discern`, `/design`, etc., its skills are fully loaded regardless of their descriptions.

The three skills flagged as problematic in this backlog item — `code-quality`, `tdd-discipline`,
`pattern-enforcement` — are ALL preloaded in the Crafter, which is the primary enforcement context.

**Conclusion: The short-circuit concern does not apply to genie-team's primary execution path
(subagent-based workflow via slash commands).**

## Finding 3: The Actual Risk Is Different Than Described

The backlog item frames the problem as:
> "Claude reads a functional summary and thinks it 'knows' what the skill does, it may skip
> the full SKILL.md content"

This conflates two separate mechanisms:

1. **Invocation decision** (description-based): Claude decides WHETHER to invoke a skill based
   on the description. This happens BEFORE full content loads. A functional summary could
   theoretically cause Claude to feel it "already knows" what the skill does and not invoke it.

2. **Content reading** (post-invocation): Once invoked, full SKILL.md content always loads.
   Claude cannot "skip" content that has been loaded into context.

The real risk is #1 (under-invocation), not #2 (skipping loaded content). But for
subagent-preloaded skills (Finding 2), even risk #1 is irrelevant — full content loads at
startup regardless of invocation decisions.

In **interactive sessions without subagents**, the risk is real but the proposed fix makes it
*worse* (see Finding 4).

## Finding 4: Removing Functional Context Would Hurt Invocation Quality

Multiple authoritative sources explicitly recommend including BOTH what a skill does AND when
to use it in descriptions:

> "Descriptions should include both what the Skill does and when Claude should use it."
> — [How to train Claude Code agents with custom skills](https://www.howdoiuseai.com/blog/2026-02-08-how-to-train-claude-code-agents-with-custom-skills) (Feb 2026)

> "The description quality directly impacts triggering reliability. Be specific about when
> the Skill should activate."
> — [The Complete Guide to Claude Skills](https://tylerfolkman.substack.com/p/the-complete-guide-to-claude-skills)

> "Baseline activation hovers around 50% reliability... Strong trigger descriptions should
> include concrete use cases and technical terms [achieving 80%+ activation]."
> — [Claude Code Agent Skills](https://prg.sh/notes/Claude-Code-Agent-Skills)

The recommended example format from documentation:
```
"Performs thorough code reviews focusing on security, performance, and best practices.
 Use when reviewing pull requests or analyzing code quality."
```

This is **exactly the pattern genie-team already uses**: functional summary + trigger context.

The proposed rewrite strips functional signal from descriptions:
- **Before:** "Enforces code quality standards when writing or editing code. Ensures error handling,
  no hardcoded values, proper patterns, and security considerations."
- **After:** "Use when writing, editing, or reviewing code."

The stripped version would move descriptions from the 80% activation tier toward the 50% tier
by removing the concrete technical terms Claude uses for semantic matching. "Use when writing
code" is too generic to be useful — it matches every coding task but tells Claude nothing about
what specific guidance the skill provides.

## Finding 5: Character Budget Is Real But Irrelevant at Current Scale

| Metric | Value |
|---|---|
| Total description characters | 1,969 |
| Budget (2% of context, fallback 16,000) | ~16,000 |
| Current utilization | 12.3% |
| Headroom for new skills | ~87 more skills at current avg (165 chars each) |

The 200-character limit proposed in AC-3 would force cuts to the three longest descriptions
(architecture-awareness: 364, spec-awareness: 333, brand-awareness: 310) — all of which are
the *knowledge skills* that the backlog's own no-gos exclude from modification.

## Current Description Character Breakdown

| Skill | Characters | Has Functional Summary? |
|---|---|---|
| architecture-awareness | 364 | Yes ("Ensures ADR and C4 diagram behaviors") |
| spec-awareness | 333 | Yes ("Ensures spec-driven behavior") |
| brand-awareness | 310 | Yes ("Ensures brand-consistent behavior") |
| code-quality | 213 | Yes ("Enforces code quality standards... Ensures error handling...") |
| tdd-discipline | 204 | Yes ("Enforces test-driven development... Ensures tests are written...") |
| problem-first | 194 | Yes ("Ensures problem-first framing") |
| pattern-enforcement | 182 | Yes ("Enforces project patterns... Ensures consistency...") |
| conventional-commits | 169 | Mild ("Creates conventional commit messages") |

## Assessment Summary

| Claim in Backlog Item | Verdict | Evidence |
|---|---|---|
| "Claude may skip the full SKILL.md content" when it reads a functional summary | **Partially valid, mischaracterized** | Claude decides whether to invoke based on descriptions alone (confirmed). But once invoked, full content always loads. Subagent-preloaded skills bypass this entirely. |
| 7 of 8 descriptions contain functional summaries | **Validated** | All 8 contain some functional signal; 7 start with "Enforces/Ensures/Creates" |
| Functional summaries cause short-circuit reading | **Disproved** | Multiple sources recommend including functional summaries. Removing them drops activation from ~80% to ~50%. |
| Removing functional summaries improves behavior | **Disproved — makes it worse** | Best practice is "include both what the Skill does and when Claude should use it." Genie-team's descriptions already follow this recommended pattern. |
| Short-circuit reading is the mechanism for skill enforcement gaps | **Disproved** | Enforcement gaps have other root causes (weak content, no rationalization blocking). Skills are preloaded in subagent context. |
| ~15k character budget is real | **Validated (refined)** | Budget is 2% of context window with 16k fallback; genie-team uses 12.3% |
| 200-character limit is appropriate | **Disproved** | Would force cuts to 3 knowledge skills (excluded by backlog's own no-gos). Recommended descriptions are 150-250+ chars. |

## Recommendation

**Close this backlog item.** The proposed changes would make skill activation *worse*, not
better. The specific findings:

1. **The core mechanism is misunderstood.** Descriptions serve invocation decisions, not as
   substitutes for full skill content. Genie-team's subagent-based workflow preloads full
   content at startup, making descriptions irrelevant to the enforcement path.

2. **The proposed fix goes against documented best practices.** Multiple sources recommend
   descriptions include both what the skill does AND when to use it — exactly what genie-team
   already does. Stripping functional summaries would reduce activation reliability from
   ~80% to ~50% in interactive sessions.

3. **The real enforcement gaps are in skill content.** The P2 items (rationalization-blocking,
   verification-gate, systematic-debugging) correctly target skill content — the actual lever
   for behavior change. Those items should be prioritized over this one.

4. **The character budget is a non-issue.** At 12.3% utilization, genie-team has room for
   ~87 more skills before hitting the budget.

## Sources

- [Claude Code skills documentation](https://code.claude.com/docs/en/skills)
- [Claude Agent Skills: A First Principles Deep Dive](https://leehanchung.github.io/blogs/2025/10/26/claude-skills-deep-dive/)
- [Inside Claude Code Skills](https://mikhail.io/2025/10/claude-code-skills/)
- [How to train Claude Code agents with custom skills](https://www.howdoiuseai.com/blog/2026-02-08-how-to-train-claude-code-agents-with-custom-skills)
- [The Complete Guide to Claude Skills](https://tylerfolkman.substack.com/p/the-complete-guide-to-claude-skills)
- [Claude Code Agent Skills](https://prg.sh/notes/Claude-Code-Agent-Skills)
