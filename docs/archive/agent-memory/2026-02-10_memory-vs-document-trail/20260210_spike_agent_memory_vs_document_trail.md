# Spike: Agent Persistent Memory vs Document Trail

**Question:** Does the native `memory: project` feature replace, complement, or conflict with genie-team's document trail (`docs/`)?
**Time spent:** 1 session (analytical spike, not multi-session empirical test)
**Verdict:** Complementary — they serve different purposes with a clean boundary

---

## Findings

### The Two Systems

| Dimension | Document Trail (`docs/`) | Agent Memory (`agent-memory/`) |
|-----------|-------------------------|-------------------------------|
| **Contains** | Deliverables — findings, contracts, designs, reviews, decisions | Meta-learning — patterns noticed, calibrations, shortcuts |
| **Audience** | You, the team, other agents, future sessions | The specific agent only |
| **Lifecycle** | Created → appended → archived; version-controlled | Curated continuously; 200-line cap forces pruning |
| **Format** | Structured schemas (Opportunity Snapshot, Design Document, etc.) | Freeform markdown (like a personal notebook) |
| **Sharing** | Git-tracked, shared across machines/team | Agent-local, should be gitignored |
| **Created by** | Workflow phases (discover writes analysis, design appends to backlog) | Agent's own judgment about what to remember |
| **Read by** | Anyone — explicit file reads via `## Context Usage` | Auto-injected into owning agent's system prompt only |

### The Boundary (One Sentence)

**Document trail stores what the project knows. Agent memory stores what the agent has learned about working on this project.**

### Analogy

The document trail is the company's filing system — reports, specs, signed-off decisions. Agent memory is an employee's personal notebook — "the build takes 45 seconds", "watch for missing error handling in API routes", "the user prefers functional components".

You wouldn't file personal notes in the company archive. You wouldn't put official specs in someone's personal notebook.

---

## What Each Agent Should Memorize

The document trail `## Context Usage` already tells agents where to write deliverables. Agent memory captures everything *around* the deliverables:

| Agent | Deliverables → `docs/` | Meta-learning → `agent-memory/` |
|-------|------------------------|---------------------------------|
| **Scout** | Opportunity Snapshots in `docs/analysis/` | Known territory (topics already explored), promising signals worth revisiting |
| **Shaper** | Shaped Contracts in `docs/backlog/` | Appetite calibration ("small batch ≈ 2 days here"), recurring problem themes |
| **Architect** | Design sections appended to `docs/backlog/` | Architectural conventions chosen, known constraints, integration quirks |
| **Crafter** | Code + tests + execution report | Build/test quirks ("must migrate first"), naming patterns, test structure conventions |
| **Critic** | Review verdicts appended to `docs/backlog/` | Common issues in this codebase, areas that tend to have problems, quality trends |
| **Tidier** | Cleanup reports in `docs/cleanup/` | Known debt hotspots, safe refactoring approaches that worked, areas to avoid |
| **Designer** | Brand guides in `docs/brand/` | Image generation prompts that work for this project's style, design decisions well-received |

### Key Insight: Memory Is About Getting Better

Document trail answers: "What did we decide?" (backward-looking record)
Agent memory answers: "What should I do differently next time?" (forward-looking learning)

A critic that remembers "the last 3 reviews all had missing input validation in API routes" will proactively check for that pattern. That observation doesn't belong in any specific review document — it's cross-cutting meta-knowledge.

---

## Version Control Decision

**Agent memory should be gitignored.** Reasons:

1. **Personal to the agent instance.** Two developers' critic agents may learn different things based on their sessions. Merging would conflict.
2. **Curated, not comprehensive.** The 200-line limit means it's a compressed summary, not a canonical record. The canonical record is in `docs/`.
3. **Machine-local.** Like IDE settings — useful to the person using it, not meaningful to share.
4. **Fresh start is fine.** A new clone gets empty agent memory. The document trail provides all project knowledge. Agent memory is a performance optimization, not a knowledge source.

