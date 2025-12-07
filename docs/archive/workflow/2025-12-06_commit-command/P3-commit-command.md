---
type: shaped-work
concept: workflow
enhancement: commit-command
status: done
created: 2025-12-06
---

# Shaped Work Contract — /commit Command

---

## 1. Problem / Opportunity Statement

**Original input:** "the best way to direct claude to commit clean, concise, commitlint style commits"

**Reframed problem:** Genie Team workflow has no structured git commit handling. After `/discern` approves work, commits happen ad-hoc without guidance, resulting in inconsistent commit messages that don't leverage the rich context already captured in backlog items.

---

## 2. Evidence & Insights

- **From Discovery:** `docs/analysis/20251206_discover_commit_conventions.md`
- **Behavioral Signals:**
  - Current workflow stops at "Ready for deployment" — no commit step
  - Claude Code won't commit proactively (requires explicit request)
  - Claude Code uses hardcoded footer that adds noise
- **JTBD:** "When I've finished implementing a feature, I want to commit with a clean conventional message so that git history is readable and changelog-ready."

---

## 3. Strategic Alignment

- **North-star Alignment:** Completes the "/d" lifecycle with explicit commit step
- **Quarterly Priorities:** Workflow polish and completeness
- **Product Pillars:** Developer experience, structured workflows
- **Persona / Segment:** Genie Team users who want clean git history
- **Opportunity Cost:** Minimal — small batch work

---

## 4. Appetite (Scope Box)

- **Appetite:** Small (1-2 hours)
- **Boundaries:**
  - Create `commands/commit.md` command file
  - Define conventional commit message template
  - Integrate with backlog item context
- **No-Gos:**
  - No automatic commits (explicit only)
  - No PR creation (separate concern)
  - No branch management
  - No multi-commit orchestration
- **Fixed Elements:**
  - Must use Claude Code's HEREDOC format
  - Must produce commitlint-compatible messages

---

## 5. Goals (Hybrid Format)

### Outcome Hypothesis
"We believe that providing a `/commit` command will result in consistent, conventional commit messages for Genie Team users."

### Success Signals
- Commits follow `type(scope): description` format
- Commit messages reference the work done (not just "fix bug")
- Users invoke `/commit` after `/discern` approval

### JTBD
"When my implementation is approved by `/discern`, I want to run `/commit` so that my changes are committed with a clean, conventional message that references what was built."

---

## 6. Opportunities & Constraints

### Opportunities
- Leverage backlog item context for rich commit messages
- Standardize commit format across all Genie Team work
- Enable future changelog automation

### Constraints
- **Technical:** Must work with Claude Code's git handling
- **User:** Explicit invocation only (no auto-commit)
- **Appetite:** Command file only — no complex logic

### Risks
- **Value Risk:** Low — users explicitly requested this
- **Usability Risk:** Low — simple command pattern
- **Feasibility Risk:** Low — straightforward implementation
- **Viability Risk:** Low — aligns with workflow

---

## 7. Riskiest Assumptions

### Primary Riskiest Assumption
- **Type:** usability
- **Assumption:** Users will remember to run `/commit` after `/discern`
- **Fastest Test:** Use it in practice; add reminder to `/discern` output
- **Invalidation Signal:** Users forget and commit manually with poor messages

---

## 8. Dependencies

### Minor Dependencies
- None

### Major Dependencies (Hard Stop)
- None

---

## 9. Open Questions

- **For Navigator:**
  - Should we include Claude's co-author footer? (Current default: yes)
  - Preferred commit types beyond standard (feat, fix, docs, etc.)?

---

## 10. Recommendation (Options + Ranked)

### Option 1: Minimal /commit Command
- **Description:** Simple command that prompts for conventional commit with backlog context
- **Pros:** Fast to implement, focused, aligns with small appetite
- **Cons:** No automation, manual type selection
- **Appetite fit:** fits

### Option 2: Smart /commit with Auto-Detection
- **Description:** Command reads backlog item and suggests commit type/scope automatically
- **Pros:** Less manual work, smarter messages
- **Cons:** More complex, may guess wrong
- **Appetite fit:** tight

### Ranked Recommendation
- **Top Recommendation:** Option 1 (Minimal)
- **Reasoning:** Small batch appetite; get it working first, enhance later

---

## 11. Routing Target

**Recommended route:**
- [x] **Crafter** - Ready for implementation

**Rationale:** Small batch, clear spec, no architectural decisions needed. Just create the command file following existing patterns.

---

## 12. Acceptance Criteria

1. `commands/commit.md` exists and follows command pattern
2. Command produces commitlint-compatible format: `type(scope): description`
3. Command reads current backlog item for context (if available)
4. Command uses HEREDOC format for multi-line messages
5. Command includes standard types: feat, fix, docs, refactor, test, chore
6. `/genie:help` updated to show `/commit` command
7. Workflow diagram updated: `/discern` → `/commit` → `/done`

