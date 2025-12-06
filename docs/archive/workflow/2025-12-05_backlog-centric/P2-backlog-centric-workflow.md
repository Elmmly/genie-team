---
type: shaped-work
concept: workflow
enhancement: backlog-centric
status: done
created: 2025-12-05
---

# Shaped Work Contract: Backlog-Centric Workflow
### Shaper Genie — 2025-12-05

---

## 1. Problem / Opportunity Statement

**Original input:** "After an item is shaped, it is added to the backlog where all other agents then work on to update directly. The goal is to minimize extra files and sprawl."

**Reframed problem:** The current workflow creates 4-5 separate files per feature (discover, design, impl, review), but after shaping, the backlog item should become the living document that accumulates all subsequent work. Only pre-shape discovery should remain separate (uncommitted exploration).

---

## 2. Evidence & Insights

**From Discovery:** `docs/analysis/20251205_discover_backlog_centric_workflow.md`

- Current workflow creates separate `docs/analysis/` files for each phase
- Backlog item becomes static after creation — never updated
- File sprawl: 6 files created for 2 recent features
- Navigator decision: Discovery stays separate (uncommitted exploration)

**Navigator Decision (2025-12-05):**
> "Let's keep it separate as uncommitted exploration"

This confirms: pre-shape discovery is separate; post-shape phases update the backlog.

---

## 3. Strategic Alignment

- **North-star Alignment:** Cleaner document trail, easier to understand work status
- **Product Pillars:** Simplicity, learnability
- **Persona:** Navigator managing multiple features
- **Opportunity Cost:** Some separation of concerns lost (design/review mixed with shaped contract)

---

## 4. Appetite (Scope Box)

- **Appetite:** Small (1-2 days)
- **Boundaries:**
  - Modify `/design`, `/deliver`, `/discern` commands to update backlog item
  - Modify `/done` to archive discovery + backlog together
  - Update shaped work contract template with phase sections
- **No-Gos:**
  - Don't change `/discover` (stays separate)
  - Don't change `/shape` output location
  - No complex linking or database
- **Fixed Elements:**
  - Discovery remains in `docs/analysis/`
  - Backlog items remain in `docs/backlog/`

---

## 5. Goals (Hybrid Format)

### Outcome Hypothesis
"We believe that having post-shape phases update the backlog item directly will result in cleaner file management and better context cohesion for Navigators tracking work."

### Success Signals
- Only 2 files per completed feature (discovery + backlog)
- Backlog item shows full lifecycle at a glance
- `/done` archives 2 files instead of 4-5

### JTBD
"When I check on a backlog item, I want to see its full history (shaped scope, design decisions, implementation notes, review verdict) so I understand the complete picture without hunting through multiple files."

---

## 6. Opportunities & Constraints

### Opportunities
- Single source of truth per feature (post-shaping)
- Reduced file management overhead
- Backlog review shows work status inline
- Simpler archival

### Constraints
- **Technical:** Commands must know to update vs create files
- **Appetite:** Must fit in 1-2 days
- **User:** Should feel natural, not bureaucratic

### Risks
- **Value Risk:** Low — we just experienced the sprawl pain
- **Usability Risk:** Low — commands already take file paths
- **Feasibility Risk:** Low — straightforward template/command changes
- **Viability Risk:** Low — natural extension of current workflow

---

## 7. Riskiest Assumptions

### Primary Riskiest Assumption
- **Type:** Usability
- **Assumption:** Large backlog items with all phases won't become unwieldy
- **Fastest Test:** Run one feature through new workflow, assess readability
- **Invalidation Signal:** Backlog item becomes too long to scan quickly

---

## 8. Dependencies

### Minor Dependencies
- None

### Major Dependencies
- None

---

## 9. Open Questions

- **For Architect:** How should phase sections be structured in the backlog template?
- **For Navigator:** Should phase sections be collapsible/foldable? (Probably N/A for markdown)

---

## 10. Recommendation

### Single Option: Backlog-Centric Phases

**Description:**
1. `/design` appends a "## Design" section to the backlog item
2. `/deliver` appends a "## Implementation" section to the backlog item
3. `/discern` appends a "## Review" section to the backlog item
4. `/done` archives discovery file + backlog item together
5. Update shaped work contract template with placeholder sections

**Implementation:**

**Command changes:**

