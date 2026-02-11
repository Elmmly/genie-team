---
type: discover
topic: "claude-hooks-vs-git-hooks"
concept: quality-enforcement
status: completed
created: 2026-02-11
---

# Opportunity Snapshot: Claude Hooks vs Git Hooks for Quality

**Created:** 2026-02-11
**Status:** Discovery Complete

---

## 1. Discovery Question

**Original:** How we might use Claude hooks for improved deterministic outcomes for quality, spec & architecture alignment, lint, etc. vs what belongs in git hooks.

**Reframed:** Where do Claude hooks produce genuine improvements to software quality, documented knowledge, context management, and token efficiency — and where do they add complexity for marginal gain over the behavioral system (rules + skills) that already exists?

---

## 2. Current State: What's Actually Working

Genie-team enforces quality through two behavioral mechanisms:

- **7 rules files** (`.claude/rules/`) — always loaded into system context. Cover TDD, code quality, autonomous execution, agent conventions, workflow, agent selection, MCP integration.
- **8 skills** (`.claude/skills/`) — auto-activate on keyword/command detection. Cover TDD cycle, code quality, conventional commits, pattern enforcement, problem-first framing, spec-awareness, architecture-awareness, brand-awareness.

These are probabilistic — Claude follows them with high but not perfect compliance. The question is whether hooks can meaningfully close that gap, and at what cost.

---

## 3. Honest Assessment by Dimension

### A. Software Quality (Does the code/implementation get better?)

**Verdict: Hooks offer limited direct value here.**

The quality problems in generated code are judgment problems, not structural ones:
- Did Claude choose the right abstraction?
- Are the tests testing the right things?
- Is the error handling appropriate for the context?
- Does the code match the architectural intent?

These require LLM reasoning. A shell script can't evaluate them. You could use prompt/agent hooks to add a second LLM pass, but:
- That doubles the token cost for every tool call it matches
- The second LLM has the same blindspots as the first
- It adds 30-60 seconds of latency per check

**One genuine exception: auto-formatting.** A PostToolUse hook on Write/Edit that runs `prettier`/`black`/`gofmt` on code files is deterministic, fast, and saves tokens because Claude doesn't need to worry about formatting. But this belongs in **target projects** (each has its own language/formatter), not in genie-team itself.

**For genie-team specifically:** The primary artifacts are markdown prompt definitions. There's no code to lint. Markdownlint could enforce heading structure, but it can't tell you whether a prompt is well-written.

### B. Documented Knowledge (Do docs/specs/decisions get better?)

**Verdict: Marginal value. The real documentation problems are content problems.**

Hooks could validate:
- Frontmatter has required fields (PostToolUse on Write, parsing YAML)
- Document matches its schema structure (section headings present)
- Cross-references point to files that exist (link validation)

But the documentation quality issues that actually matter are:
- Is the spec's acceptance criteria precise enough to verify?
- Does the ADR capture the real trade-offs or just the chosen option?
- Is the backlog item's problem statement actually a problem, not a solution?
- Does the design address the shaped boundaries?

These are content quality questions that require the same LLM judgment the behavioral system already provides. A frontmatter validator catches a typo; it doesn't catch a bad spec.

**The honest cost/benefit:** A frontmatter validation hook would catch maybe 1-2 missing fields per week. The cost is: a shell script to maintain, `yq` as an environment dependency, latency on every file write to `docs/`, and configuration complexity in `install.sh`. The `/discern` review step already catches these issues. The improvement is marginal.

### C. Context Management (Does Claude maintain better awareness?)

**Verdict: This is where hooks have the most genuine potential.**

The real context management pain points:

