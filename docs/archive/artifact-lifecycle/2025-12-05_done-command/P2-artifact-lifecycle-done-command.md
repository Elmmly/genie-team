# Shaped Work Contract: Artifact Lifecycle & /done Command
### Shaper Genie — 2025-12-05

---

## 1. Problem / Opportunity Statement

**Original input:** "Consider options for a /done or alternative workflow command that marks the metadata status to done on all of the docs and moves them to archive."

**Reframed problem:** After completing a feature workflow (discover → design → deliver → discern), artifacts remain in `docs/analysis/` with no indication they represent finished work. There's no "completion ceremony" to mark work done, causing confusion about which artifacts are active vs historical.

---

## 2. Evidence & Insights

**From Discovery:** `docs/analysis/20251205_discover_artifact_lifecycle.md`

- **Observed pain:** We just ran a full workflow and artifacts are orphaned
- **Current state:** 3 artifacts exist with no status indication
- **Missing mechanism:** No archive path, no status field, no completion command
- **User moment:** "After `/discern` returns APPROVED, I want to finalize and archive"

**Behavioral Signals:**
- Navigator had to manually ask "what do we do with these docs now?"
- Confusion about which artifacts represent completed vs in-progress work

---

## 3. Strategic Alignment

- **North-star Alignment:** Genie-team should produce a clean document trail that's useful over time
- **Product Pillars:** Supports "learnability" — understanding past decisions
- **Persona:** Navigator managing multiple features over time
- **Opportunity Cost:** Not doing this means artifacts accumulate without organization

---

## 4. Appetite (Scope Box)

- **Appetite:** Small (1-2 days)
- **Boundaries:**
  - Add `/done` command to finalize completed work
  - Add status metadata to artifact templates
  - Simple archive mechanism (move files)
- **No-Gos:**
  - No database or complex state management
  - No automatic artifact linking/graph
  - No implementation report enforcement (separate scope)
- **Fixed Elements:**
  - Must work with existing markdown-based artifacts
  - Must be optional (not forced on every workflow)

---

## 5. Goals (Hybrid Format)

### Outcome Hypothesis
"We believe that adding a `/done` command with status metadata will result in cleaner artifact organization for Navigators managing multiple features."

### Success Signals
- Artifacts clearly indicate completed vs active status
- `docs/analysis/` contains only active work
- Completed work is findable in archive

### JTBD
"When I finish a feature and get APPROVED from Critic, I want to mark all related artifacts as done so I know the work is complete and can find it later if needed."

---

## 6. Opportunities & Constraints

### Opportunities
- Clear completion signal after `/discern` APPROVED
- Organized document trail for future reference
- Reduced cognitive load when browsing artifacts

### Constraints
- **Technical:** Markdown files only — no database
- **Appetite:** Must be achievable in 1-2 days
- **User:** Should feel lightweight, not bureaucratic

### Risks
- **Value Risk:** Low — we just experienced the pain directly
- **Usability Risk:** Low — simple command
- **Feasibility Risk:** Low — just file operations and metadata
- **Viability Risk:** Low — natural extension of existing workflow

---

## 7. Riskiest Assumptions

### Primary Riskiest Assumption
- **Type:** Value
- **Assumption:** Users will actually use `/done` after workflows complete
- **Fastest Test:** Use it ourselves for 2-3 workflows, see if it feels natural
- **Invalidation Signal:** We forget to run it or it feels like busywork

### Secondary Assumption
- **Assumption:** Archiving to `docs/archive/` is better than status-only
- **Test:** Implement both, see which we prefer
- **Signal:** If we never look at archive, status-only is sufficient

---

## 8. Dependencies

### Minor Dependencies
- None — this is standalone workflow enhancement

### Major Dependencies
- None

---

## 9. Open Questions

- **For Architect:** Should status be YAML frontmatter or inline markdown header?
- **For Navigator:** Prefer `/done` (explicit) or enhance `/discern --approve` (integrated)?

---

## 10. Recommendation (Options + Ranked)

### Option 1: `/done` Command (Explicit Completion)

**Description:** New command that:
1. Takes a topic or list of artifact paths
2. Adds `status: completed` to each artifact's frontmatter
3. Moves artifacts to `docs/archive/YYYY-MM/` (or `docs/archive/{topic}/`)
4. Outputs completion summary

**Command signature:**
```
/done                           # Uses concept/enhancement from current context
/done [artifact-path]           # Reads concept/enhancement from artifact frontmatter
/done [concept]                 # Archives all active artifacts for this concept
```

