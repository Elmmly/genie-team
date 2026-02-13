# /handoff [from] [to]

Explicit transition between lifecycle phases with context summarization.

---

## Arguments

- `from` - Source phase: discover, define, design, deliver (required)
- `to` - Target phase: define, design, deliver, discern (required)

---

## Valid Transitions

| From | To | Handoff Creates |
|------|-----|-----------------|
| discover | define | Opportunity summary + defining guidance |
| define | design | Design brief + constraints |
| design | deliver | Implementation guidance |
| deliver | discern | Review request + focus areas |

---

## Purpose

Handoffs ensure:
1. Current phase output is summarized
2. Key context transfers to next phase
3. User confirms before proceeding
4. No implicit assumptions cross boundaries

---

## Output Format

```markdown
# Handoff: [From] → [To]

**[From] completed:** [Document reference]

**Key findings:**
- [Finding 1]
- [Finding 2]

**For [To] genie:**
- [Context item 1]
- [Context item 2]

**Domain-Specific Guidance:**
{Each active awareness skill that detects relevant artifacts contributes 1-2 contextual reminders here. Skills activate via their "During /handoff" behavior sections. If no skill has guidance, omit this section entirely.}

**Recommended next:** `/[to] [input-path]`
```

---

## Handoff Details

### discover → define

```markdown
# Handoff: Discovery → Defining

**Discovery completed:** docs/analysis/20251203_discover_auth.md

**Key findings:**
- Users frustrated with SSO login failures
- Token expiry too aggressive
- No refresh token mechanism

**Assumptions identified:**
- [Assumption 1] - untested
- [Assumption 2] - evidence mixed

**For Shaper:**
- Focus on: [opportunity area]
- Appetite signal: [complexity indicator]
- Constraints: [any discovered constraints]

**Next:** `/define docs/analysis/20251203_discover_auth.md`
```

### define → design

```markdown
# Handoff: Defining → Design

**Defining completed:** docs/backlog/P2-auth-improvements.md

**Problem frame:**
[Summary of what we're solving]

**Appetite:** [Time budget]

**For Architect:**
- Solution sketch: [rough direction]
- Rabbit holes: [what to avoid]
- Constraints: [boundaries from defining]

**Next:** `/design docs/backlog/P2-auth-improvements.md`
```

### design → deliver

```markdown
# Handoff: Design → Delivery

**Design completed:** docs/analysis/20251203_design_auth.md

**Design summary:**
[What we're building]

**For Crafter:**
- Components to create/modify: [list]
- Key interfaces: [critical interfaces]
- Test strategy: [testing approach]
- Gotchas: [things to watch for]

**For Crafter (domain context):**
{brand-awareness /handoff guidance — if brand guide exists}
{spec-awareness /handoff guidance — if spec_ref exists}
{architecture-awareness /handoff guidance — if adr_refs exist}
{Omit this section if no awareness skill has guidance}

**Next:** `/deliver docs/analysis/20251203_design_auth.md`
```

### deliver → discern

```markdown
# Handoff: Delivery → Review

**Implementation completed:** [code changes summary]

**What was built:**
- [Component 1]
- [Component 2]

**For Critic:**
- Acceptance criteria: [from defined contract]
- Test results: [summary]
- Focus areas: [where to look closely]
- Known limitations: [if any]

**For Critic (domain context):**
{brand-awareness /handoff guidance — if visual work}
{spec-awareness /handoff guidance — if spec delta or regressions}
{architecture-awareness /handoff guidance — if ADR compliance needed}
{Omit this section if no awareness skill has guidance}

**Next:** `/discern [implementation-reference]`
```

---

## Usage Examples

```
/handoff discover define
> Handoff: Discovery → Defining
>
> Discovery completed: docs/analysis/20251203_discover_auth.md
>
> Key findings:
> - SSO users experiencing login failures
> - Token expiry at 15 min too short
>
> Assumptions to validate:
> - Users want "remember me" functionality
>
> For Shaper:
> - Focus on token refresh mechanism
> - Appetite signal: Medium complexity
>
> Ready to define? (y/n)
> y
>
> Next: /define docs/analysis/20251203_discover_auth.md
```

---

## Notes

- Explicit > implicit handoffs
- Creates clean phase boundaries
- User confirms each transition
- Preserves context that matters
- Discards context that doesn't