1. **Post-compaction context loss.** When Claude Code compacts the conversation, rules survive (they're in the system prompt), but session-specific context disappears — which backlog item you're working on, which spec was loaded, what phase you're in, decisions made earlier in the session. A `SessionStart` hook on `compact` could re-inject a summary of current work state. This is a real problem with a real hook solution.

2. **Spec/ADR loading verification.** The spec-awareness and architecture-awareness skills tell Claude to load relevant specs and ADRs. But after compaction or in long sessions, Claude may proceed without actually reading them. An agent hook on `Stop` could verify that expected context was loaded — but at the cost of an additional LLM invocation (tokens + latency) at the end of every response.

3. **Context injection at session start.** A `SessionStart` hook could automatically read `docs/context/current_work.md` (or equivalent) and inject it, saving the manual `/context:load` step. This is a convenience improvement — genuinely useful but small.

**The trade-off is real:** The compaction re-injection hook (#1) is the strongest case. It's a command hook (cheap — just reads a file and prints it), fires only on compaction events (rare), and addresses a problem that behavioral rules can't solve (rules can't know what context was lost). This is the one hook use case where the mechanism genuinely fits the problem.

### D. Token Management (Do we use tokens more efficiently?)

**Verdict: Hooks are likely net-negative on token efficiency, with one exception.**

**Hooks cost tokens:**
- Prompt hooks: invoke a separate LLM call (input + output tokens) every time they fire
- Agent hooks: invoke a multi-turn LLM session (potentially 50+ tool calls) every time they fire
- Command hooks: free in tokens but add wall-clock latency

**Hooks that fire frequently are expensive.** A PostToolUse hook on Write fires on *every file write*. In a `/deliver` session, that could be 20-50 writes. Even a command hook adds latency; a prompt hook adds token cost per write.

**The one token-saving case: auto-formatting.** If a PostToolUse command hook runs a formatter on code files, Claude no longer needs to spend tokens getting formatting right. It can write sloppy code and the formatter fixes it. Over a long session this could save meaningful tokens on formatting-related back-and-forth. But again — this is a target project concern, not a genie-team concern.

**For genie-team:** The behavioral system (rules + skills) is already loaded into the system prompt — those tokens are already spent. Adding hooks on top means paying *additional* cost (latency for command hooks, tokens for prompt/agent hooks) for enforcement that the behavioral system mostly handles.

### E. Spec & Architecture Alignment (Does implementation match intent?)

**Verdict: Hooks can't help here. This is inherently a judgment problem.**

Verifying that an implementation aligns with a spec or ADR requires:
- Understanding the spec's intent (not just its text)
- Evaluating whether code satisfies acceptance criteria
- Assessing whether architectural boundaries are respected

This is exactly what `/discern` does — it's an LLM-powered review step. You could move this into an agent hook that fires on `Stop`, but you'd just be replicating `/discern` as a hook with worse UX (no structured review document, no verdict, no routing).

The behavioral approach (spec-awareness skill loads the spec, architecture-awareness skill loads ADRs, critic genie evaluates alignment) is actually the right architecture for this problem. It's judgment all the way down.

---

## 4. What Belongs Where

| Concern | Best Mechanism | Why |
|---------|---------------|-----|
| **Code formatting** | Git hooks (pre-commit) or Claude hooks (PostToolUse) in **target projects** | Deterministic, language-specific, saves tokens on formatting |
| **Commit message format** | Git hooks (commit-msg with commitlint) in **target projects** | Standard tooling exists; works for all committers, not just Claude |
| **Test execution** | Behavioral (TDD skill) + git hooks (pre-push) in **target projects** | TDD skill handles the cycle; git hook is the safety net |
| **Context re-injection after compaction** | Claude hook (SessionStart on `compact`) | Only mechanism that can address post-compaction context loss |
| **Spec/ADR awareness** | Behavioral (skills) | Judgment required; hooks can't evaluate whether context was *understood* |
| **Documentation quality** | Behavioral (skills + `/discern` review) | Content quality requires LLM judgment |
| **Code quality** | Behavioral (rules + skills) | Abstraction choice, error handling, design — all judgment |
| **Protected file blocking** | Claude hook (PreToolUse on Write/Edit) | Genuine deterministic case — but how often does this actually happen? |
| **Linting** | Git hooks (pre-commit) in **target projects** | Language-specific, standard tooling, not genie-team's concern |

---

## 5. The Uncomfortable Conclusion

**Most of what matters for quality requires LLM judgment, and genie-team already has a well-built behavioral system for that.**

The hooks capability is powerful infrastructure, but for genie-team's specific situation:

1. **It's a prompt engineering project.** No code to lint, format, or type-check. The artifacts are markdown files where quality = content quality = judgment.

2. **The behavioral system has high compliance.** Claude Code's rules system is not a suggestion box — it's injected into the system prompt and followed reliably. Skills auto-activate with good precision. The gap between "usually follows" and "always follows" is narrow.

3. **The highest-value hook use cases belong to target projects, not genie-team.** Auto-formatting, linting, test execution, commitlint — these are all language-specific concerns that each target project should configure for itself.

4. **Prompt/agent hooks are expensive.** They add LLM invocations on top of the work already being done. For quality enforcement, you're paying twice for the same type of judgment.

**What's genuinely worth building:**

- **Context re-injection after compaction** (SessionStart hook on `compact`). This solves a real problem that behavioral rules can't address. Low cost (command hook, reads a file), fires rarely (only on compaction), high value (prevents context loss in long sessions).

- **Auto-format hook template for target projects.** Not a genie-team hook, but a recommended hook configuration that `install.sh` can optionally install in target projects. PostToolUse on Write/Edit → run project formatter. Saves tokens, deterministic.

Everything else is either marginal (frontmatter validation catches rare typos), already handled (behavioral system), or mismatched to the mechanism (judgment problems solved with shell scripts).

---

## 6. Assumptions & Evidence

| Assumption | Type | Confidence | Evidence For | Evidence Against |
|------------|------|------------|--------------|------------------|
| Behavioral enforcement has high compliance | Value | High | Claude Code injects rules into system prompt; skills auto-activate reliably; anecdotal experience shows strong adherence | No telemetry; compliance may degrade in very long sessions or after compaction |
| Content quality is the real documentation problem | Value | High | Frontmatter typos are rare; the hard problems are imprecise ACs, shallow analysis, missed trade-offs | Some structural issues do slip through (missing sections, wrong status values) |
| Post-compaction context loss is a real pain point | Usability | High | Compaction drops session-specific context; rules survive but loaded specs/decisions/current-work don't | `/context:load` exists as a manual recovery; unclear how often compaction actually causes problems |
| Auto-formatting saves meaningful tokens | Feasibility | Medium | Formatting corrections appear in many sessions; Claude spends tokens fixing whitespace, indentation, trailing commas | Hard to quantify without token-level analysis; may be noise-level savings |
| Target projects should own their own hooks | Viability | High | Language-specific tooling varies; `.git/hooks/` is project-owned; genie-team installs to `.claude/` | Could provide templates/recommendations without owning the hooks |

---

## 7. Evidence Gaps

- **Behavioral compliance rate.** No data on how often rules/skills are actually followed vs. ignored. This is the key unknown — if compliance is 99%, hooks add little; if it's 80%, hooks matter more.
- **Compaction frequency and impact.** How often does compaction cause real problems in practice? If sessions rarely hit compaction, the hook ROI is low.
- **Token spend on formatting.** How many tokens per session go to formatting corrections that a hook could eliminate?

---

## 8. Routing Recommendation

- [ ] Continue Discovery
- [ ] Ready for Shaper
- [ ] Needs Architect Spike
- [x] **Needs Navigator Decision** — Low overall opportunity; one strong use case, one moderate template case

**Rationale:** The discovery found a narrow opportunity, not a broad one. Two actions worth considering:

1. **Build:** SessionStart hook for post-compaction context re-injection (small, high-value, solves a real gap)
2. **Template:** Recommended Claude hook + git hook configurations for target projects (auto-format, commitlint) — as documentation or optional install, not as genie-team's own enforcement

The rest of the hooks landscape doesn't justify the complexity for genie-team. The behavioral system is the right architecture for judgment-based quality enforcement, and that's where most quality problems live.

---

Next: Navigator decision on whether to proceed with the narrow opportunity or park this.
