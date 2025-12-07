---
type: discover
concept: workflow
enhancement: commit-command
status: completed
created: 2025-12-06
---

# Opportunity Snapshot — Scout Genie

---

## 1. Discovery Question

**Original input:** "the best way to direct claude to commit clean, concise, commitlint style commits and the best way to implement it. Either as a commit in our lifecycle (maybe /deliver or /done) or create a /commit command"

**Reframed question:** How should Genie Team integrate structured, conventional commit messages into the workflow, and where in the lifecycle does this responsibility belong?

---

## 2. Observed Behaviors / Signals

- Current Genie Team workflow stops at "Ready for deployment" after `/discern APPROVED`
- `/done` archives artifacts but does not create git commits
- `/deliver` implements code but does not commit changes
- Claude Code has built-in commit behavior with a hardcoded footer: `🤖 Generated with [Claude Code]... Co-Authored-By: Claude`
- Claude Code requires explicit user request to commit (won't commit proactively)
- No existing Genie Team command handles git operations

---

## 3. Pain Points / Friction Areas

- **Gap in workflow:** Implementation happens but commits are manual/ad-hoc
- **Inconsistent messages:** Without guidance, commit messages vary in quality and format
- **Context loss:** Claude Code doesn't know about the shaped work contract, design decisions, or acceptance criteria when crafting commits
- **Footer bloat:** Claude's default footer adds 2+ lines to every commit
- **No changelog integration:** Conventional commits enable automated changelogs, but this requires consistent format

---

## 4. Telemetry Patterns

> N/A - No telemetry data available for this discovery

---

## 5. JTBD / User Moments

**Primary Job:**
"When I've finished implementing a feature with `/deliver`, I want to commit changes with a clean, conventional message so that the git history is readable and changelog-ready."

**Related Jobs:**
- When reviewing history, I want to quickly understand what each commit does
- When generating changelogs, I want automated tooling to work
- When bisecting bugs, I want atomic, well-described commits

**Key Moments:**
- After `/deliver` completes implementation
- After `/discern` approves the work
- Before `/done` archives the artifacts

---

## 6. Assumptions & Evidence

### Assumption 1: Commit belongs after /discern (not /deliver)

- **Type:** usability
- **What we believe:** Commits should happen after review approval, not immediately after implementation
- **Evidence for:** Standard workflow is implement → review → commit → merge; prevents committing broken code
- **Evidence against:** Some teams prefer WIP commits during implementation
- **Confidence:** high
- **Test idea:** Ask users when they typically commit

### Assumption 2: Conventional commits format is desired

- **Type:** value
- **What we believe:** Users want commitlint-compatible conventional commits (`type(scope): description`)
- **Evidence for:** User explicitly mentioned "commitlint style commits"; industry standard for automated changelogs
- **Evidence against:** Some projects use different conventions (GitHub-style, Jira-prefixed)
- **Confidence:** high
- **Test idea:** Check if project has commitlint config

### Assumption 3: A dedicated /commit command is better than embedding in /done

- **Type:** usability
- **What we believe:** Separate command gives more control than auto-committing in /done
- **Evidence for:** Explicit > implicit; users may want to review before committing; aligns with Claude Code's "no proactive commits" principle
- **Evidence against:** Additional step in workflow; /done could be more seamless
- **Confidence:** medium
- **Test idea:** Prototype both approaches

### Assumption 4: Commit message should reference the backlog item

- **Type:** feasibility
- **What we believe:** Commit can pull context from backlog item (problem frame, acceptance criteria) for richer messages
- **Evidence for:** Backlog item contains all context; creates document trail linkage
- **Evidence against:** May be over-engineering; simple description might suffice
- **Confidence:** medium
- **Test idea:** Compare messages with/without backlog context

---

## 7. Technical / Architectural Signals

- **Feasibility:** straightforward
- **Constraints:**
  - Must work with Claude Code's built-in git handling (HEREDOC format)
  - Should respect Claude Code's "only commit when asked" principle
  - Must not conflict with project's existing git hooks
- **Dependencies:** None - git is always available
- **Architecture fit:** Natural extension of command pattern; similar to other lifecycle commands
- **Risks:**
  - Conflicting with commitlint pre-commit hooks (double validation)
  - Footer format preferences vary by team
- **Needs Architect spike:** no

---

## 8. Opportunity Areas (Unshaped)

- **Opportunity 1:** Create `/commit` command that reads backlog context and generates conventional commit message
- **Opportunity 2:** Extend `/done` to optionally commit before archiving
- **Opportunity 3:** Integrate commit into `/deliver` with `--commit` flag
- **Opportunity 4:** Create `.claude/commands/commit.md` template for Claude Code's native commit handling

---

## 9. Evidence Gaps

- **Missing data:** How other Genie Team users handle commits currently
- **Unanswered questions:**
  - Should the command handle multiple commits (atomic per file) or single squash commit?
  - Should it generate commit body from acceptance criteria?
  - How to handle the Claude Code footer preference?
- **Research needed:** Survey of conventional commit tooling ecosystem

---

## 10. Recommended Next Steps

- [ ] Decide: Standalone `/commit` vs integrated in `/done` vs `/deliver --commit`
- [ ] Define: Commit message template structure (type, scope, description, body, footer)
- [ ] Decide: Whether to suppress/customize Claude Code's default footer
- [ ] Prototype: Basic `/commit` command that reads backlog and generates message

---

## 11. Routing Recommendation

**Recommended route:**
- [x] **Ready for Shaper** - Problem understood, ready to define appetite and constraints

**Rationale:** The problem space is well understood. Conventional commits format is clear. The main decisions are about workflow placement and message template design - these are shaping decisions, not discovery questions.

---

## Navigator Decisions

**Decision 1:** Use standalone `/commit` command (explicit, not embedded in `/done` or `/deliver`)
- Aligns with Claude Code's "no proactive commits" principle
- Gives user explicit control over when commits happen
- Cleaner separation of concerns

**Decision 2:** `/define` explicitly replaces `/shape` in the lifecycle
- Aligns "/d" commands: `/discover` → `/define` → `/design` → `/deliver` → `/discern` → `/done`
- Already implemented in codebase

---

## 12. Artifacts Created

- **Snapshot saved to:** `docs/analysis/20251206_discover_commit_conventions.md`
- **Backlog item created:** no (pending shaping)

---

## 13. Notes for Future Discovery

- Could explore: automatic PR creation workflow (after commit)
- Could explore: integration with changelog generation tools
- Could explore: branch naming conventions command

---

# End of Opportunity Snapshot
