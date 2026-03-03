---
type: discover
topic: autonomous-discovery-and-maintenance-loops
reasoning_mode: deep
status: active
created: 2026-02-27
---

# Opportunity Snapshot: Autonomous Discovery and Maintenance Loops

## 1. Discovery Question

**Original:** How might the daemon overseer be extended (or composed with) to continuously scout for new opportunities, shape them into backlog items, run diagnostics, and trigger tidying across managed projects?

**Reframed:** What problem does autonomous discovery solve, and what is the operator's job-to-be-done when they walk away from three managed projects and expect the system to continuously find, evaluate, and fix problems without intervention?

---

## 2. Context Summary

The daemon overseer (`genies daemon`) was just completed (P1-continuous-overseer, archived 2026-02-27) and solves the "continuous delivery loop" problem: scan backlog → run existing work through design/deliver/discern → sleep → repeat. It handles review cycle retries and graceful shutdown.

However, the daemon only processes **existing backlog items**. It cannot:
- Find new problems that haven't been shaped into backlog items yet
- Detect emerging code quality issues and trigger cleanup
- Run diagnostic scans and populate cleanup reports for `/tidy`

The three projects the operator manages (genie-team, 2hearted, motiviate) accumulate problems over time:
- New feature opportunities discovered via user feedback or code exploration
- Dead code, unused dependencies, pattern violations discovered only via audit
- Technical debt that grows between maintenance cycles

**Current workflow:** Operator must manually run `/discover` with topics, `/define` the backlog items, then let the daemon handle design→delivery. This is not "walk away and it works" — it's "walk away once I've pre-shaped the backlog."

The gap: **There is no continuous discovery or maintenance trigger mechanism.** The daemon runs the backlog. But who continuously refills the backlog? Who continuously scans for decay?

---

## 3. Observed Behaviors / Signals

### A. Daemon Capabilities (from P1-continuous-overseer)

The daemon (`run_daemon` in scripts/genies):
- Loops every `--interval` seconds (default 300s = 5m)
- Each cycle: scan backlog with `resolve_batch_items()` → filter by status → run batch
- Maps status to next phase: `defined/shaped` → design, `designed` → deliver, `implemented` → discern
- Runs across multiple projects with `--projects` flag
- Tracks completed/failed/in-progress items in status JSON
- Handles SIGTERM gracefully
- Has `run_finisher()` pass to recover stalled branches

### B. What the Daemon Doesn't Do

1. **No discovery trigger.** The daemon calls `resolve_batch_items()`, which:
   - Scans `docs/backlog/*.md` for items with actionable statuses
   - Filters by `--priority` if provided
   - Can load topics from `--topics-file` and start those items from `discover` phase
   - But `--topics-file` must be pre-populated by the operator
   - No mechanism to *generate* topics continuously

2. **No diagnostics trigger.** The daemon doesn't call `/diagnose`. It doesn't:
   - Scan for code health issues
   - Detect pattern violations or dead code
   - Generate cleanup reports that `/tidy` consumes

3. **No maintenance loop.** There's no outer orchestration:
   - Discover → Define → [wait for daemon] → Design/Deliver/Discern → Done
   - Then: Diagnose → [wait for operator] → Tidy → Commit
   - These are separate, manual workflows

### C. Evidence from Field Tests (2026-02-13 autonomous execution)

From the memory log:
- **Context freshness matters:** Scout's exploration is 15x faster when `current_work.md` is fresh vs. cold start (3 reads vs. 46)
- **Preflight validation prevents wasted tokens:** Checking toolchain before starting saves tokens on failed runs
- **Per-phase cost tracking is missing:** No way to understand which phase (discover? define?) consumes the most cost, so budget allocation is opaque
- **Build artifacts leaked:** Untracked files from previous run corrupted state — autonomous cycles need aggressive cleanup
- **Critic calibration helps:** After tuning, critic had zero false positives, meaning agent memory works across cycles

This suggests: **Autonomous discovery is expensive and needs instrumentation** (cost per topic, cost per diagnostic scan) to be economically viable.

