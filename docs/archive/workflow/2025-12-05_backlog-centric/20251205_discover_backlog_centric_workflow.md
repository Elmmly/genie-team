---
type: discover
concept: workflow
enhancement: backlog-centric
status: completed
created: 2025-12-05
---

# Opportunity Snapshot: Backlog-Centric Workflow
### Scout Genie Discovery — 2025-12-05

---

## 1. Discovery Question

**Original input:** "Review the workflow of the agents & commands to ensure that after an item is shaped, it is added to the backlog where all other agents then work on to update directly. The goal is to minimize extra files and sprawl while clarifying that items in the backlog are prioritized and worked on."

**Reframed question:** How can the genie-team workflow be restructured so that the backlog item becomes the single source of truth that evolves through the lifecycle, rather than creating separate analysis files at each phase?

---

## 2. Observed Behaviors / Signals

**Current workflow creates multiple files:**

```
/discover topic
  → docs/analysis/20251205_discover_topic.md (NEW FILE)

/shape docs/analysis/20251205_discover_topic.md
  → docs/backlog/P2-topic.md (NEW FILE)

/design docs/backlog/P2-topic.md
  → docs/analysis/20251205_design_topic.md (NEW FILE)

/deliver docs/analysis/20251205_design_topic.md
  → code changes + Implementation Report (NEW FILE or inline)

/discern
  → docs/analysis/20251205_review_topic.md (NEW FILE)

/done
  → moves 3-4 files to docs/archive/
```

**Result:** 4-5 files created per feature, then archived together.

**Current command context writing patterns:**

| Command | Writes To |
|---------|-----------|
| `/discover` | `docs/analysis/YYYYMMDD_discover_{topic}.md` |
| `/shape` | `docs/backlog/{priority}-{topic}.md` |
| `/design` | `docs/analysis/YYYYMMDD_design_{topic}.md` |
| `/deliver` | Code + `docs/analysis/YYYYMMDD_impl_{topic}.md` |
| `/discern` | `docs/analysis/YYYYMMDD_review_{topic}.md` |

**Observation:** The backlog item exists but subsequent phases don't update it — they create parallel analysis files.

---

## 3. Pain Points / Friction Areas

- **File sprawl:** Each workflow produces 4-5 files that must be archived together
- **Split context:** Design, implementation, and review details live in separate files from the shaped contract
- **Backlog disconnect:** After shaping, the backlog item is essentially frozen — work continues elsewhere
- **Archive complexity:** Must gather multiple files from `docs/analysis/` to archive as a unit
- **Discovery artifacts orphaned:** Pre-shape discovery exists only in `docs/analysis/`, not linked to backlog
- **Status unclear:** Which artifacts are "active" vs "historical" isn't obvious until `/done` runs

---

## 4. Telemetry Patterns

> Based on our recent workflow test

- **Files created:** 6 files for "agents complement commands" work
- **Files created:** 6 files for "artifact lifecycle done command" work
- **Archive action:** Moved 3 files each to archive (discover, design, review)
- **Backlog unchanged:** Shaped contract remained in backlog, not updated during design/deliver/discern

---

## 5. JTBD / User Moments

**Primary Job:**
"When I'm tracking a feature through the genie workflow, I want to see all progress in one place so I can understand the current state without hunting through multiple files."

**Related Jobs:**
- "When reviewing backlog items, I want to see which have been worked on and what stage they're at."
- "When returning to past work, I want to find everything about that feature in one location."

**Key Moments:**
- Reviewing backlog to pick next work
- Checking status of in-progress work
- Onboarding new contributor to existing work
- Auditing decisions made during a feature

---

## 6. Assumptions & Evidence

### Assumption 1: Separate analysis files add unnecessary overhead

- **Type:** Value
- **What we believe:** Having discover/design/review as separate files creates cognitive overhead and file management burden
- **Evidence for:** We just archived 6 files for 2 features; commands explicitly write to separate paths
- **Evidence against:** Separate files allow independent version history; some workflows may not complete (partial discovery)
- **Confidence:** Medium
- **Test idea:** Run a workflow where all phases update the backlog item directly, compare experience