The install script should add `.claude/agent-memory/` to project `.gitignore` templates.

---

## Why Not Just Use `docs/` for Everything?

Three reasons agent memory adds value beyond the document trail:

### 1. Auto-injection vs. explicit loading
Document trail requires the command/agent to explicitly `Read` files. Agent memory is auto-injected into the system prompt — the agent starts every session already knowing its learned patterns. No workflow step needed to "load context."

### 2. Cross-cutting observations don't fit any single document
"This codebase has inconsistent error handling" doesn't belong in any one review document. It's a pattern noticed *across* reviews. The document trail is organized by work item. Memory is organized by the agent's perspective.

### 3. The 200-line constraint forces curation
Document trail files grow (a backlog item accumulates shaped → designed → implemented → reviewed sections). Memory must be pruned. This forces the agent to distill and prioritize — keeping only what's genuinely useful for future sessions.

---

## What Memory Is NOT

To prevent overlap and confusion, agent memory should explicitly **not** contain:

- **Deliverables** — no Opportunity Snapshots, no Design Documents, no Review Verdicts. Those go in `docs/`.
- **Session-specific state** — no "currently working on P1-auth-refactor." That's transient.
- **Duplicates of `docs/` content** — no copying spec summaries or architecture decisions. Reference by path instead.
- **Speculative conclusions** — only patterns confirmed across multiple sessions.

---

## Implementation: Memory Guidance per Agent

Each agent needs a `## Memory Guidance` section that tells it:
1. What to write to memory (meta-learning categories)
2. What NOT to write to memory (deliverables, duplicates)
3. When to prune (keep under 200 lines, remove stale observations)

Example for Critic:

```markdown
## Memory Guidance

After each review, update your MEMORY.md with observations that will help future reviews:

**Write to memory:**
- Recurring quality issues in this codebase (patterns across reviews)
- Areas that tend to have problems (hotspots)
- Project-specific conventions you've observed
- Calibration notes (what "high confidence" means for this project)

**Do NOT write to memory:**
- The review verdict itself (that goes in the backlog item)
- Specific findings from this review (those are in the review document)
- Anything already in docs/architecture/ or docs/specs/

**Prune when:** Memory exceeds 150 lines. Remove observations older than 5 reviews that haven't been reinforced.
```

---

## Answers to Spike Questions

| Question | Answer |
|----------|--------|
| Does memory replace, complement, or conflict with docs/? | **Complements.** Different content, different audience, different lifecycle. |
| What does the agent store in memory vs docs/? | **Memory:** meta-learning about the project. **Docs:** deliverables and decisions. |
| Does memory complement or conflict with the document trail? | **Complements** — no overlap when agents have clear guidance. |
| Is recall quality sufficient for cross-session continuity? | **Not tested empirically** (requires multi-session test). Mechanism is sound — auto-injection means recall is guaranteed if content is written. |
| Should `.claude/agent-memory/` be gitignored? | **Yes.** It's agent-local learning, not project documentation. |

---

## Risks

1. **Agents may not write to memory without explicit guidance.** Confirmed by the native-agent-format spike — the critic agent didn't create a MEMORY.md because nothing told it to. Each agent needs a `## Memory Guidance` section.
2. **200-line limit could fill quickly.** Agents need pruning discipline. The guidance must include a pruning strategy.
3. **Memory could drift from reality.** An agent might remember "tests are slow" after the test suite was optimized. Pruning based on staleness mitigates this.
4. **Multi-session testing not done.** This spike answers the *conceptual* boundary question. Empirical validation (does recall actually improve agent performance?) is a separate follow-up.

---

## Recommendation

**Verdict: COMPLEMENTARY — proceed with memory guidance.**

Next steps:
1. Add `.claude/agent-memory/` to `.gitignore`
2. Add `## Memory Guidance` section to each of the 7 agent files
3. Run 2-3 real workflow sessions to validate agents actually write useful memory
4. Evaluate whether memory improves agent performance in subsequent sessions