### D. Cross-Item Obligations (Newly Designed)

The just-completed P2-deferred-obligation-tracking spec adds constraints:
- When work defers a step to another item, it must populate `deferred_to` in the source item's frontmatter
- The destination item must have a corresponding AC
- `/done` must scan for unresolved inbound obligations before archival

This is relevant to autonomous discovery: **If discovery generates topics that create backlog items, those items might defer work to other items.** The obligation tracking system needs to be aware of daemon-generated items.

### E. Cross-Project Scope (Daemon Already Supports)

The daemon already accepts `--projects /path/1 /path/2 /path/3` and cycles through each:
- Scans each project's backlog independently
- Runs batches in each project
- Accumulates results in the status JSON

This means: **Multi-project discovery is architecturally possible.** The daemon can loop across projects. The missing piece is: what tells it to discover in each project?

---

## 4. Pain Points / Friction Areas

### P1: Discovery Topics Are Manually Pre-Populated

**Friction:** `/discover` requires a topic (a question or area to explore). There's no source of truth for "what should we discover next?"

Currently:
- Operator runs `/discover "authentication patterns in 2hearted"`
- Or `/discover --workshop` for interactive multi-phase discovery
- Or provides `--topics-file` to batch discovery across multiple topics
- But: No system generates the topics automatically

**Workaround:** Operator maintains a mental list or external note of areas to explore. Or waits for bugs/feedback to surface problems.

**Impact:** The operator is the bottleneck for discovery. Even with a 24/7 daemon, it's only as good as the backlog the operator feeds it.

### P2: Diagnostics and Cleanup Are Decoupled from Continuous Cycles

**Friction:** `/diagnose` and `/tidy` are separate commands that must be invoked manually:

```bash
# Manual workflow
/diagnose full
/tidy docs/cleanup/20260227_diagnose_full.md
```

Currently:
- No automatic trigger for diagnostics
- No scheduled cleanup batches
- No integration between daemon cycles and maintenance cycles
- Cleanup reports accumulate but aren't processed

**Workaround:** Operator runs diagnostics during off-hours, reviews report, manually schedules tidying for the next cycle.

**Impact:** Code quality degrades between manual maintenance runs. Dead code and technical debt accumulate faster than they're cleaned.

### P3: No Continuous Cost Visibility

**Friction:** The operator can't tell if autonomous discovery is economically viable without running it end-to-end and comparing bills.

Currently:
- Daemon tracks cumulative cost in status JSON
- But no breakdown: "discovery cost $X, define cost $Y, design cost $Z per cycle"
- No early warning if discovery topics are expensive
- No budget allocation mechanism per genie phase

**Impact:** Autonomous discovery could exceed budget without visibility until the cycle completes.

### P4: Topic Quality and Relevance Unknown

**Friction:** If topics are auto-generated, how do we know they're relevant? How do we avoid low-value, high-cost discovery?

Currently:
- No feedback mechanism to score topics (was this discovery valuable?)
- No learning system to adjust topic generation strategy based on results
- No way to prioritize high-impact areas of the codebase

**Impact:** Autonomous discovery could run many cycles on low-value topics, wasting budget and generating low-quality backlog items.

### P5: Multi-Project Orchestration Has No Prioritization

**Friction:** The daemon scans all projects in order. If one project has 10 items and another has 1, the daemon may spend all budget on the first.

Currently:
- `--priority` flag filters by P1/P2/P3 but applies to all projects uniformly
- No way to say "prioritize discovery in project A, maintenance in project B"
- No cross-project work prioritization

**Impact:** Operator can't steer the daemon toward the most critical work across a portfolio.

---

## 5. JTBD / User Moments

### Primary Job

**When** the operator has shaped the initial backlog and is ready to delegate ongoing discovery and maintenance to automation,
**the operator** wants the system to continuously find new opportunities, diagnose code quality issues, and fix them without requiring manual intervention per project,
**so they can** walk away knowing that all three managed projects are improving continuously, even if new problems emerge or code decays while they're busy elsewhere.

