---
type: design
concept: artifact-lifecycle
enhancement: done-command
status: completed
created: 2025-12-05
---

# Design Document: /done Command
### Architect Genie — 2025-12-05

---

## 1. Design Overview

The `/done` command provides a completion ceremony for finished work, updating artifact status and archiving to an organized directory structure. It's context-aware, inferring concept and enhancement from artifacts when not explicitly provided.

**Input:** `docs/backlog/P2-artifact-lifecycle-done-command.md`
**Appetite:** Small (1-2 days)
**Complexity:** Simple

---

## 2. Architecture

### System Context

```
User completes workflow → /discern APPROVED
                              ↓
                         /done [optional args]
                              ↓
              ┌───────────────┼───────────────┐
              ↓               ↓               ↓
      Find artifacts    Update status    Move to archive
```

### Component Design

| Component | Responsibility | New/Modified |
|-----------|---------------|--------------|
| `commands/done.md` | Command definition for `/done` | New |
| `genies/*/templates` | Add frontmatter to 6 templates | Modified |
| Archive structure | `docs/archive/{concept}/YYYY-MM-DD_{enhancement}/` | New directory pattern |

### Data Flow

```
1. Parse args: /done | /done [path] | /done [concept]
2. Identify artifacts:
   - No args: Read docs/context/current_work.md for active concept/enhancement
   - Path arg: Read frontmatter from specified artifact
   - Concept arg: Glob docs/analysis/*_{concept}*.md with status: active
3. For each artifact:
   - Update status: active → completed
   - Preserve original content
4. Create archive directory: docs/archive/{concept}/YYYY-MM-DD_{enhancement}/
5. Move artifacts to archive
6. Output completion summary
```

---

## 3. Interfaces & Contracts

### Command Signature

```
/done                     # Context-aware (from current_work.md or most recent artifact)
/done [artifact-path]     # Read concept/enhancement from artifact frontmatter
/done [concept]           # Archive all active artifacts for this concept
```

### Artifact Frontmatter Format

```yaml
---
type: discover | design | review | implementation | cleanup
concept: {concept-name}
enhancement: {enhancement-name}
status: active | completed
created: YYYY-MM-DD
---
```

**Field Definitions:**
- `type`: Artifact type matching genie output (discover, design, review, etc.)
- `concept`: Feature or capability category (e.g., `agents`, `authentication`)
- `enhancement`: Specific work item (e.g., `complement-commands`, `refresh-tokens`)
- `status`: Lifecycle state — artifacts start as `active`, `/done` marks `completed`
- `created`: Date artifact was created

### Archive Directory Structure

```
docs/archive/
├── {concept}/
│   └── YYYY-MM-DD_{enhancement}/
│       ├── discover_{concept}_{enhancement}.md
│       ├── design_{concept}_{enhancement}.md
│       └── review_{concept}_{enhancement}.md
```

**Example:**
```
docs/archive/
├── agents/
│   └── 2025-12-05_complement-commands/
│       ├── discover_agents_complement_commands.md
│       ├── design_agents_complement_commands.md
│       └── review_agents_complement_commands.md
```

### Output Format

```
## /done Complete

**Concept:** {concept}
**Enhancement:** {enhancement}

### Archived Artifacts
- {original_path} → {archive_path}
- {original_path} → {archive_path}
- {original_path} → {archive_path}

**Status:** All {count} artifacts marked completed and archived.
**Archive location:** docs/archive/{concept}/YYYY-MM-DD_{enhancement}/
```

---

## 4. Pattern Adherence

### Patterns Applied
- **YAML frontmatter:** Standard metadata format (matches agent definitions)
- **Context-aware commands:** Follows `/handoff` pattern of inferring from context
- **File-based state:** No database — status lives in markdown files

### Project Conventions Followed
- [x] Markdown-based configuration
- [x] Date-prefixed directories for chronological ordering
- [x] Underscore-separated naming (consistent with existing artifacts)
- [x] Optional args with sensible defaults

### Deviations from Convention
| Deviation | Justification |
|-----------|---------------|
| None | Follows existing patterns |

---

## 5. Technical Decisions

| Decision | Options Considered | Choice | Rationale |
|----------|-------------------|--------|-----------|
| Frontmatter format | YAML vs inline markdown | YAML | Standard, parseable, Claude Code convention |
| Archive path | Date-first vs concept-first | Concept-first | Shows concept evolution over time |
| Status values | Boolean vs enum | Enum (active/completed) | Extensible for future states |
| Context inference | Require explicit vs infer | Infer from context | Reduces friction, matches user workflow |

---

## 6. Implementation Guidance

### File Structure

```
commands/
└── done.md              # New command definition

genies/
├── scout/
│   └── OPPORTUNITY_SNAPSHOT_TEMPLATE.md    # Add frontmatter
├── shaper/
│   └── SHAPED_WORK_CONTRACT_TEMPLATE.md    # Add frontmatter (no status - stays in backlog)
├── architect/
│   └── DESIGN_DOCUMENT_TEMPLATE.md         # Add frontmatter
├── critic/
│   └── REVIEW_DOCUMENT_TEMPLATE.md         # Add frontmatter
├── crafter/
│   └── IMPLEMENTATION_REPORT_TEMPLATE.md   # Add frontmatter
└── tidier/
    └── CLEANUP_REPORT_TEMPLATE.md          # Add frontmatter

docs/
└── archive/             # Created by /done as needed
    └── {concept}/
        └── YYYY-MM-DD_{enhancement}/
```

### Implementation Sequence

1. [ ] Create `commands/done.md` with command definition
2. [ ] Add frontmatter section to all 6 genie templates (5 get status field)
3. [ ] Update `docs/context/current_work.md` to track active concept/enhancement
4. [ ] Test with existing artifacts from agents work

