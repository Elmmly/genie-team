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
    ├─→ Root-Cause Protocol (MANDATORY opening — see below)
    │   └─→ Reproduce and state the reproduction
    │   └─→ Environment cause or code cause?
    │   └─→ Architectural root cause vs proximate symptom?
    │   └─→ More than one code path producing this state?
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

## Root-Cause Protocol (MANDATORY opening)

Every `/bugfix` — including `--urgent` — opens with the `debugging` skill's
protocol. Load that skill and follow it. Before writing ANY code:

1. **Reproduce first.** Reproduce the bug and state the reproduction (command,
   input, observed vs expected). A bug you cannot reproduce is a bug you
   cannot claim to have fixed.
2. **Answer explicitly, in writing, in the light-shape output:**
   - **(a) Environment or code?** Could this be an expired token/PAT, a
     stopped service, a wrong URL, a stale process, or a dependency/config
     issue — rather than a code defect? Rule environment out (or in) before
     touching code.
   - **(b) Root cause or symptom?** Is the proposed fix addressing the
     architectural root cause, or papering over a proximate symptom (e.g., a
     precedence patch hiding two competing resolution paths)? If symptom:
     name the root cause and fix that, or explicitly record why the symptom
     fix is the right scope.
   - **(c) One path or many?** Is there more than one code path that can
     produce this state? A fix on one path leaves the bug alive on the others.
3. **Then** write the failing regression test, **then** fix.

The debugging skill's escalation still applies: after 3 failed fix attempts,
STOP and produce a root-cause-analysis document instead of a fourth patch.

---

## Light Shaping Output

```markdown
# Bug Fix: [Issue]

**Problem:** [What's broken]
**Expected:** [Correct behavior]
**Actual:** [Current behavior]
**Scope:** [What we will/won't touch]

**Reproduction:** [Exact command/input, observed vs expected]
**Cause classification:** [environment | code] — [one-line rationale]
**Root cause:** [The mechanism, not the symptom; note if multiple code paths produce this state]

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
> Root-cause protocol still applies: reproducing first...
> [Crafter reproduces, classifies cause, then fixes]
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