### Secondary Jobs

1. **Budget awareness job:** "When I'm concerned about the cost of autonomous discovery, I want to see per-genie-phase cost breakdowns, so I can adjust budget limits or topic strategies."

2. **Topic relevance job:** "When an autonomous discovery run completes, I want to quickly see whether the discovered topics were valuable (led to shaped work), so I can adjust the discovery strategy."

3. **Multi-project steering job:** "When managing 3 projects with different needs, I want to assign discovery budgets and priorities per project, so I can focus depth where it matters most."

4. **Maintenance synchronization job:** "When code is deployed to production, I want automated diagnostics to run and stale code to be cleaned up, so technical debt doesn't accumulate."

---

## 6. Assumptions & Evidence

| Assumption | Type | Confidence | Evidence For | Evidence Against | Priority |
|-----------|------|-----------|--------------|------------------|----------|
| Autonomous discovery is more cost-effective than manual discovery | viability | medium | 1-2 discovery topics per week × $50/topic = $100-200 human cost. Autonomous discovery could reduce this by batching topics. But: auto-generated topics might be low quality (see P4). | Field test shows per-topic cost is ~$5-15 depending on scope. If 80% of auto-topics are low-value, cost explodes. | High |
| The operator wants continuous discovery, not just continuous delivery | value | medium | Problem statement says "walk away and it ships." But does "it" include discovering new work, or just delivering pre-planned work? The daemon solves the latter, not the former. | No user feedback on discovery frequency. The operator might be satisfied with weekly manual discovery + daily automated delivery. | High |
| Code diagnostics should run continuously, not on-demand | value | low | Maintenance cycles were previously manual. No evidence that daily diagnostics is better than weekly manual checks. | The `check-crossrefs.sh` pre-commit hook already catches some issues. Daily diagnostics might be noise. | Medium |
| Multi-project orchestration will be a differentiator | viability | low | The daemon already supports `--projects` flag. No evidence that cross-project prioritization is the blocker — it might be enough to just run all projects on the same schedule. | The operator manages 3 projects, but they're independent (genie-team, 2hearted, motiviate). No shared backlog or dependencies observed. | Low |
| Topic generation can be automated without degrading quality | feasibility | low | No existing implementation. Possible approaches: (1) static topic list, (2) code health analysis triggers discovery, (3) LLM-based opportunity scanning. All are complex. | ADR-001 says "thin orchestrator" — the daemon doesn't think, it just runs work. Adding topic generation requires a "discovery generator" genie, which is new scope. | High |
| Per-genie cost tracking is necessary for autonomous execution | viability | medium | The 2026-02-13 field test shows cost varies by phase (Opus 87%, Sonnet 10%, Haiku 3%). But: no breakdown by genie. Is discovery expensive? Or define? | Daemon status JSON tracks cumulative cost. No existing per-phase cost breakdown. Would require parsing claude JSON output per phase and accumulating. | Medium |

---

## 7. Technical Signals

### Feasibility Assessment

The daemon architecture supports autonomous discovery IF we add:

1. **Topic generation mechanism** (new)
   - Status: Unknown feasibility
   - Options:
     a. Static topics file (simplest, manual maintenance)
     b. Code analysis triggers discovery (e.g., "if dead code detected, discover refactoring opportunities")
     c. LLM-based opportunity scanning (most powerful, most expensive)
   - Constraint: ADR-001 says "thin orchestrator" — the daemon doesn't contain business logic. Topic generation might live in an external system, or as a structured list

2. **Diagnostic trigger integration** (moderate feasibility)
   - Status: Mostly straightforward
   - Design: After each daemon cycle, optionally run `/diagnose` on each project
   - Implementation: Add `--auto-diagnose` flag to daemon, which triggers `run_diagnose_cycle()` after batch execution
   - Constraint: `/diagnose` output format (currently goes to `docs/cleanup/`) needs to be structured for daemon consumption

