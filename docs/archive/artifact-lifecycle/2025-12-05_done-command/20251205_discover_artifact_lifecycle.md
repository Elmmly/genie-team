---
type: discover
concept: artifact-lifecycle
enhancement: done-command
status: completed
created: 2025-12-05
---

# Opportunity Snapshot: Artifact Lifecycle After Delivery
### Scout Genie Discovery — 2025-12-05

---

## 1. Discovery Question

**Original input:** "We ran discover, design, and deliver as a test but now there are artifacts that are out of date with the completed work after delivering we need a way to confirm the work completed and clean up the docs."

**Reframed question:** How should the genie-team lifecycle handle artifact state transitions after work is delivered and approved, so that documentation accurately reflects completed vs in-progress work?

---

## 2. Observed Behaviors / Signals

**Current state after our test workflow:**
- `docs/analysis/20251205_discover_agents_complement_commands.md` — Discovery artifact, now stale (work is done)
- `docs/analysis/20251205_design_agents_complement_commands.md` — Design artifact, now stale (implemented)
- No implementation report was created (Crafter didn't produce one)
- No review document exists (we skipped `/discern`)
- Artifacts don't indicate their status (in-progress vs complete vs superseded)

**Existing lifecycle gaps:**
- `/discern` exists but wasn't invoked — it's supposed to review and update status
- `/handoff deliver discern` mentions "Move to archive if complete" but no archive mechanism exists
- No `/close` or `/complete` command to finalize work
- Artifacts have no status field (draft, active, completed, archived)
- `docs/backlog/` mentioned but not used in our workflow

---

## 3. Pain Points / Friction Areas

- **Stale artifacts accumulate:** Discovery and design docs remain after work ships, creating confusion about what's current
- **No completion ceremony:** Work finishes without a clear "done" signal
- **Status is implicit:** Must read artifact content to know if work is complete
- **No archive path:** Old artifacts clutter `docs/analysis/` indefinitely
- **Missing implementation report:** Crafter should produce one but nothing enforces this
- **Disconnected artifacts:** Discovery → Design → Implementation are separate files with no linking

---

## 4. Current Workflow vs Ideal

**What happened:**
```
/discover topic → created docs/analysis/YYYYMMDD_discover_*.md
     ↓
/design doc → created docs/analysis/YYYYMMDD_design_*.md
     ↓
/deliver doc → implemented code, NO artifact created
     ↓
(stopped here — artifacts orphaned)
```

**What should happen:**
```
/discover topic → docs/analysis/YYYYMMDD_discover_*.md [status: active]
     ↓
/design doc → docs/analysis/YYYYMMDD_design_*.md [status: active]
     ↓
/deliver doc → docs/analysis/YYYYMMDD_impl_*.md [status: active]
     ↓
/discern impl → docs/analysis/YYYYMMDD_review_*.md + VERDICT
     ↓
If APPROVED:
  /close topic → marks all artifacts [status: completed]
               → optionally archives to docs/archive/
               → updates any backlog items
```

---

## 5. JTBD / User Moments

**Primary Job:**
"When I finish a feature workflow, I want to mark the work as complete so that I know which artifacts are current and which represent finished work."

**Related Jobs:**
- "When reviewing past decisions, I want to quickly find relevant artifacts without wading through stale drafts."
- "When starting new work, I want to see if related discovery/design already exists."
- "When onboarding to a project, I want to understand what's been built from the document trail."

**Key Moments:**
- After `/discern` returns APPROVED — want to finalize and archive
- When browsing `docs/analysis/` — want to distinguish active from completed
- When running `/context:recall` — want to find relevant prior work

---

## 6. Assumptions & Evidence

### Assumption 1: Artifacts need explicit status

- **Type:** Usability
- **What we believe:** Adding status metadata to artifacts would help distinguish active from completed work
- **Evidence for:** We just experienced confusion about which docs are current
- **Evidence against:** None observed
- **Confidence:** High
- **Test idea:** Add status frontmatter to artifacts, see if it helps

### Assumption 2: A `/close` or `/complete` command is needed

- **Type:** Value
- **What we believe:** Explicit completion step would clean up artifact state
- **Evidence for:** Current workflow leaves artifacts orphaned; `/discern` alone doesn't archive
- **Evidence against:** Could add friction to simple workflows
- **Confidence:** Medium-High
- **Test idea:** Add command, use it, evaluate if it feels necessary or bureaucratic

### Assumption 3: Archiving is better than deleting

- **Type:** Value
- **What we believe:** Moving completed artifacts to `docs/archive/` preserves history while decluttering
- **Evidence for:** Historical decisions are valuable for understanding "why"
- **Evidence against:** Could just leave in place with status marker
- **Confidence:** Medium
- **Test idea:** Try both approaches, see which feels right

### Assumption 4: Crafter should always produce an implementation report

- **Type:** Feasibility
- **What we believe:** `/deliver` should create `docs/analysis/YYYYMMDD_impl_*.md`
- **Evidence for:** Design doc says "Implementation Report" is expected output
- **Evidence against:** Adds overhead; code + commits might be sufficient
- **Confidence:** Medium
- **Test idea:** Enforce it for a few cycles, evaluate value

---

## 7. Opportunity Areas (Unshaped)

### Opportunity 1: Artifact Status System
Add status metadata to all genie artifacts:
- `status: draft | active | completed | archived`
- Commands update status at transitions
- `/context:recall` filters by status

### Opportunity 2: `/close` Command
New command to finalize completed work:
- Marks related artifacts as completed
- Optionally moves to archive
- Updates backlog items
- Provides completion summary

### Opportunity 3: Artifact Linking
Connect related artifacts:
- Discovery links to Design
- Design links to Implementation
- Implementation links to Review
- Enables "show me everything about feature X"

### Opportunity 4: Implementation Report Enforcement
Ensure Crafter produces artifact:
- `/deliver` always creates impl doc
- Captures what was built, decisions made
- Required for `/discern` to proceed

### Opportunity 5: Archive Structure
Organize completed work:
- `docs/archive/YYYY/` or `docs/archive/{topic}/`
- Preserves history, declutters active area
- Searchable for future reference

---

## 8. Evidence Gaps

- **Missing data:**
  - How often do users refer back to old artifacts?
  - Does status metadata actually get used?
  - Is archiving worth the complexity vs just filtering?

- **Unanswered questions:**
  - Should `/discern` APPROVED auto-trigger completion?
  - Should there be a "reopen" mechanism for archived work?
  - How to handle partially completed work (some artifacts done, others not)?

---

## 9. Recommended Next Steps

### Immediate (before shaping):
1. Manually clean up current artifacts — add status, decide archive approach
2. Decide: Is `/close` a separate command or part of `/discern --approve`?

### For Shaping:
- [ ] Define artifact status lifecycle (draft → active → completed → archived)
- [ ] Design `/close` or `/complete` command
- [ ] Decide on archive structure
- [ ] Update `/deliver` to require implementation report

---

## 10. Routing Recommendation

**Recommended route:**
- [ ] Continue Discovery — Could explore more, but problem is clear
- [x] **Ready for Shaper** — Problem understood, needs appetite and scoping
- [ ] Needs Architect Spike — No technical unknowns
- [ ] Needs Navigator Decision — Straightforward workflow improvement

**Rationale:** The problem is well-understood from direct experience. Shaper should determine appetite (how much ceremony vs simplicity) and scope the solution.

---

## 11. Artifacts Created

- **Snapshot saved to:** `docs/analysis/20251205_discover_artifact_lifecycle.md`

---

# End of Opportunity Snapshot