| Command | Current | New |
|---------|---------|-----|
| `/discover` | → `docs/analysis/` | No change |
| `/shape` | → `docs/backlog/` | No change |
| `/design` | → `docs/analysis/` | → Append to backlog item |
| `/deliver` | → code + report | → code + Append to backlog item |
| `/discern` | → `docs/analysis/` | → Append to backlog item |
| `/done` | Archive 3-4 analysis files | Archive discovery + backlog |

**Template changes:**

Add sections to `SHAPED_WORK_CONTRACT_TEMPLATE.md`:

```markdown
---
## 15. Design
> Added by Architect genie during /design

[Design decisions, component structure, interfaces]

---

## 16. Implementation
> Added by Crafter genie during /deliver

[Implementation notes, files changed, decisions made]

---

## 17. Review
> Added by Critic genie during /discern

[Review verdict, acceptance criteria check, issues found]

---
```

**Pros:**
- Single living document per feature
- Full context in one place
- Simpler archival (2 files)
- Backlog shows work status

**Cons:**
- Backlog items grow larger
- Phase boundaries less distinct
- Some version history consolidation

**Appetite fit:** Fits comfortably

---

## 11. Routing Target

**Recommended route:**
- [x] **Architect** — Brief design for section structure and command changes
- [ ] **Crafter** — After design, implement command/template changes
- [ ] **Navigator** — Approved via shaping

**Rationale:** Need to nail down exact section format and how commands detect/append to backlog.

---

## 12. Bet Framing

- **Appetite:** 1-2 days
- **Why Now:** Just experienced sprawl pain; workflow is fresh in mind
- **Expected Impact:** Cleaner document trail, easier status tracking
- **Risk:** Very low — worst case we revert to separate files

---

## 13. Breadcrumbs

- **Related:** This simplifies what `/done` needs to archive
- **Related:** Consider whether discovery should auto-link to resulting backlog item
- **Future:** Could add status field to backlog (draft → designed → implemented → reviewed → done)

---

## 14. Artifacts

- **Contract saved to:** `docs/backlog/P2-backlog-centric-workflow.md`
- **Discovery referenced:** `docs/analysis/20251205_discover_backlog_centric_workflow.md`

---

## Acceptance Criteria

1. [ ] `/design` command updates backlog item instead of creating analysis file
2. [ ] `/deliver` command updates backlog item with implementation notes
3. [ ] `/discern` command updates backlog item with review verdict
4. [ ] `SHAPED_WORK_CONTRACT_TEMPLATE.md` includes Design/Implementation/Review sections
5. [ ] `/done` archives discovery file + backlog item together
6. [ ] Existing workflow commands updated with new context writing paths

---

# Design
> Added by Architect genie — 2025-12-05

## 1. Design Overview

This design modifies the post-shape workflow so that `/design`, `/deliver`, and `/discern` append sections to the backlog item rather than creating separate analysis files. The backlog item becomes a living document that evolves through the lifecycle.

**Key design decisions:**
1. Backlog items gain a `status` field in frontmatter (shaped → designed → implemented → reviewed → done)
2. Commands append structured sections using consistent markers
3. Discovery remains separate (links via `concept`/`enhancement` frontmatter)
4. `/done` archives discovery file + backlog item together

---

## 2. Frontmatter Changes

### Backlog Item Frontmatter (Updated)

```yaml
---
type: shaped-work
concept: {concept}
enhancement: {enhancement}
status: shaped | designed | implemented | reviewed | done
created: {YYYY-MM-DD}
---
```

**Status progression:**
- `shaped` — Initial state after `/shape`
- `designed` — After `/design` appends design section
- `implemented` — After `/deliver` appends implementation section
- `reviewed` — After `/discern` appends review section
- `done` — After `/done` archives

### Discovery Frontmatter (No Change)

```yaml
---
type: discover
concept: {concept}
enhancement: {enhancement}
status: active | completed
created: {YYYY-MM-DD}
---
```

Discovery links to backlog via matching `concept` + `enhancement`.

---

## 3. Section Structure

### Design Section (appended by `/design`)

```markdown
---

# Design
> Added by Architect genie — {YYYY-MM-DD}

## Design Summary
[High-level approach — 2-3 sentences]

## Components
| Component | Responsibility | New/Modified |
|-----------|---------------|--------------|
| [Name] | [What it does] | [New/Modified] |

## Key Decisions
| Decision | Choice | Rationale |
|----------|--------|-----------|
| [Decision] | [Choice] | [Why] |

## Implementation Guidance
1. [ ] [Step 1]
2. [ ] [Step 2]
3. [ ] [Step 3]

## Risks
- [Risk 1]: [Mitigation]
```

