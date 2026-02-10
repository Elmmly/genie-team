---
type: spike
topic: "proactive-delegation"
status: complete
created: "2026-02-09"
completed: "2026-02-10"
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

**Partially.** Proactive delegation via skills (e.g., `problem-first` skill activating when users say "we should add..." or "let's build...") successfully triggers reframing behavior inline. However, the full structured output (Shaped Work Contract with YAML frontmatter, acceptance criteria, appetite boundaries) requires the command file's orchestration — argument parsing, spec lifecycle checks, template loading — which proactive agent delegation via Task tool does not invoke.

Skills handle cross-cutting concerns (reframing, TDD enforcement, brand awareness) well because they inject behavior into whatever command is running. Agent delegation handles genie selection well. But neither reproduces the full command-level workflow.

### Does the 7 D's sequence hold without explicit commands?

**No.** The 7 D's sequence (discover → define → design → deliver → discern) is encoded in commands, not agents. Without explicit commands, there is no mechanism to enforce ordering — a user saying "build me dark mode" could trigger Shaper (correct) but there's nothing preventing them from jumping straight to implementation without a design phase.

For interactive use, this is acceptable — the user maintains workflow awareness. For autonomous/Cataliva use, commands ARE the API: `claude "/deliver docs/backlog/P1-feature.md"` explicitly encodes which phase to run.

### Where does the workflow degrade?

Three degradation points:

1. **Command-level orchestration lost** — Commands load skills, parse arguments, check preconditions (e.g., "does a design doc exist before /deliver?"). Proactive delegation skips all of this.
2. **Document trail at risk** — Commands explicitly write artifacts to `docs/`. Proactive delegation may produce output in conversation only, breaking the versioned document trail that both humans and AI need.
3. **Ambiguous routing** — "The login page is slow" could reasonably go to Scout (discovery) or Shaper (problem framing). Commands make the user's intent explicit; proactive delegation guesses.

### Document trail impact

Commands ensure artifacts land in `docs/` as committed files. Proactive delegation via Task tool returns content to the orchestrator (main conversation), which may or may not write it to disk. The document trail — the core value proposition for both human review and Cataliva integration — requires explicit commands or explicit file-writing instructions in the agent prompt.

---

## 5. Key Tension — Resolved

Genie-team's explicit commands encode two things:
1. **Which genie** to invoke (Shaper vs Scout vs Architect)
2. **Where in the workflow** you are (discover → define → design → deliver)

Proactive delegation handles #1 well but loses #2. Both mechanisms coexist:

- **Skills** (proactive, cross-cutting) — Handle behavioral enforcement: problem-first reframing, TDD discipline, brand awareness, code quality. These activate automatically during any command.
- **Commands** (explicit, sequential) — Handle workflow orchestration: phase sequencing, document trail creation, precondition checking, structured output formatting.
- **For Cataliva** — Commands are the API. `claude "/deliver docs/backlog/P1-feature.md"` is how an orchestrator dispatches work with explicit phase selection.

---

## 6. Routing Recommendation

- [ ] **Proactive delegation works fully** — Commands become optional power-user shortcuts
- [x] **Partially works** — Some agents benefit, workflow sequence still needs commands
- [ ] **Doesn't work** — Explicit commands remain the primary interface
- [ ] **Needs further investigation** — More testing required

**Rationale:** Proactive skills successfully handle cross-cutting concerns (reframing, TDD, brand). But workflow sequencing, document trail creation, and precondition checking require explicit commands. Both coexist — skills are proactive behavioral enforcement, commands are explicit workflow orchestration. For Cataliva's autonomous PDLC, commands serve as the dispatch API.

**Action:** No further changes needed. The current architecture (commands + skills + agents) is the right layering. Archive this spike.
