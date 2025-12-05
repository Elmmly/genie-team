# /bugfix [issue]

Quick bug fix workflow: light shape → deliver → discern.

---

## Arguments

- `issue` - Bug description or issue reference (required)
- Optional flags:
  - `--urgent` - Skip shaping, go direct to fix
  - `--test-only` - Just write regression test

---

## Workflow

```
/bugfix "login fails for SSO users"
    │
    ├─→ Light Shaping (abbreviated)
    │   └─→ Problem statement
    │   └─→ Acceptance criteria
    │   └─→ Scope boundaries
    │
    ├─→ /deliver (bug fix mode)
    │   └─→ Write regression test first
    │   └─→ Fix the bug
    │   └─→ Verify test passes
    │
    └─→ /discern (abbreviated)
        └─→ Regression test exists?
        └─→ Bug actually fixed?
        └─→ No new issues introduced?
```

---

## Light Shaping Output

```markdown
# Bug Fix: [Issue]

**Problem:** [What's broken]
**Expected:** [Correct behavior]
**Actual:** [Current behavior]
**Scope:** [What we will/won't touch]

**Acceptance:**
- [ ] Regression test written
- [ ] Bug fixed
- [ ] All tests pass
```

---

## Usage Examples

```
/bugfix "login fails for SSO users"
> Bug fix workflow started
>
> Light shape:
> - Problem: SSO users get 401 on login
> - Expected: Successful authentication
> - Scope: SSO auth flow only
>
> Proceeding to fix...
>
> [Crafter writes regression test]
> Test: "SSO user login succeeds" - FAILING (expected)
>
> [Crafter implements fix]
> Test: "SSO user login succeeds" - PASSING
>
> [Critic quick review]
> Verdict: APPROVED
> Regression test exists, bug fixed, no side effects

/bugfix --urgent "production 500 error on checkout"
> URGENT mode - skipping shaping
> [Crafter investigating and fixing]
```

---

## Routing

- **Simple bug**: Full workflow
- **Urgent bug**: Skip shaping with `--urgent`
- **Complex bug**: Upgrade to `/feature` workflow
- **Systemic issue**: Escalate to Architect for root cause

---

## Notes

- Faster than full feature workflow
- Still enforces regression test
- Abbreviated but not skipped review
- Creates audit trail for bug fixes
- Know when to escalate to full workflow
