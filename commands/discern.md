# /discern [backlog-item]

Activate Critic genie to review implementation against acceptance criteria.

---

## Arguments

- `backlog-item` - Path to backlog item (contains shaped contract + design + implementation) (required)

There are no focus flags or sub-commands: every default `/discern` review
includes acceptance verification, the adversarial security pass, and
performance assessment. Narrowing the review is not supported — the failure
mode this prevents is real vulnerabilities shipping because nobody asked for
the security pass.

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
- Backlog frontmatter field `spec_ref` → load the linked spec (ACs to verify)
- Code changes (diff)
- Test results

**RECALL:**
- Past review patterns
- Common issues in this area

**ADR LOADING:**
1. Check for `adr_refs` in the backlog item or design section frontmatter
2. If present: Read each referenced ADR from `docs/decisions/`
3. Load component diagram for the domain (if exists in `docs/architecture/components/`)
4. If `docs/decisions/` does not exist: Note and continue. ADR compliance check is skipped.

**SPEC LOADING:**
1. Read `spec_ref` from backlog item frontmatter
2. If `spec_ref` is present: Read the spec file. Load acceptance_criteria for verification against implementation.
3. If `spec_ref` is missing: Warn and continue:
   > This backlog item has no spec_ref. Review will use backlog ACs only.
4. If `spec_ref` points to a nonexistent file: Warn and continue:
   > spec_ref points to {path} but file not found. Review will use backlog ACs only.

---

## Context Writing

**UPDATE:**
- Backlog item: Append "# Review" section before "# End of Shaped Work Contract"
- Backlog frontmatter: `status: implemented` → `status: reviewed`
- Backlog frontmatter: add `verdict: APPROVED|BLOCKED|CHANGES_REQUESTED` field (machine-readable verdict for the autonomous runner)
- **Spec (if spec_ref exists):** Update spec AC statuses and append "## Review Verdict" section (see below)
- docs/specs/{domain}/README.md (per Domain README Format, when spec_ref exists)

> **Note:** Review content is appended directly to the backlog item rather than creating a separate analysis file.

**SPEC UPDATE (when spec_ref is present):**

After completing the review, update the linked spec:

1. **Update acceptance_criteria statuses in frontmatter:**
   - For each spec AC, evaluate whether the implementation satisfies it
   - Update `status: pending` → `status: met` (if satisfied) or `status: unmet` (if not satisfied)
   - Never remove or rewrite AC descriptions — only change the status field
2. **Append "## Review Verdict" section** to the spec body (or update if it already exists):
   ```markdown
   ## Review Verdict
   <!-- Updated by /discern on {YYYY-MM-DD} from {backlog-item-id} -->

   **Verdict:** {APPROVED | CHANGES REQUESTED | BLOCKED}
   **ACs verified:** {N}/{M} met

   | AC | Status | Evidence |
   |----|--------|----------|
   | AC-1 | met | {brief evidence} |
   | AC-2 | unmet | {what's missing} |
   ```
3. **Do NOT change spec status** — the spec stays `active` regardless of verdict
4. **Regenerate `docs/specs/{domain}/README.md`** per spec-awareness Domain README Format

---

## Output

Produces a **Review Document** with clear verdict:
- **APPROVED** - Ready for deployment
- **CHANGES REQUESTED** - Issues found, fixable
- **BLOCKED** - Critical issues, cannot proceed

---

## Adversarial Security Pass (MANDATORY)

Every `/discern` review includes an adversarial security pass as a distinct
section of the review document — not a checkbox, an attack attempt. Assume
the implementation is vulnerable and try to prove it. For each vector below,
either demonstrate an exploit path (file:line, payload, effect) or state
specifically why the code is not susceptible:

1. **XSS — including inline SVG/HTML.** Any user-supplied content rendered
   into markup: does it escape script tags AND inline SVG (`<svg onload=…>`),
   event-handler attributes, and `javascript:` URLs? Sanitizers that only
   strip `<script>` miss stored XSS via SVG.
2. **CSS injection.** User-supplied values interpolated into styles or
   `style=` attributes (exfiltration selectors, `url()` beacons, UI overlay).
3. **Authorization / IDOR — including on-behalf-of paths.** Every endpoint
   and handler: is the *authenticated* principal checked against the
   *addressed* resource? Pay attention to admin/on-behalf-of/impersonation
   flows and IDs accepted from the client.
