---
type: discover
concept: execution
enhancement: worker-based-repo-execution
status: completed
created: 2026-02-04
---

# Opportunity Snapshot: Worker-Based Repository Execution

**Created:** 2026-02-04
**Status:** Discovery Complete

---

## 1. Discovery Question

**Original input:** How can genies execute against actual repositories instead of just local CLI context?

**Reframed question:** What capabilities does the Genie Team need to enable genies (especially Crafter) to clone repositories, create branches, make commits, and open PRs as part of their execution flow?

---

## 2. Observed Behaviors / Signals

- **Current limitation:** Genies operate on local filesystem context provided by Claude Code
- **No persistence:** Changes made during genie execution don't persist unless user manually commits
- **Context isolation:** Each genie invocation starts fresh without repo history awareness
- **Output as artifacts:** Crafter produces code as markdown artifacts, not actual file changes

---

## 3. Pain Points / Friction Areas

- **Manual code transfer:** User must copy code from Crafter output into actual files
- **No branching strategy:** Genies can't create feature branches for isolation
- **No PR creation:** User must manually create PR after copying code
- **Lost commit history:** No genie attribution in git history
- **No test execution against real repo:** Crafter can't verify code compiles/passes tests

---

## 4. Telemetry Patterns

> No telemetry available — genie-team is CLI-based

- **Estimated friction:** 5-10 minutes per feature for manual code transfer
- **Error rate:** Unknown — manual transfer introduces copy/paste errors

---

## 5. JTBD / User Moments

**Primary Job:**
"When Crafter finishes implementing a feature, I want the code automatically committed to a feature branch so I can review and merge without manual file operations."

**Related Jobs:**
- "When starting implementation, I want a clean feature branch so changes are isolated"
- "When implementation is complete, I want a PR created so I can run CI and review"
- "When I approve a PR, I want the merge to happen automatically"

**Key Moments:**
- Crafter generates 20+ lines of code across multiple files
- User needs to track which files changed
- User wants to see diff before committing

---

## 6. Assumptions & Evidence

### Assumption 1: Git operations from genies are safe
- **Type:** feasibility
- **What we believe:** Genies can safely create branches, commit, and push without breaking main
- **Evidence for:** Feature branch workflow isolates changes; PRs provide review gate
- **Evidence against:** Runaway commits could spam repository
- **Confidence:** high (standard git workflow)
- **Test idea:** Spike: Crafter creates branch, commits, pushes to test repo

### Assumption 2: Repo context improves code quality
- **Type:** value
- **What we believe:** Genies with access to full repo produce better code than artifact-only
- **Evidence for:** Crafter with `read_file` tool (P1-genie-tool-use) already improves quality
- **Evidence against:** Context window limits may still constrain understanding
- **Confidence:** high
- **Test idea:** Compare Crafter output: artifact-only vs. repo-aware

### Assumption 3: Worker isolation is achievable
- **Type:** feasibility
- **What we believe:** Multiple concurrent genie executions can be isolated without cross-contamination
- **Evidence for:** Container/VM isolation is standard practice
- **Evidence against:** Shared filesystem requires careful management
- **Confidence:** high
- **Test idea:** Run two concurrent Crafters on different products, verify isolation

---

## 7. Technical / Architectural Signals

- **Feasibility:** moderate — established patterns exist
- **Constraints:** Requires execution environment outside CLI (worker process)
- **Dependencies:** Git credentials management; workspace isolation
- **Architecture fit:** Extends existing tool execution model
- **Risks:** Credential security; runaway git operations
- **Needs Architect spike:** yes — for workspace management and git credential flow

---

## 8. Opportunity Areas (Unshaped)

- **Opportunity 1: Repo-aware Crafter** — Crafter can read existing code, write new code, commit to branch
- **Opportunity 2: Branch management** — Automatic feature branch creation and cleanup
- **Opportunity 3: PR integration** — Genies can create PRs with design docs as description
- **Opportunity 4: Test execution** — Critic can run actual tests, not just review code

---

## 9. Evidence Gaps

- **Missing data:** Performance impact of full repo clone vs. sparse checkout
- **Unanswered questions:** Optimal branch naming convention for genie branches
- **Research needed:** Credential management patterns for multi-repo access

---

## 10. Recommended Next Steps

- [ ] Spike: Git operations from genie execution context
- [ ] Define workspace lifecycle (create, execute, cleanup)
- [ ] Research sparse checkout for large repositories
- [ ] Design branch naming: `genie/{workflow_id}-{phase}` or similar
- [ ] Evaluate GitHub App vs. PAT for authentication

---

## 11. Routing Recommendation

**Recommended route:**
- [x] **Ready for Shaper** - Problem understood, ready to shape

**Rationale:** The capability is well-defined and builds on existing tool use patterns. Ready to shape into concrete deliverables.

---

## 12. Artifacts Created

- **Snapshot saved to:** `docs/analysis/20260204_discover_worker_based_execution.md`
- **Backlog item created:** yes
  - `docs/backlog/crafter/P1-repo-aware-execution.md`

---

## 13. Notes for Future Discovery

- **Monorepo support:** How to handle large monorepos with sparse checkout?
- **Submodule handling:** Should genies operate on submodules?
- **Force push protection:** Prevent destructive git operations

---

# End of Opportunity Snapshot