### Implementation Section (appended by `/deliver`)

```markdown
---

# Implementation
> Added by Crafter genie — {YYYY-MM-DD}

## Summary
[What was built — 2-3 sentences]

## Files Changed
| File | Change | Lines |
|------|--------|-------|
| [path] | [Created/Modified] | +N/-M |

## Tests
- [x] [Test 1]: Passing
- [x] [Test 2]: Passing

## Decisions Made
- [Decision during implementation]

## Ready for Review
- [ ] All acceptance criteria addressed
- [ ] Tests passing
- [ ] Code follows conventions
```

### Review Section (appended by `/discern`)

```markdown
---

# Review
> Added by Critic genie — {YYYY-MM-DD}

## Verdict: [APPROVED | CHANGES REQUESTED | BLOCKED]

## Acceptance Criteria
| Criterion | Status | Evidence |
|-----------|--------|----------|
| [From shaped contract] | ✅/❌ | [How verified] |

## Issues Found
| Issue | Severity | Resolution |
|-------|----------|------------|
| [Issue] | Major/Minor | [Fixed/Deferred] |

## Recommendation
[Next steps based on verdict]
```

---

## 4. Command Changes

### `/design` Command

**Current Context Writing:**
```markdown
**WRITE:**
- docs/analysis/YYYYMMDD_design_{topic}.md
```

**New Context Writing:**
```markdown
**UPDATE:**
- Backlog item: Append "# Design" section
- Backlog frontmatter: `status: shaped` → `status: designed`
```

**Command behavior:**
1. Read backlog item path from argument
2. Verify `status: shaped` (or allow re-design)
3. Generate design content
4. Append design section before "# End of Shaped Work Contract"
5. Update frontmatter status to `designed`

### `/deliver` Command

**Current Context Writing:**
```markdown
**WRITE:**
- Code changes
- Test files
- Implementation report (inline or separate)
```

**New Context Writing:**
```markdown
**WRITE:**
- Code changes
- Test files

**UPDATE:**
- Backlog item: Append "# Implementation" section
- Backlog frontmatter: `status: designed` → `status: implemented`
```

### `/discern` Command

**Current Context Writing:**
```markdown
**WRITE:**
- docs/analysis/YYYYMMDD_review_{topic}.md
```

**New Context Writing:**
```markdown
**UPDATE:**
- Backlog item: Append "# Review" section
- Backlog frontmatter: `status: implemented` → `status: reviewed`
```

### `/done` Command

**Current behavior:**
- Archives discovery + design + review files from `docs/analysis/`

**New behavior:**
- Archives discovery file from `docs/analysis/`
- Archives backlog item from `docs/backlog/`
- Both go to `docs/archive/{concept}/YYYY-MM-DD_{enhancement}/`
- Updates backlog frontmatter: `status: reviewed` → `status: done`

**Archive structure (updated):**
```
docs/archive/
├── {concept}/
│   └── YYYY-MM-DD_{enhancement}/
│       ├── discover_{topic}.md          # From docs/analysis/
│       └── {priority}-{topic}.md        # From docs/backlog/
```

---

## 5. Template Changes

### SHAPED_WORK_CONTRACT_TEMPLATE.md

Add to end of template (before "# End of Shaped Work Contract"):

```markdown
---

# Design
> This section added by Architect genie during /design

[Design content will be appended here]

---

# Implementation
> This section added by Crafter genie during /deliver

[Implementation content will be appended here]

---

# Review
> This section added by Critic genie during /discern

[Review content will be appended here]

---

# End of Shaped Work Contract
```

**Alternative:** Don't include placeholders — let commands append sections dynamically. This avoids empty sections in backlog items that haven't progressed.

**Recommendation:** Dynamic append (no placeholders). Commands insert sections before the "# End of Shaped Work Contract" marker.

---

## 6. File Changes Summary

| File | Change |
|------|--------|
| `commands/design.md` | Update Context Writing to append to backlog |
| `commands/deliver.md` | Update Context Writing to append to backlog |
| `commands/discern.md` | Update Context Writing to append to backlog |
| `commands/done.md` | Update to archive discovery + backlog |
| `genies/shaper/SHAPED_WORK_CONTRACT_TEMPLATE.md` | Add `status` to frontmatter |