---

## 13. Solution Sketch

### Command Structure
```markdown
# /commit [backlog-item]

Create conventional commit for completed work.

## Arguments
- `backlog-item` - Path to backlog item (optional, uses current context)
- `--type` - Commit type (feat|fix|docs|refactor|test|chore)
- `--scope` - Commit scope (optional)
- `--amend` - Amend previous commit

## Behavior
1. Read backlog item (if provided) for context
2. Determine commit type from work done
3. Generate conventional commit message
4. Execute git commit with HEREDOC format

## Message Template
type(scope): concise description

- What was done (from implementation section)
- Why it was done (from problem statement)

Refs: docs/backlog/{item}.md

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

### Workflow Position
```
/discover → /define → /design → /deliver → /discern → /commit → /done
                                              ↓
                                    (after APPROVED)
```

---

## 14. Artifacts

- **Contract saved to:** `docs/backlog/P3-commit-command.md`
- **Discovery referenced:** `docs/analysis/20251206_discover_commit_conventions.md`

---

# Implementation

## What Was Built

### Files Created
- `commands/commit.md` — New command for conventional commits

### Files Modified
- `commands/genie-help.md` — Added `/commit` to command listing, updated to "7 D's", added FINALIZE section
- `commands/discern.md` — Updated routing to mention `/commit` before `/done`
- `templates/CLAUDE.md` — Updated lifecycle diagram to "7 D's" with `/commit → /done` flow
- `install.sh` — Updated lifecycle diagram in CLAUDE.md template

### Files Synced
- `dist/commands/` — All command files synced including new `commit.md`

## Implementation Decisions

1. **Placed in TRANSITIONS section** — `/commit` is a transition step between `/discern` and `/done`, not a genie command
2. **All standard commit types included** — feat, fix, docs, refactor, test, chore, perf, style, build, ci
3. **Breaking change support** — Added `--breaking` flag and `!` notation documentation
4. **Safety rules section** — Explicitly documents Claude Code's git safety conventions
5. **Updated "6 D's" to "7 D's"** — Now includes `/done` as the seventh D in the lifecycle

## Acceptance Criteria Status

- [x] `commands/commit.md` exists and follows command pattern
- [x] Command produces commitlint-compatible format: `type(scope): description`
- [x] Command reads current backlog item for context (if available)
- [x] Command uses HEREDOC format for multi-line messages
- [x] Command includes standard types: feat, fix, docs, refactor, test, chore (plus perf, style, build, ci)
- [x] `/genie:help` updated to show `/commit` command
- [x] Workflow diagram updated: `/discern` → `/commit` → `/done`

---

# Review

## Verdict: APPROVED

### Acceptance Criteria Evaluation

| Criteria | Status | Evidence |
|----------|--------|----------|
| `commands/commit.md` exists and follows command pattern | ✅ Pass | File created with standard sections (Arguments, Genie Invoked, Context Loading, etc.) |
| Produces commitlint-compatible format | ✅ Pass | `type(scope): description` format documented with all standard types |
| Reads backlog item for context | ✅ Pass | Context Loading section specifies reading backlog item; examples show context usage |
| Uses HEREDOC format | ✅ Pass | Notes section confirms HEREDOC usage |
| Includes standard commit types | ✅ Pass | 10 types documented: feat, fix, docs, refactor, test, chore, perf, style, build, ci |
| `/genie:help` updated | ✅ Pass | `/commit [item]` in TRANSITIONS section; FINALIZE flow added |
| Workflow diagram updated | ✅ Pass | `/discern` → `/commit` → `/done` flow in genie-help, templates/CLAUDE.md, install.sh |

**Result: 7/7 criteria met**

### Code Quality Assessment

| Aspect | Rating | Notes |
|--------|--------|-------|
| Pattern adherence | Good | Follows existing command file structure |
| Documentation | Good | Clear examples, usage scenarios, type reference table |
| Consistency | Good | Matches style of other command files |
| Completeness | Good | Covers edge cases (amend, breaking changes, no staged files) |

### Risk Assessment

| Risk | Level | Mitigation |
|------|-------|------------|
| Security | None | No code execution, just documentation |
| Data integrity | None | Git safety rules documented |
| Correctness | Low | Format matches commitlint spec |
| Maintainability | Low | Simple command file, easy to update |

### Minor Observations (non-blocking)

1. **WORKFLOWS section still shows old flow** — `/bugfix` shows `shape → deliver → discern` (should use `define`)
2. **Feature workflow description** — Says "discover → discern" but doesn't mention commit/done

These are cosmetic inconsistencies that can be addressed in a follow-up cleanup.

### Reviewer Notes

- Implementation is clean and well-documented
- Workflow diagrams consistently updated across files
- Safety rules section is a good addition
- Breaking change syntax documented correctly

---

## Routing

**APPROVED** — Ready for `/commit` then `/done`

---

# End of Shaped Work Contract
