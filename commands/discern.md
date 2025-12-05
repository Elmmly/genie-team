# /discern [implementation]

Activate Critic genie to review implementation against acceptance criteria.

---

## Arguments

- `implementation` - Implementation report or code reference (required)
- Optional flags:
  - `--security` - Security-focused review only
  - `--performance` - Performance-focused review only
  - `--accept` - Just acceptance criteria check

---

## Genie Invoked

**Critic** - Reviewer combining:
- Risk-first review approach
- Evidence-based decisions
- Clear verdict authority

---

## Context Loading

**READ (automatic):**
- Implementation report from /deliver
- Code changes (diff)
- Test results
- Design document
- Shaped contract (acceptance criteria)

**RECALL:**
- Past review patterns
- Common issues in this area

---

## Context Writing

**WRITE:**
- docs/analysis/YYYYMMDD_review_{topic}.md

**UPDATE:**
- docs/backlog/{priority}-{topic}.md (status)
- Move to archive if complete

---

## Output

Produces a **Review Document** with clear verdict:
- **APPROVED** - Ready for deployment
- **CHANGES REQUESTED** - Issues found, fixable
- **BLOCKED** - Critical issues, cannot proceed

---

## Sub-Commands

| Command | Purpose |
|---------|---------|
| `/discern:security [code]` | Security-focused review |
| `/discern:performance [code]` | Performance-focused review |
| `/discern:accept [impl]` | Just acceptance criteria check |

---

## Review Checklist

Critic evaluates:
1. Acceptance criteria met?
2. Code quality acceptable?
3. Test coverage sufficient?
4. Security concerns?
5. Performance concerns?
6. Error handling adequate?
7. Risks identified and mitigated?

---

## Usage Examples

```
/discern docs/analysis/20251203_impl_auth.md
> [Critic reviews implementation]
> Saved to docs/analysis/20251203_review_auth.md
>
> Verdict: APPROVED
>
> Acceptance criteria: 5/5 met
> Code quality: Good
> Test coverage: 87%
> Security: Pass
> Performance: Pass
>
> Ready for deployment
> Monitoring: Watch token refresh failure rate

/discern docs/analysis/20251203_impl_auth.md
> Verdict: CHANGES REQUESTED
>
> Issues:
> 1. [Major] Missing rate limiting on refresh endpoint
> 2. [Minor] Error messages expose internal details
>
> Route to Crafter for fixes, then re-review
```

---

## Routing

After review:
- **APPROVED**: Notify Navigator, ready for deploy
- **CHANGES REQUESTED**: Route to Crafter, schedule re-review
- **BLOCKED**: Escalate to Architect or Navigator

---

## Notes

- Clear, actionable verdicts only
- Evidence-based (not opinion-based)
- Focuses on risks that matter
- Creates audit trail
- Gatekeeper before deployment