3. **Maintenance cycle execution** (straightforward)
   - Status: Daemon already supports `/tidy` phase via `--through tidy`
   - But: No automatic trigger for tidy based on diagnose output
   - Design: Add logic to detect fresh diagnose reports and auto-schedule `/tidy` phases
   - Constraint: Must not run `/tidy` on code that's currently being delivered (race condition)

4. **Per-genie cost tracking** (straightforward)
   - Status: Parsing exists; aggregation missing
   - Design: Parse `total_cost_usd` from each phase's claude JSON output, accumulate per phase
   - Implementation: Update `run_phase()` to extract and log cost, update status JSON with per-phase cost breakdown

5. **Topic quality feedback** (moderate feasibility)
   - Status: No existing mechanism
   - Design: After `/define` completes a topic, log outcome (shaped → accepted / rejected / deferred)
   - Implementation: Requires post-phase analysis of backlog changes
   - Constraint: Can't be fully automated — relies on operator to mark topics as "valuable" or "waste"

### Architecture Constraints (from ADR-001)

**ADR-001: Thin Orchestrator**

The decision to use a "thin orchestrator" means:
- External systems (or the daemon) spawn `claude -p` processes, not import a genie-core library
- The daemon IS the orchestrator — it's in bash, it spawns CLI processes
- No shared state between daemon and CLI (must parse stdout/JSON)

**Implication for discovery:** If topic generation lives in the daemon, it must be bash logic or shell scripts. LLM-based opportunity generation would require either:
1. Spawning a separate `claude -p "/discover auto-generate-topics"` call (adds latency + cost)
2. Accepting that the daemon can't do intelligent topic generation, and topics must come from external sources

### Needs Architect Spike: YES

**Question for Architect:** What is the minimal topic generation mechanism that (a) fits the thin orchestrator pattern, (b) is economically viable, and (c) produces higher-quality topics than random sampling?

Options to evaluate:
- Static daily/weekly topics rotated by daemon
- Code health analysis (dead code detection) triggers discovery
- LLM-based "scan this project for opportunities" one-shot per day
- Human-curated topic queue that daemon pulls from

---

## 8. Opportunity Areas (Unshaped)

### OA1: Autonomous Topic Generation from Code Signals

**Problem:** The daemon can't discover new opportunities because there's no source of topics to explore.

**Territory:**
- Code health analysis could trigger discovery: "If dead code detected, discover refactoring opportunities for this module"
- Git history patterns could trigger discovery: "If commits are concentrated in one file, discover architectural refactoring"
- Dependency analysis could trigger discovery: "If critical dependency is outdated, discover upgrade path"
- Each signal is a potential topic, but which signals matter?

**Evidence:**
- The `/diagnose` command already identifies code health issues
- Dead code, pattern violations, and dependency issues exist in all codebases
- No evidence yet that these signals should automatically trigger discovery (vs. manual triage)

**Counter-evidence:**
- Not all code health issues warrant discovery + shaping + delivery (e.g., a minor style violation might not be worth 3 days of work)
- Automating discovery based on code analysis could generate low-value topics, wasting budget

### OA2: Integrated Diagnosis → Cleanup Cycle

**Problem:** Diagnostics and cleanup are decoupled. Reports accumulate but aren't automatically prioritized and executed.

**Territory:**
- After a daemon cycle completes, automatically run `/diagnose` on each project
- Scan for fresh diagnose reports, prioritize by severity
- Auto-schedule `/tidy` phases for high-priority cleanups
- But: How to prevent race conditions (deliver is running, clean is scheduled)?
- How to handle `/tidy` that needs user decision (which batch to execute)?

**Evidence:**
- The 2026-02-13 field test showed code quality issues were not caught until manual inspection
- P3-discovery-workshop mentioned code decay as a real concern
- Cross-item obligations (P2-deferred-obligation-tracking) show work can be silently lost — cleanup could prevent this

**Counter-evidence:**
- `/tidy` is designed as a human-guided process (Tidier executes batches, operator decides)
- Fully automated tidying could introduce bugs (refactoring is risky)
- No evidence that daily cleaning is better than weekly manual reviews