### Assumption 2: The backlog item should evolve rather than remain static

- **Type:** Usability
- **What we believe:** After shaping, the backlog item should accumulate design decisions, implementation notes, and review outcomes
- **Evidence for:** Shape Up philosophy — shaped work is a "bet" that gets refined as you build
- **Evidence against:** Keeping shaped contract pristine preserves original scope (deviation becomes visible)
- **Confidence:** Medium
- **Test idea:** Add sections to backlog template for design/impl/review updates

### Assumption 3: Pre-shape discovery should merge into the backlog item

- **Type:** Value
- **What we believe:** Discovery insights should become part of the backlog item, not a separate referenced file
- **Evidence for:** Discovery informs shaping — having it inline keeps context together
- **Evidence against:** Discovery may spawn multiple shaped items; one-to-many relationship doesn't fit
- **Confidence:** Low — this may be the wrong assumption
- **Test idea:** Try workflow where discovery produces a backlog draft directly

---

## 7. Technical / Architectural Signals

- **Feasibility:** Straightforward — this is command and template changes only
- **Constraints:**
  - Templates already use YAML frontmatter
  - Commands already update `docs/backlog/` for some phases
- **Dependencies:** None — isolated change to genie-team
- **Architecture fit:** Consistent with markdown-based, file-as-state philosophy
- **Risks:**
  - Large backlog items could become unwieldy
  - Merge conflicts if multiple phases edited same file rapidly
- **Needs Architect spike:** No — design is straightforward

---

## 8. Opportunity Areas (Unshaped)

- **Opportunity 1: Single-file backlog items** — Backlog item accumulates all phase outputs (discovery summary, design decisions, impl notes, review verdict) as sections

- **Opportunity 2: Minimal analysis files** — Only create separate analysis files for pre-shape discovery (which may not result in shaped work); post-shape phases update backlog directly

- **Opportunity 3: Phase sections in shaped template** — Add expandable sections to shaped contract template for Design, Implementation, Review that genies populate

- **Opportunity 4: Keep current model, improve `/done`** — Accept multiple files as intentional separation of concerns; improve archival UX instead

---

## 9. Evidence Gaps

- **Missing data:**
  - How do other Shape Up practitioners handle artifact lifecycle?
  - What's the typical backlog item size after accumulating all phases?

- **Unanswered questions:**
  - Should discovery always create a backlog item, or remain separate until shaping?
  - How to handle discovery that spawns multiple shaped items?
  - What's lost by not having separate version-controlled analysis files?

- **Research needed:**
  - Review Shape Up methodology for artifact patterns
  - Test backlog-centric workflow on real feature

---

## 10. Recommended Next Steps

- [ ] Map the ideal workflow: what should happen to artifacts at each phase transition?
- [ ] Design a "living backlog item" template with sections for each phase
- [ ] Prototype: run one feature with backlog-centric approach, compare to current
- [ ] Decide: should discovery stay separate (pre-commitment) vs merge (post-commitment)?

---

## 11. Routing Recommendation

**Recommended route:**
- [ ] Continue Discovery — Need to map desired workflow before shaping
- [x] **Ready for Shaper** — Problem is clear, options identified, ready to make tradeoff decisions
- [ ] Needs Architect Spike — N/A
- [ ] Needs Navigator Decision — Shaper can present options, Navigator decides

**Rationale:** The core question is a design choice, not a technical constraint. Shaper should present options (backlog-centric vs current multi-file) with tradeoffs for Navigator decision.

---

## 12. Artifacts Created

- **Snapshot saved to:** `docs/analysis/20251205_discover_backlog_centric_workflow.md`
- **Backlog item created:** No — awaiting shaping

---

## 13. Notes for Future Discovery

- Consider how this interacts with parallel work on same concept (multiple enhancements)
- Explore whether backlog items could have "sub-items" for related enhancements
- Think about how AI agents (vs Claude commands) might update backlog items directly

---

# End of Opportunity Snapshot
