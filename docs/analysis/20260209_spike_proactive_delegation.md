---
type: spike
topic: "proactive-delegation"
status: active
created: "2026-02-09"
spec_ref: "docs/backlog/spike-P0-proactive-delegation.md"
---

# Spike: Proactive Agent Delegation vs Explicit /commands

## 1. Experiment Setup

### Mechanism

Claude Code's Task tool spec states:
> "If the agent description mentions that it should be used proactively, then you should try your best to use it without the user having to ask for it first."

### Change Made

**Before (non-proactive):**
```
description: "Product shaper for problem framing, appetite setting, and scope boundaries. Use for converting opportunities into shaped work contracts using Shape Up methodology."
```

**After (proactive):**
```
description: "Problem framing specialist. Proactively activates when the user describes a feature request, solution-loaded problem, or says 'we should add' or 'let's build'. Reframes solutions as problems and produces Shaped Work Contracts with appetite boundaries."
```

### Key Constraint (from Navigator)

Document artifacts are required for versioned history useful to both humans and AI. Even if proactive delegation works, the structured output (Shaped Work Contracts, etc.) must still land in `docs/` as committed files — not just appear in conversation.

---

## 2. Test Conversations

### Test A: Natural Language (no slash commands)

Run in a **fresh session** in any project that has genie-team installed globally.

| # | Prompt | Expected Agent | Observed Agent | Structured Output? | Written to docs/? |
|---|--------|---------------|----------------|--------------------|--------------------|
| A1 | "I want to add dark mode to the app" | shaper | | | |
| A2 | "We should build a notification system" | shaper | | | |
| A3 | "The login page is slow" | scout (ambiguous) | | | |

### Test B: Explicit Commands (baseline)

| # | Command | Expected Agent | Structured Output? | Written to docs/? |
|---|---------|---------------|--------------------|--------------------|
| B1 | `/define "add dark mode"` | shaper | | |
| B2 | `/define "build a notification system"` | shaper | | |
| B3 | `/discover "login page performance"` | scout | | |

---

## 3. Evaluation Criteria

| Criterion | Proactive (A) | Explicit (B) | Notes |
|-----------|:---:|:---:|-------|
| Correct agent selected? | | | |
| Shaped Work Contract produced? | | | |
| YAML frontmatter present? | | | |
| Artifact written to docs/? | | | |
| problem-first skill triggered? | | | |
| Anti-pattern detection worked? | | | |
| 7 D's sequence preserved? | | | |

---

## 4. Findings

### Does auto-delegation preserve structured output?

_[To be filled after testing]_

### Does the 7 D's sequence hold without explicit commands?

_[To be filled after testing]_

### Where does the workflow degrade?

_[To be filled after testing]_

### Document trail impact

_[To be filled — does proactive delegation still write artifacts to docs/, or does output stay in conversation only?]_

---

## 5. Key Tension

Genie-team's explicit commands encode two things:
1. **Which genie** to invoke (Shaper vs Scout vs Architect)
2. **Where in the workflow** you are (discover → define → design → deliver)

Proactive delegation can handle #1 (match request to agent) but may lose #2 (workflow position and sequencing).

Additionally: explicit commands trigger the command file, which loads skills and sets up the workflow context. Proactive delegation via Task tool only loads the agent file — it may miss the command-level orchestration (argument parsing, workshop mode, spec lifecycle behavior).

---

## 6. Routing Recommendation

- [ ] **Proactive delegation works fully** — Commands become optional power-user shortcuts
- [ ] **Partially works** — Some agents benefit, workflow sequence still needs commands
- [ ] **Doesn't work** — Explicit commands remain the primary interface
- [ ] **Needs further investigation** — More testing required

**Rationale:** _[To be filled]_