### OA3: Cost-Aware Discovery Budgeting

**Problem:** Autonomous discovery has no cost visibility, so the operator can't tell if it's economical or adjust budgets per project/genie phase.

**Territory:**
- Track per-genie cost: discover cost, define cost, design cost, deliver cost, discern cost
- Expose cost per topic, cost per project, cost per cycle
- Implement budget allocation: "spend max $5 on discovery per day, max $20 on delivery"
- Alert when approaching budget limit
- But: How to allocate budget across competing topics?
- How to handle budget overrun gracefully (pause discovery? reduce parallel jobs?)?

**Evidence:**
- The 2026-02-13 field test tracked cost and showed phase distribution (Opus 87%, Sonnet 10%, Haiku 3%)
- Daemon status JSON already accumulates `cumulative_cost_usd`
- No per-phase cost breakdown exists, making budget allocation impossible

**Counter-evidence:**
- Budget tracking adds complexity. The operator might be satisfied with total cost tracking
- Automating budget allocation requires machine learning or heuristics — not guaranteed to make good decisions

### OA4: Topic Relevance Feedback Loop

**Problem:** If topics are auto-generated, there's no way to measure whether discovery was valuable or wasteful.

**Territory:**
- After a discovery topic completes (shaped or rejected), log outcome: "topic_outcome: shaped" vs. "rejected"
- Track which topics led to approved work, which were abandoned
- Use outcomes to tune topic generation strategy
- But: How to classify outcomes (was a shaped-but-not-delivered topic a success or failure?)?
- How to close the feedback loop (who tunes the strategy)?

**Evidence:**
- The operator wants to "walk away" — implies they want feedback to learn if it's working
- No existing measurement of discovery quality
- Word-of-mouth feedback is the only signal (e.g., "that discovery was a waste of money")

**Counter-evidence:**
- Humans are bad at evaluating opportunity cost ("I don't know what I would have discovered instead")
- Topic relevance is subjective and context-dependent
- Automated feedback might be noise

### OA5: Multi-Project Discovery Prioritization

**Problem:** The daemon scans all projects uniformly. If one project needs discovery and another needs cleanup, there's no way to steer effort.

**Territory:**
- Operator assigns discovery/maintenance budgets per project: "genie-team: $50/day discovery, 2hearted: $20/day cleanup, motiviate: $10/day design"
- Daemon prioritizes work across projects based on budgets
- But: How to handle multi-day items that cross project boundaries?
- How to handle discovery that spans multiple projects (e.g., "discover reusable patterns across projects")?

**Evidence:**
- The operator manages 3 independent projects
- Daemon already supports `--projects` flag
- No evidence of cross-project dependencies (each project seems independent)

**Counter-evidence:**
- Three independent projects might not need sophisticated multi-project orchestration
- The daemon could just loop through each project on the same schedule
- Project-specific priorities might be over-engineering

---

## 9. Evidence Gaps

### Critical Gaps

1. **No evidence of operator preference for autonomous discovery vs. manual discovery**
   - How often does the operator want discovery to run? (daily? weekly? monthly?)
   - What would make autonomous discovery valuable enough to pay for?
   - How much time does the operator spend manually discovering today?

2. **No cost baseline for discovery**
   - What is the cost per discovery topic on average?
   - How does cost vary by project or codebase size?
   - What is the acceptable cost budget per cycle?

3. **No quality baseline for auto-generated topics**
   - If we auto-generate topics, what % of them would be shaped into backlog items?
   - What % would be rejected as low-value?
   - Is 50% adoption enough to be economically viable? 80%? 20%?

### Moderate Gaps

4. **No understanding of code decay patterns**
   - How quickly does dead code, unused dependencies, pattern violations accumulate in each project?
   - Should diagnostics run daily, weekly, or monthly?

5. **No measurement of discovery effectiveness**
   - Of the shaped work discovered, what % is actually delivered and approved?
   - Do operator-curated topics have higher approval rate than auto-generated ones?