**Examples:**
```
/done                                                    # Context-aware
/done docs/analysis/20251205_review_agents.md           # From specific artifact
/done agents                                             # All active work in concept
```

**Artifact frontmatter (added to templates):**
```yaml
---
concept: agents
enhancement: complement-commands
status: active
---
```

**Pros:**
- Minimal input required — context flows from workflow
- Explicit, intentional completion
- Works for any workflow (not just post-discern)

**Cons:**
- Extra step after `/discern`
- Requires frontmatter in artifact templates

**Appetite fit:** Fits comfortably

---

### Option 2: Enhance `/discern --complete` (Integrated Completion)

**Description:** Add `--complete` flag to `/discern` that:
1. After APPROVED verdict, marks all related artifacts as completed
2. Moves to archive
3. No separate command needed

**Pros:**
- Single command for review + completion
- Natural workflow integration

**Cons:**
- Only works after `/discern` (not standalone)
- Mixes review responsibility with archival
- What if you want to review but not archive yet?

**Appetite fit:** Fits, but conflates concerns

---

### Option 3: Status-Only (No Archive)

**Description:**
1. Add `status: active | completed` frontmatter to all artifacts
2. Commands update status at transitions
3. No physical archive — just filter by status

**Pros:**
- Simplest implementation
- No file movement complexity
- `/context:recall` can filter by status

**Cons:**
- `docs/analysis/` still accumulates files
- No visual decluttering

**Appetite fit:** Very comfortable, possibly too minimal

---

### Ranked Recommendation

**Top Recommendation:** Option 1 (`/done` Command)

**Reasoning:**
1. **Explicit is better than implicit** — completion is a deliberate act
2. **Separation of concerns** — review (discern) vs completion (done) are different
3. **Flexibility** — works for any workflow, not just post-discern
4. **Archive provides real value** — declutters active workspace
5. **Matches genie-team philosophy** — explicit handoffs, user confirmation

---

## 11. Routing Target

**Recommended route:**
- [x] **Architect** — Brief design for command and archive structure
- [ ] **Crafter** — After Architect, straightforward implementation
- [ ] **Scout** — N/A
- [ ] **Navigator** — Approve approach before implementation

**Rationale:** Small scope but needs brief design pass to nail down:
- Artifact frontmatter format
- Archive directory structure
- How to identify "related" artifacts by topic

---

## 12. Bet Framing

> Small appetite — minimal bet framing needed

- **Appetite:** 1-2 days
- **Why Now:** We just experienced the pain; best time to fix
- **Expected Impact:** Cleaner document trail, less confusion
- **Risk:** Very low — worst case we don't use it

---

## 13. Breadcrumbs

- **Related:** Consider `/reopen` command for archived work (future)
- **Related:** Implementation report enforcement is separate scope
- **Related:** Artifact linking (discovery → design → impl) is future enhancement

---

## 14. Artifacts

- **Contract saved to:** `docs/backlog/P2-artifact-lifecycle-done-command.md`
- **Discovery referenced:** `docs/analysis/20251205_discover_artifact_lifecycle.md`

---

## Navigator Decisions

**Decided 2025-12-05:**
1. **Approach:** Explicit `/done` command (confirmed)
2. **Archive structure:** `docs/archive/{concept}/YYYY-MM-DD_{enhancement}/`
   - `{concept}` = feature or capability category (e.g., `agents`, `authentication`, `notifications`)
   - `{enhancement}` = specific work item (e.g., `complement-commands`, `refresh-tokens`)
   - Shows how related concepts evolve over time

**Example:**
```
docs/archive/
├── agents/
│   ├── 2025-12-05_complement-commands/
│   │   ├── discover_agents_complement_commands.md
│   │   ├── design_agents_complement_commands.md
│   │   └── review_agents_complement_commands.md
│   └── 2025-12-10_parallel-execution/
│       └── ...
├── authentication/
│   └── 2025-12-08_refresh-tokens/
│       └── ...
```

---

## Acceptance Criteria

For this shaped work to be complete:

1. [ ] `/done` command exists with three invocation modes:
   - No args (uses current context)
   - Artifact path (reads frontmatter)
   - Concept name (archives all active for concept)
2. [ ] Artifact templates updated with frontmatter: `concept`, `enhancement`, `status`
3. [ ] Command updates `status: active` → `status: completed` in frontmatter
4. [ ] Command moves artifacts to `docs/archive/{concept}/YYYY-MM-DD_{enhancement}/`
5. [ ] Creates directory structure if it doesn't exist
6. [ ] Completion summary output shows what was archived
7. [ ] `/discover`, `/design`, `/discern` templates include frontmatter fields

---

# End of Shaped Work Contract
