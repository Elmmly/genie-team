# /done [concept|artifact-path]

Mark completed work as done and archive artifacts.

---

## Arguments

- No args: Uses context from `docs/context/current_work.md` or most recent active artifact
- `artifact-path`: Path to specific artifact (reads concept/enhancement from frontmatter)
- `concept`: Archives all active artifacts for this concept

Optional flags:
- `--dry-run`: Preview what would be archived without making changes

---

## Genie Invoked

**None** — This is a workflow command that operates on artifacts.

---

## Context Loading

**READ (automatic):**
- `docs/context/current_work.md` (for context-aware invocation)
- Target artifact(s) frontmatter
- `docs/analysis/*_discover_*.md` (to find related discovery)
- `docs/backlog/*.md` (to find related backlog item)
- `docs/topics/*.md` (to find originating topic file via `result_ref` match)
- Backlog frontmatter field `spec_ref` → load the linked spec (for preservation check)

---

## Context Writing

**UPDATE:**
- Discovery frontmatter: `status: active` → `status: completed`
- Backlog frontmatter: `status: reviewed` → `status: done`
- Topic frontmatter: `status: done` → `status: archived`

**MOVE:**
- Discovery from `docs/analysis/` → `docs/archive/{concept}/YYYY-MM-DD_{enhancement}/`
- Backlog item from `docs/backlog/` → `docs/archive/{concept}/YYYY-MM-DD_{enhancement}/`
- Topic file from `docs/topics/` → `docs/archive/{concept}/YYYY-MM-DD_{enhancement}/` (when `result_ref` matches the discovery file being archived)

**SPEC PRESERVATION (when spec_ref exists in backlog):**
1. **Never archive the spec.** Specs are persistent — only backlog items get archived.
2. **Leave the spec in place** with all accumulated knowledge (design constraints, implementation evidence, review verdicts).
3. The archived backlog item retains `spec_ref` as a historical pointer.

---

## Artifact Frontmatter

Artifacts must have YAML frontmatter to be processed:

```yaml
---
type: discover | design | review | implementation | cleanup
concept: {concept-name}
enhancement: {enhancement-name}
status: active | completed
created: YYYY-MM-DD
---
```

---

## Output

```
## /done Complete

**Concept:** {concept}
**Enhancement:** {enhancement}

### Archived Artifacts
- docs/topics/20251203_agents.md → docs/archive/agents/2025-12-05_complement-commands/
- docs/analysis/20251205_discover_agents.md → docs/archive/agents/2025-12-05_complement-commands/
- docs/backlog/P2-agents-complement-commands.md → docs/archive/agents/2025-12-05_complement-commands/

**Status:** 3 artifacts marked completed and archived.
**Archive location:** docs/archive/agents/2025-12-05_complement-commands/
```

---

## Archive Structure

```
docs/archive/
├── {concept}/
│   └── YYYY-MM-DD_{enhancement}/
│       ├── YYYYMMDD_{topic}.md                # Topic file (from docs/topics/, if present)
│       ├── YYYYMMDD_discover_{topic}.md       # Discovery (from docs/analysis/)
│       └── {priority}-{topic}.md              # Backlog item (from docs/backlog/)
```

This structure:
- Groups by concept (feature/capability category)
- Sorts chronologically within concept
- Shows how concepts evolve over time
- **2-3 files per completed feature** (optional topic + discovery + backlog item with design/impl/review)

---

## Usage Examples

```
# Context-aware (after /discern APPROVED)
/done
> Archives all active artifacts for current concept/enhancement

# From specific artifact
/done docs/analysis/20251205_discover_agents_complement_commands.md
> Reads concept/enhancement from frontmatter, archives all related

# By concept name
/done agents
> Archives all active artifacts where concept: agents

# Preview mode
/done --dry-run
> Shows what would be archived without making changes
```

---

## Verification Gate (MANDATORY)

Before archiving a backlog item that went through implementation
(`status: implemented`, `reviewed`, or later), check its Implementation
section for the **Verification block** required by `/deliver` (exact test
command with pass/fail counts, pre-existing failures, build/lint state, docs
updated, git status summary).

**If the block is absent, refuse to archive:**

```
> Cannot archive docs/backlog/P2-example.md: Implementation section has no
> Verification block. "Done" requires evidence, not a claim.
> Run the verification (see /deliver Phase 5), append the block, then re-run /done.
```

This gate does not apply to items that never reached implementation
(abandoned discoveries, superseded contracts) — those archive normally.

---

## Error Handling

| Scenario | Behavior |
|----------|----------|
| No artifacts found | "No active artifacts found for {concept}" |
| Missing frontmatter | "Skipping {file}: no frontmatter found" |
| Already completed | "Already archived: {file}" |
| Missing Verification block | Refuse to archive implemented items (see Verification Gate) |
| No context available | "Specify artifact path or concept: /done [path\|concept]" |

---

## Workflow

After `/discern` returns **APPROVED**:

```
/discern docs/analysis/20251205_impl_feature.md
> Verdict: APPROVED
> Recommended: Mark this work as complete

/done
> Concept: agents
> Enhancement: complement-commands
> Archived 3 artifacts to docs/archive/agents/2025-12-05_complement-commands/
```

---

## Topic File Tracing

When archiving a discovery file, scan `docs/topics/*.md` for any topic file whose `result_ref` frontmatter field matches the discovery file path being archived. If found:

1. Update topic frontmatter: `status: done` → `status: archived`
2. Move to the same archive directory as the discovery file
3. Include in the archive summary output

This ensures topic files don't accumulate in `docs/topics/` after their work is complete. External systems can detect archival via `status: archived` or the file's absence from `docs/topics/`.

---

## Notes

- Only processes artifacts with valid frontmatter
- Archives discovery file, backlog item, AND originating topic file together
- Backlog item contains shaped contract + design + implementation + review (living document)
- Creates archive directory structure if it doesn't exist
- Preserves original filenames in archive
- Fully reversible: move files back and update status
- **Specs are never archived** — they persist as the source of truth for what the system does
- **Topic files are archived** when their `result_ref` matches an archived discovery file

---

## Autonomous Safety

When `/done` runs within an autonomous `/run` lifecycle:

- **NEVER amend a previous commit.** Archive updates (status changes,
  `current_work.md` updates, file moves) go in a NEW commit:
  `chore(docs): archive {item-id}`. This is non-negotiable — amending a
  pushed commit and force-pushing violates safety rules and can destroy
  parallel session work.
- **NEVER force-push.** If the branch has already been pushed, create a new
  commit and push normally. If the push fails, report the error.
- **Stage only archive-related changes** — status field updates in frontmatter
  (discovery, backlog, topic files), file moves to `docs/archive/`, and
  `current_work.md` updates. Do not re-stage delivery artifacts.

---

## Routing

After `/done`:
- Work is complete — start new discovery or pick from backlog
- If issues found later: Create new discovery, reference archived work