6. **No cross-project dependency analysis**
   - Are there any shared concerns or patterns across the three projects?
   - Would cross-project discovery generate useful insights, or is it noise?

### Questions to Answer

- **Q1:** What topics does the operator care about discovering in each project? (Interview/survey)
- **Q2:** How often should autonomous discovery run? (Daily? Weekly? On-demand?)
- **Q3:** What is the budget ceiling for autonomous discovery per cycle?
- **Q4:** If diagnostics run daily, how many cleanup items would accumulate per week?
- **Q5:** Does the operator want to set discovery budgets per project, or run uniformly across all projects?
- **Q6:** What would make the operator trust auto-generated topics enough to let the daemon execute them unsupervised?

---

## 10. Routing Recommendation

**Status:** Requires human decision and further exploration

### Option A: Continue Discovery

**Proceed if:**
- The operator wants to invest time understanding their discovery workflow and priorities
- They're willing to run experiments (e.g., manual discovery for one week, measure time + cost)
- They want to explore automated topic generation before committing to implementation

**Next steps:**
1. Interview operator: How often do they discover? What topics matter? What's the budget?
2. Run a 1-week experiment: Track manual discovery, measure cost and time
3. Design topic generation strategy based on findings
4. Return for second round of discovery focused on topic generation feasibility

### Option B: Ready for Shaper

**Proceed if:**
- The operator confirms they want autonomous discovery (not just autonomous delivery)
- They can articulate discovery frequency and budget
- They accept that Phase 1 will use manual topic curation (static topic list or human-provided)
- They're willing to implement auto-topic-generation in Phase 2

**In this case, shape:**
- `P1-autonomous-discovery: Static topics with daemon integration` (small batch)
  - Add `--discover` flag to daemon to optionally run discovery in each cycle
  - Accept `--topics-file` from external system (topics are provided, not generated)
  - Track per-topic cost
  - Integrate with existing daemon cycle loop
  - Estimated appetite: 2-3 days (mostly bash scripting)

- `P2-autonomous-maintenance: Integrated diagnose → cleanup cycle` (medium batch)
  - Add `--auto-diagnose` flag to daemon
  - Auto-schedule `/tidy` on fresh reports if severity thresholds met
  - Estimated appetite: 3-5 days (design + prompt engineering + testing)

- `P3-topic-relevance-feedback` (deferred)
  - Track topic outcomes and collect feedback
  - Estimated appetite: 2-3 days (data collection + dashboard-free reporting)

### Option C: Needs Architect Spike

**Proceed if:**
- The operator wants automatic topic generation (not manual curation)
- They need clarity on feasibility and cost before committing

**Spike focus:**
- Evaluate topic generation options: (a) static rotation, (b) code-signal-triggered, (c) LLM-based scanning
- Prototype the most promising option
- Measure cost and quality for 3-5 generated topics in one project
- Compare auto-generated topics to manually curated ones
- Report on feasibility, cost, and recommended approach

---

## 11. Key Tensions & Non-Obvious Risks

### Tension 1: Autonomous Doesn't Mean Unsupervised

