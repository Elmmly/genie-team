---
type: discover
concept: agents
enhancement: complement-commands
status: completed
created: 2025-12-05
---

# Opportunity Snapshot: Agents to Complement Commands
### Scout Genie Discovery — 2025-12-05

---

## 1. Discovery Question

**Original input:** "use of agents to compliment the use of commands for the genie team"

**Reframed question:** How might Claude Code's native subagent architecture complement the existing slash command-based genie system to create a more powerful, context-efficient, and scalable workflow?

---

## 2. Observed Behaviors / Signals

- **Current architecture is command-centric:** The genie-team uses 18 slash commands (`.claude/commands/`) to invoke specialized personas (Scout, Shaper, Architect, Crafter, Critic, Tidier)
- **Commands inject prompts into main context:** All command outputs flood the single conversation thread, contributing to context pollution over time
- **Genies are personas, not isolated agents:** Each genie is a system prompt that shapes Claude's behavior, but they share the same context window
- **Document trail is well-designed:** Opportunity Snapshots, Design Documents, Implementation Reports create persistent artifacts outside the conversation
- **Handoffs are explicit but manual:** `/handoff` command summarizes context for transitions, but all context still lives in one thread
- **Workflows orchestrate linearly:** `/feature` runs through 5 phases sequentially with human confirmation gates
- **No parallel execution:** Current architecture doesn't leverage concurrent work

---

## 3. Pain Points / Friction Areas

- **Context accumulation:** Long feature workflows accumulate context, potentially degrading later-phase quality as the context window fills with earlier artifacts
- **No isolation between genies:** Scout's exploration pollutes the context that Crafter needs for implementation
- **Sequential bottleneck:** Complex work can't be parallelized (e.g., Architect feasibility check while Scout continues discovery)
- **Research overhead in main thread:** Every file read, grep, or codebase exploration consumes main context tokens
- **Genie "mode switching":** Asking Claude to become a different persona mid-conversation is less reliable than true isolation
- **Scaling limits:** Can't easily have multiple genies working on related tasks simultaneously

---

## 4. Telemetry Patterns

> No telemetry data provided. This is a design-phase project.

- **Metrics:** N/A
- **Trends:** N/A
- **Anomalies:** N/A
- **Confidence:** Low (conceptual analysis only)

---

## 5. JTBD / User Moments

**Primary Job:**
"When I'm using the genie team on a complex feature, I want to delegate specialized work to focused agents so that I can maintain a clean main context while getting deep expertise in each phase."

**Related Jobs:**
- "When I need both discovery research and feasibility analysis, I want them to run in parallel so I don't wait for sequential handoffs."
- "When Crafter is implementing, I want Critic to prepare review criteria simultaneously so the feedback loop is faster."
- "When exploring a large codebase, I want to offload the exploration to a specialized agent so my main context stays focused on decisions."

**Key Moments:**
- Starting `/feature` on a complex topic — want parallel discovery streams
- Handoff from `/discover` to `/shape` — want distilled summary, not full exploration context
- Long implementation in `/deliver` — want background code review preparation
- Technical spike in `/diagnose` — want codebase exploration without main context pollution

---

## 6. Assumptions & Evidence

### Assumption 1: Subagents would reduce context pollution

- **Type:** Usability / Feasibility
- **What we believe:** Moving exploration and research to subagents would keep the main context cleaner and improve later-phase quality
- **Evidence for:** Claude Code docs explicitly describe context isolation as a key subagent benefit; Jason Liu's article identifies "context pollution" as the core problem subagents solve
- **Evidence against:** No empirical data on how much this affects genie-team specifically
- **Confidence:** Medium-High
- **Test idea:** Run same feature through command-only vs command+agent approaches, compare Crafter output quality

### Assumption 2: Genie personas would work as isolated agents

- **Type:** Feasibility
- **What we believe:** Current genie system prompts (e.g., SCOUT_SYSTEM_PROMPT.md) could be converted to agent definitions in `.claude/agents/`
- **Evidence for:** Claude Code supports custom agents with YAML frontmatter + markdown content; genie prompts are already structured markdown
- **Evidence against:** Agents have different capabilities (tool access, model selection) than commands; may need restructuring
- **Confidence:** Medium
- **Test idea:** Convert Scout genie to agent format, test discovery quality

### Assumption 3: Parallel agents would speed up workflows