### Template Frontmatter Additions

**For OPPORTUNITY_SNAPSHOT_TEMPLATE.md:**
```yaml
---
type: discover
concept: {concept}
enhancement: {enhancement}
status: active
created: {YYYY-MM-DD}
---

# Opportunity Snapshot — Scout Genie
...
```

**For DESIGN_DOCUMENT_TEMPLATE.md:**
```yaml
---
type: design
concept: {concept}
enhancement: {enhancement}
status: active
created: {YYYY-MM-DD}
---

# Design Document — Architect Genie
...
```

**For REVIEW_DOCUMENT_TEMPLATE.md:**
```yaml
---
type: review
concept: {concept}
enhancement: {enhancement}
status: active
created: {YYYY-MM-DD}
---

# Review Document — Critic Genie
...
```

**For IMPLEMENTATION_REPORT_TEMPLATE.md:**
```yaml
---
type: implementation
concept: {concept}
enhancement: {enhancement}
status: active
created: {YYYY-MM-DD}
---

# Implementation Report — Crafter Genie
...
```

**For CLEANUP_REPORT_TEMPLATE.md:**
```yaml
---
type: cleanup
concept: {concept}
enhancement: {enhancement}
status: active
created: {YYYY-MM-DD}
---

# Cleanup Report — Tidier Genie
...
```

**For SHAPED_WORK_CONTRACT_TEMPLATE.md:**
```yaml
---
type: shaped-work
concept: {concept}
enhancement: {enhancement}
created: {YYYY-MM-DD}
---

# Shaped Work Contract — Shaper Genie
...
```

Note: Shaped work contracts don't have `status` field — they live in `docs/backlog/` and are not archived by `/done`. They represent the "bet" and remain as historical record.

### Key Considerations

**Must do:**
- Command must handle all three invocation modes
- Frontmatter must be valid YAML (with `---` delimiters)
- Archive directory must be created if it doesn't exist
- Status field must be updated before moving
- Completion summary must show what was archived

**Should do:**
- Preserve file permissions when moving
- Handle edge case: artifact already marked completed
- Validate frontmatter exists before processing

**Nice to have:**
- Dry-run mode: `--dry-run` to preview without changes
- Undo tracking: Record original paths for potential `/reopen`

---

## 7. Error Handling & Edge Cases

| Scenario | Expected Behavior | Handling |
|----------|-------------------|----------|
| No artifacts found | Informative message | "No active artifacts found for {concept}" |
| Missing frontmatter | Skip with warning | "Skipping {file}: no frontmatter found" |
| Archive dir exists | Merge files | Move new files into existing directory |
| File already in archive | Skip | "Already archived: {file}" |
| No context available | Ask for clarification | "Specify artifact path or concept: /done [path\|concept]" |
| Mixed concepts in args | Process only matching | Only archive artifacts matching specified concept |

### Failure Modes
- **Graceful degradation:** If one artifact fails, continue with others and report at end
- **Critical failures:** File permission errors should stop and report clearly

---

## 8. Performance Considerations

### Expected Load
- Typical: 1-5 artifacts per `/done` invocation
- Maximum: ~20 artifacts for large features

### Potential Bottlenecks
- None expected — simple file operations

### Optimization Opportunities
- N/A for this scope

---

## 9. Security Considerations

### Threat Model
- **Data sensitivity:** Low — artifacts are documentation
- **Attack surface:** File paths from user input

### Security Measures
- [x] Validate paths stay within docs/ directory
- [x] No shell expansion of user input
- [x] Standard file permissions preserved

---

## 10. Testing Strategy

### Manual Testing

| Scenario | Test Steps | Expected Result |
|----------|-----------|-----------------|
| Context-aware invocation | Run `/done` after `/discern APPROVED` | Archives all related artifacts |
| Path invocation | `/done docs/analysis/20251205_discover_agents.md` | Archives specified artifact + related |
| Concept invocation | `/done agents` | Archives all active agents artifacts |
| No artifacts | `/done nonexistent` | "No active artifacts found" message |
| Already completed | `/done` on completed artifact | "Already archived" message |

### Verification

After running `/done`:
1. Check `docs/archive/{concept}/{date}_{enhancement}/` exists
2. Verify artifacts have `status: completed`
3. Verify original locations are empty
4. Run `ls docs/analysis/` — should not contain archived files

---

## 11. Rollback / Feature Flag Plan

### Rollback Procedure

1. Move files from `docs/archive/{concept}/{date}_{enhancement}/` back to `docs/analysis/`
2. Update `status: completed` → `status: active` in frontmatter
3. No permanent changes — fully reversible

### Feature Flag
- Not needed — simple file operations, easily reversible

---

## 12. Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Accidental archive of wrong files | Low | Medium | Context confirmation in output |
| Broken references to moved files | Low | Low | Files rarely cross-referenced by path |

### Accepted Risks
- Artifacts must have valid frontmatter to be processed

---

## 13. Open Questions for Crafter

- [x] **Frontmatter parsing:** Claude can read YAML frontmatter natively — no special parsing needed
- [ ] **Context inference:** How should `current_work.md` track active concept/enhancement? (Suggest simple YAML)
- [ ] **Artifact renaming:** Should files be renamed when moved to archive? (Suggest: no — keep original names)

---

## 14. Routing

**Recommended route:**
- [x] **Crafter** - Design complete, ready for implementation

**Rationale:** Simple file operations, clear specification, low risk. Crafter can implement directly.

---

## 15. Artifacts Created

- **Design saved to:** `docs/analysis/20251205_design_done_command.md`
- **ADR created:** No (scope too small)
- **Architecture docs updated:** No

---

# End of Design Document
