# /discern [backlog-item]

Activate Critic genie to review implementation against acceptance criteria.

---

## Arguments

- `backlog-item` - Path to backlog item (contains shaped contract + design + implementation) (required)
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
- docs/backlog/{priority}-{topic}.md (contains shaped contract + design + implementation)
- Code changes (diff)
- Test results

**RECALL:**
- Past review patterns
- Common issues in this area

---

## Context Writing

**UPDATE:**
- Backlog item: Append "# Review" section before "# End of Shaped Work Contract"
- Backlog frontmatter: `status: implemented` → `status: reviewed`

> **Note:** Review content is appended directly to the backlog item rather than creating a separate analysis file.

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
/discern docs/backlog/P2-auth-improvements.md
> [Critic reviews implementation]
> Appended to docs/backlog/P2-auth-improvements.md
> Status updated: implemented → reviewed
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
> Next: /done docs/backlog/P2-auth-improvements.md

/discern docs/backlog/P2-auth-improvements.md
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
- **APPROVED**: Run `/done` to archive completed work
- **CHANGES REQUESTED**: Route to Crafter, schedule re-review
- **BLOCKED**: Escalate to Architect or Navigator

---

## Notes

- Clear, actionable verdicts only
- Evidence-based (not opinion-based)
- Focuses on risks that matter
- Creates audit trail
- Gatekeeper before deployment