- **Type:** Value
- **What we believe:** Running complementary genies in parallel (e.g., Scout + Architect feasibility) would reduce wall-clock time
- **Evidence for:** Claude Code supports up to 10 concurrent agents; docs describe parallel execution patterns
- **Evidence against:** Some genie work is inherently sequential (can't shape without discovery); coordination adds overhead
- **Confidence:** Medium
- **Test idea:** Time `/discover:feasibility` with sequential vs parallel execution

### Assumption 4: Commands should orchestrate agents, not replace them

- **Type:** Usability
- **What we believe:** The optimal architecture uses commands for orchestration/control and agents for specialized delegation
- **Evidence for:** Multiple sources (ArsTurn, InfoQ) describe this as best practice; commands provide human decision gates that agents lack
- **Evidence against:** Could add complexity; users must understand both paradigms
- **Confidence:** High
- **Test idea:** Design hybrid command that spawns agents, evaluate UX

---

## 7. Technical / Architectural Signals

- **Feasibility:** Moderate — Claude Code native support exists, but integration needs design
- **Constraints:**
  - Write operations must stay in main thread (agents can't safely edit same files)
  - Agent definitions live in `.claude/agents/`, commands in `.claude/commands/`
  - Tool access must be configured per agent (principle of least privilege)
- **Dependencies:**
  - Claude Code's Task tool with `subagent_type` parameter
  - Agent discovery and hot-reload mechanism
  - Context isolation and result summarization
- **Architecture fit:**
  - Current: Commands invoke genies as personas in main context
  - Proposed: Commands orchestrate agents as isolated subcontexts
  - Transition: Could be incremental (some genies as agents, some as commands)
- **Risks:**
  - Coordination complexity between main thread and agents
  - Different behavior between command-invoked persona vs agent-invoked specialist
  - Document artifact creation may need to stay in main thread
- **Needs Architect spike:** Yes — design the command/agent boundary and coordination model

---

## 8. Opportunity Areas (Unshaped)

- **Opportunity 1: Research Offloading** — Use agents for codebase exploration, file reading, and evidence gathering (Scout, Architect feasibility) while main context stays decision-focused

- **Opportunity 2: Parallel Phase Execution** — Allow complementary genies to work simultaneously (e.g., Scout continues discovery while Architect assesses feasibility; Crafter implements while Critic prepares review criteria)

- **Opportunity 3: Context Distillation** — Agents return only summaries/artifacts, keeping main context lean; enables longer workflows without degradation

- **Opportunity 4: Specialized Tool Access** — Configure agents with minimal required tools (Scout: read-only; Crafter: write access; Critic: read-only + test execution)

- **Opportunity 5: Agent-as-Genie Parity** — Convert some or all genie system prompts to agent definitions, enabling consistent behavior whether invoked via command or Task tool

---

## 9. Evidence Gaps

- **Missing data:**
  - No usage data on current context pollution patterns
  - No benchmarks comparing command vs agent execution times
  - No user feedback on current workflow friction points
- **Unanswered questions:**
  - How do genies handle document artifact creation in agent mode?
  - What's the overhead of agent coordination vs sequential commands?
  - Which genies benefit most from isolation vs staying in main context?
- **Research needed:**
  - Prototype one genie (Scout) as both command and agent, compare outputs
  - Analyze typical `/feature` context growth over phases
  - Map which genie operations are read-only vs write-requiring

---

## 10. Recommended Next Steps

- [ ] Create Scout agent definition in `.claude/agents/scout.md` to test conversion
- [ ] Run comparison: `/discover` command vs Task(subagent_type='scout') on same topic
- [ ] Design coordination model: how commands spawn and manage agents
- [ ] Map each genie's tool requirements for agent configuration
- [ ] Prototype `/discover:parallel` that runs Scout + Architect feasibility concurrently
- [ ] Document decision framework: when to use command vs agent for each genie

---

## 11. Routing Recommendation

**Recommended route:**
- [ ] Continue Discovery — More evidence needed on specific genie conversions
- [x] **Ready for Shaper** — Problem understood, ready to frame appetite and constraints
- [x] **Needs Architect Spike** — Technical design for command/agent boundary required
- [ ] Needs Navigator Decision — Not blocking on strategic questions

**Rationale:** The opportunity is clear and technically feasible. Shaper should frame the appetite (how much to invest in this integration) while Architect investigates the coordination model between commands and agents. These can run in parallel.

---

## 12. Artifacts Created

- **Snapshot saved to:** `docs/analysis/20251205_discover_agents_complement_commands.md`
- **Backlog item created:** No — awaiting shaping

---

## 13. Notes for Future Discovery

- Explore how MCP servers might provide additional tool capabilities to agents
- Investigate whether agents could maintain their own persistent memory/context across sessions
- Consider how this pattern might extend to multi-user/multi-session collaboration
- Look at Claude Agent SDK for more sophisticated agent orchestration patterns

---

# End of Opportunity Snapshot
