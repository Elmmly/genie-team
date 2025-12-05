# /handoff [from] [to]

Explicit transition between lifecycle phases with context summarization.

---

## Arguments

- `from` - Source phase: discover, shape, design, deliver (required)
- `to` - Target phase: shape, design, deliver, discern (required)

---

## Valid Transitions

| From | To | Handoff Creates |
|------|-----|-----------------|
| discover | shape | Opportunity summary + shaping guidance |
| shape | design | Design brief + constraints |
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

**Recommended next:** `/[to] [input-path]`
```

---

## Handoff Details

### discover → shape

```markdown
# Handoff: Discovery → Shaping

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

**Next:** `/shape docs/analysis/20251203_discover_auth.md`
```

### shape → design

```markdown
# Handoff: Shaping → Design

**Shaping completed:** docs/backlog/P2-auth-improvements.md

**Problem frame:**
[Summary of what we're solving]

**Appetite:** [Time budget]

**For Architect:**
- Solution sketch: [rough direction]
- Rabbit holes: [what to avoid]
- Constraints: [boundaries from shaping]

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
- Acceptance criteria: [from shaped contract]
- Test results: [summary]
- Focus areas: [where to look closely]
- Known limitations: [if any]

**Next:** `/discern [implementation-reference]`
```

---

## Usage Examples

```
/handoff discover shape
> Handoff: Discovery → Shaping
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
> Ready to shape? (y/n)
> y
>
> Next: /shape docs/analysis/20251203_discover_auth.md
```

---

## Notes

- Explicit > implicit handoffs
- Creates clean phase boundaries
- User confirms each transition
- Preserves context that matters
- Discards context that doesn't
