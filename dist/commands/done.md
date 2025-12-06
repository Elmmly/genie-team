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

---

## Context Writing

**UPDATE:**
- Discovery frontmatter: `status: active` → `status: completed`
- Backlog frontmatter: `status: reviewed` → `status: done`

**MOVE:**
- Discovery from `docs/analysis/` → `docs/archive/{concept}/YYYY-MM-DD_{enhancement}/`
- Backlog item from `docs/backlog/` → `docs/archive/{concept}/YYYY-MM-DD_{enhancement}/`

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
- docs/analysis/20251205_discover_agents.md → docs/archive/agents/2025-12-05_complement-commands/
- docs/backlog/P2-agents-complement-commands.md → docs/archive/agents/2025-12-05_complement-commands/

**Status:** 2 artifacts marked completed and archived.
**Archive location:** docs/archive/agents/2025-12-05_complement-commands/
```

---

## Archive Structure

```
docs/archive/
├── {concept}/
│   └── YYYY-MM-DD_{enhancement}/
│       ├── YYYYMMDD_discover_{topic}.md      # Discovery (from docs/analysis/)
│       └── {priority}-{topic}.md              # Backlog item (from docs/backlog/)
```

This structure:
- Groups by concept (feature/capability category)
- Sorts chronologically within concept
- Shows how concepts evolve over time
- **Only 2 files per completed feature** (discovery + backlog item with design/impl/review)

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

## Error Handling

| Scenario | Behavior |
|----------|----------|
| No artifacts found | "No active artifacts found for {concept}" |
| Missing frontmatter | "Skipping {file}: no frontmatter found" |
| Already completed | "Already archived: {file}" |
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

## Notes

- Only processes artifacts with valid frontmatter
- Archives both discovery file AND backlog item together
- Backlog item contains shaped contract + design + implementation + review (living document)
- Creates archive directory structure if it doesn't exist
- Preserves original filenames in archive
- Fully reversible: move files back and update status

---

## Routing

After `/done`:
- Work is complete — start new discovery or pick from backlog
- If issues found later: Create new discovery, reference archived work