The phrase "walk away and it works" is seductive but misleading. The operator will return to:
- Review shaped work from discovery (is it valuable?)
- Approve delivery before cleanup (don't break code mid-flight)
- Handle failures (something always breaks)

**Risk:** If we design autonomous discovery as "fully hands-off," it will fail. The operator will need touchpoints for course correction.

**Mitigation:** Design autonomous discovery as "runs continuously with clear status and decision points," not "never needs human attention."

### Tension 2: Topic Quality vs. Cost

Auto-generated topics will vary in quality. Some will be valuable, some will be noise. If we accept a 50% quality rate, we're effectively paying 2x for each good topic.

**Risk:** Autonomous discovery could be economically unviable if 70%+ of auto-topics are low-value.

**Mitigation:** Don't auto-generate topics until we can measure and validate quality. Start with manual curation, use feedback to improve generation.

### Tension 3: Discovery Blocks Other Work

If the daemon is running discovery on Monday, it can't run delivery on the same projects (resource contention). The cycle will be slower.

**Risk:** Adding autonomous discovery to an already-busy daemon might slow down delivery of in-progress work.

**Mitigation:** Design discovery and delivery as separate queues, or use project-level isolation (discover project A while delivering project B).

### Tension 4: Maintenance Cleanup is Risky

Automated `/tidy` can introduce bugs. The Tidier genie is designed for human oversight (operator reviews changes, approves commit).

**Risk:** Unsupervised cleanup could break code or regress features.

**Mitigation:** Never fully automate `/tidy`. Design it as "auto-generate cleanup reports + human review" not "auto-execute cleanup."

### Tension 5: Cost Opacity Leads to Budget Shock

If per-genie cost tracking isn't designed in from the start, the operator will discover costly discovery only after the fact (bills arrive).

**Risk:** Autonomous discovery runs unchecked and exceeds budget before anyone notices.

**Mitigation:** Make cost tracking a Phase 1 requirement, not a Phase 2 nice-to-have. Every cycle must log and report cost.

### Tension 6: Cross-Item Obligations Create New Failure Modes

The new P2-deferred-obligation-tracking adds complexity: when discovery creates backlog items, those items might defer work to existing items. If obligation tracking fails, silent failures increase.

**Risk:** Autonomous discovery generates items with untracked deferrals, leading to incomplete integrations.

**Mitigation:** Ensure P2-deferred-obligation-tracking is delivered and tested BEFORE autonomous discovery is enabled. Don't layer two new complex systems simultaneously.

---

## 12. Summary: What We Know vs. Don't Know

### What We Know (Strong Evidence)
- The daemon infrastructure exists and is proven (P1-continuous-overseer, 2026-02-27)
- Cost tracking is feasible (cumulative cost works; per-phase cost requires parsing)
- Multi-project scanning is supported (daemon loop already handles `--projects`)
- The operator wants autonomous operation (problem statement says "walk away")

### What We Don't Know (Missing Evidence)
- Whether autonomous discovery is economically viable (no cost baseline, no quality baseline)
- Whether auto-generated topics can achieve >50% quality (no prototype)
- Whether daily diagnostics are better than weekly manual checks (no experiment)
- Whether the operator wants a hands-off system or hands-on-with-automation (not yet clarified)

### What We're Uncertain About (Moderate Evidence)
- Whether topic generation should be automated or manual (both are viable, tradeoffs unknown)
- Whether multi-project prioritization is necessary (three projects might not need it)
- Whether to integrate diagnostics → cleanup or keep them separate (ADR-001 prefers simplicity)

---

## 13. Routing Recommendation (Final)

**Recommend: Continue Discovery**

**Rationale:**
This opportunity has significant evidence gaps and strategic uncertainty. The operator's preference for autonomous discovery vs. manual curation is unknown. The cost economics of auto-generated topics are unvalidated. The risks of unsupervised discovery (quality, cost, safety) are not yet understood.

Rather than commit to implementation based on the problem statement alone, this work needs one more discovery phase focused on:

1. **Operator interview** — Clarify the job-to-be-done: frequency, budget, preferred discovery model (manual curation vs. auto-generation)
2. **Cost baseline** — Run 5-10 manual discovery topics, measure time + cost to establish baseline
3. **Topic generation prototype** — If auto-generation is preferred, evaluate and prototype top 2 options, measure quality and cost on one small project
4. **Risk validation** — With the operator, discuss failure modes and acceptable safety thresholds

**If this discovery clarifies preferences and validates feasibility**, the work is **Ready for Shaper** with clear Phase 1 scope (manual topic curation + daemon integration).

**If this discovery reveals that autonomous discovery is too risky or uneconomical**, the operator can proceed with the current workflow (daemon handles delivery only, discovery remains manual).

---

**Confidence:** Medium (the architectural feasibility is high, but the user need and economic viability are unclear)

**Next Genie:** Scout (more discovery), then Shaper (if discovery confirms value)