4. **Injection.** SQL, shell/command, and template injection anywhere
   user-controlled data meets an interpreter (queries, `exec`, string-built
   templates, YAML/JSON parsers with code paths).
5. **Secrets exposure.** Keys/tokens in logs, error messages, client-visible
   config, committed files, or overly broad env passthrough.
6. **Over-required fields.** Forms/APIs demanding data the feature doesn't
   need — a privacy defect and an adoption blocker; flag it.
7. **Silently-failing credentials.** Auth that degrades to anonymous/no-op on
   expired or invalid credentials instead of failing loudly (the two-month
   expired-PAT failure mode). Credential failure must surface as an error.

If the pass is interrupted, the review is **incomplete** — resume or restate
it before issuing a verdict; never issue APPROVED with a partial security pass.

Findings feed the standard severity levels; any demonstrated vulnerability is
**Critical** and blocks approval.

---

## Review Checklist

Critic evaluates:
1. Acceptance criteria met? (backlog ACs)
2. **Spec ACs verified?** (if spec_ref exists — each spec AC checked against implementation)
3. Code quality acceptable?
4. Test coverage sufficient?
5. **Adversarial security pass complete?** (see section above — mandatory, all seven vectors)
6. Performance concerns?
7. Error handling adequate?
8. Risks identified and mitigated?
9. **ADR compliance?** (if adr_refs exist — does implementation follow each accepted decision?)
10. **Wiring verification?** — For ACs that describe system behavior (e.g., "auto-trigger," "writes to repo," "pushes to," "syncs," "sends"), verify there is a code path from the running application to the implemented logic. Mock-passing tests are NOT sufficient evidence for integration ACs. Check:
    - Are interfaces implemented with real (non-mock) types?
    - Is the component instantiated in service bootstrap?
    - Are event handlers/consumers registered?
    - Can you trace a call path from HTTP/gRPC handler → business logic → external effect?
    If mock-only: mark AC as **unmet** with note "logic implemented but not wired into running system."

---

## ADR Compliance Output

When `adr_refs` exist, include an ADR Compliance table in the review:

```
## ADR Compliance

| ADR | Decision | Compliant? | Notes |
|-----|----------|------------|-------|
| ADR-001 | JWT refresh tokens | YES | Implemented as specified |
| ADR-003 | Auth service boundary | VIOLATION | Direct DB access bypasses service |
```

Compliance verdicts:
- **YES** — Implementation follows the accepted decision
- **VIOLATION** — Implementation contradicts the accepted decision (flag prominently)
- **N/A** — ADR not relevant to this implementation

An ADR VIOLATION does not automatically BLOCK the review, but it MUST be flagged prominently and the reviewer should consider whether it warrants CHANGES REQUESTED.

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
> Spec ACs: 3/3 met
> Code quality: Good
> Test coverage: 87%
> Security: Pass
> Performance: Pass
>
> ADR Compliance:
> | ADR-015 | JWT refresh strategy | YES | Refresh tokens with rotation |
> | ADR-016 | Token storage | YES | Redis-backed as specified |
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
- **APPROVED**: `/done` to archive (use `/commit` anytime for checkpoints)
- **CHANGES REQUESTED**: Route to Crafter, schedule re-review
- **BLOCKED**: Escalate to Architect or Navigator

---

## Notes

- Clear, actionable verdicts only
- Evidence-based (not opinion-based)
- Focuses on risks that matter
- Creates audit trail
- Gatekeeper before deployment

## Calibration

**CHANGES REQUESTED is expensive.** In an autonomous `/run`, it triggers a full fix-retest-re-review cycle. Reserve it for issues that would cause runtime failures, security vulnerabilities, or spec non-compliance. Do NOT request changes for:
- Style preferences when the code follows project conventions
- Alternative approaches that aren't clearly better (e.g., `errors.Join` vs first-error)
- ACs that are already satisfied — verify before claiming unmet
- Pedantic concerns that don't affect correctness or maintainability

**When in doubt, APPROVE with notes** rather than requesting changes. Append observations to the review as informational findings, not blocking issues.

**Exception: Never APPROVE when integration wiring is missing.** If an AC describes end-to-end behavior (triggers, syncs, pushes, sends) and there is no code path from the running application to the implemented logic, that AC is **unmet** regardless of unit test coverage. This warrants CHANGES REQUESTED, not "APPROVED with notes."