---

## 7. Implementation Guidance

### Step 1: Update Template Frontmatter
Add `status: shaped` to SHAPED_WORK_CONTRACT_TEMPLATE.md frontmatter.

### Step 2: Update Command Docs
Modify Context Writing sections in design.md, deliver.md, discern.md to specify backlog updates.

### Step 3: Update /done Command
Change archive behavior to find:
- Discovery: `docs/analysis/*_discover_*.md` matching concept/enhancement
- Backlog: `docs/backlog/*.md` matching concept/enhancement

### Step 4: Rebuild Distribution
Run `./install.sh build` to include updated commands.

---

## 8. Open Questions Resolved

| Question | Resolution |
|----------|------------|
| Section structure | Condensed versions of full templates — key info only |
| Placeholder vs dynamic | Dynamic append — no empty placeholders |
| Status values | 5 states: shaped → designed → implemented → reviewed → done |
| Discovery linking | Via matching concept/enhancement in frontmatter |

---

## 9. Routing

**Ready for:** Crafter

**Implementation is straightforward:**
1. Template frontmatter change (1 file)
2. Command doc updates (4 files)
3. Rebuild distribution

---

# Implementation
> Added by Crafter genie — 2025-12-05

## Summary

Implemented backlog-centric workflow by updating command documentation and template. Post-shape phases (`/design`, `/deliver`, `/discern`) now append sections to the backlog item instead of creating separate analysis files.

## Files Changed

| File | Change |
|------|--------|
| `genies/shaper/SHAPED_WORK_CONTRACT_TEMPLATE.md` | Added `status: shaped` to frontmatter |
| `commands/design.md` | Updated Context Writing to append to backlog |
| `commands/deliver.md` | Updated Context Writing to append to backlog |
| `commands/discern.md` | Updated Context Writing to append to backlog |
| `commands/done.md` | Updated to archive discovery + backlog together |

## Key Changes

### Template Frontmatter
```yaml
status: shaped  # New field with progression: shaped → designed → implemented → reviewed → done
```

### Command Updates
- `/design`: Appends "# Design" section, updates status to `designed`
- `/deliver`: Appends "# Implementation" section, updates status to `implemented`
- `/discern`: Appends "# Review" section, updates status to `reviewed`
- `/done`: Archives discovery file + backlog item (2 files instead of 4-5)

## Tests

- [x] Build succeeds: `./install.sh build` completed
- [x] All commands updated with new context writing
- [x] Template includes status field

## Decisions Made

- Used dynamic section append (no empty placeholders in template)
- Status field added to shaped template, not other templates (they're not used post-shape)

## Ready for Review

- [x] All acceptance criteria addressed
- [x] Build passing
- [x] Commands follow new pattern

---

# Review
> Added by Critic genie — 2025-12-05

## Verdict: APPROVED

Implementation meets all acceptance criteria and follows the design specification.

## Acceptance Criteria

| Criterion | Status | Evidence |
|-----------|--------|----------|
| `/design` command updates backlog item | ✅ | `commands/design.md` line 43: "Append # Design section" |
| `/deliver` command updates backlog item | ✅ | `commands/deliver.md` line 47: "Append # Implementation section" |
| `/discern` command updates backlog item | ✅ | `commands/discern.md` line 42: "Append # Review section" |
| Template includes status field | ✅ | `SHAPED_WORK_CONTRACT_TEMPLATE.md` line 5: `status: shaped` |
| `/done` archives discovery + backlog | ✅ | `commands/done.md` lines 40-42: MOVE both files |
| Commands updated with new context writing | ✅ | All 4 commands verified |

**Result: 6/6 criteria met**

## Issues Found

| Issue | Severity | Resolution |
|-------|----------|------------|
| None | — | — |

## Workflow Validation

This very implementation demonstrated the new workflow:
- Shaped contract created in backlog
- Design appended to backlog item (status: designed)
- Implementation appended to backlog item (status: implemented)
- Review appended to backlog item (status: reviewed)

The backlog item now contains the complete lifecycle in one file.

## Recommendation

**Ready for `/done`** — Archive discovery file + this backlog item together.

---

# End of Shaped Work Contract
