---
type: design
concept: agents
enhancement: complement-commands
status: completed
created: 2025-12-05
---

# Design Document: Agents to Complement Commands

**Date:** 2025-12-05
**Architect:** Technical design for hybrid command/agent architecture
**Input:** `docs/analysis/20251205_discover_agents_complement_commands.md`
**Appetite:** Medium — Incremental adoption, not full rewrite
**Complexity:** Moderate

---

## 1. Design Overview

This design introduces Claude Code native agents as a complementary layer to the existing slash command system. Commands remain the orchestration and control layer (human decision gates), while agents handle isolated, specialized work (research, exploration, parallel execution). The architecture enables context-efficient workflows where heavy exploration happens in agent subcontexts, returning only distilled results to the main thread.

**Key design decisions:**
1. **Dual invocation paths:** Each genie can be invoked via command (main context) OR agent (isolated context)
2. **Commands orchestrate agents:** Commands spawn agents for research-heavy phases, coordinate results
3. **Write operations stay in main thread:** Agents read/research; main thread writes artifacts
4. **Incremental adoption:** Start with Scout agent, validate pattern, expand to others

---

## 2. Architecture

### System Context

```
┌─────────────────────────────────────────────────────────────────┐
│                     Claude Code Session                         │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                    Main Context                            │  │
│  │  ┌─────────┐ ┌─────────┐ ┌─────────┐                      │  │
│  │  │/discover│ │ /shape  │ │/deliver │  ... Commands        │  │
│  │  └────┬────┘ └─────────┘ └─────────┘                      │  │
│  │       │                                                    │  │
│  │       │ Task(subagent_type='scout')                       │  │
│  │       ▼                                                    │  │
│  │  ┌─────────────────────────────────────────────────────┐  │  │
│  │  │              Agent Subcontexts                       │  │  │
│  │  │  ┌───────┐ ┌─────────┐ ┌────────┐ ┌───────┐        │  │  │
│  │  │  │ Scout │ │Architect│ │ Critic │ │Tidier │ Agents │  │  │
│  │  │  │ Agent │ │ Agent   │ │ Agent  │ │ Agent │        │  │  │
│  │  │  └───┬───┘ └────┬────┘ └───┬────┘ └───┬───┘        │  │  │
│  │  │      │          │          │          │             │  │  │
│  │  │      └──────────┴──────────┴──────────┘             │  │  │
│  │  │                   │                                  │  │  │
│  │  │        Returns: Distilled summary only               │  │  │
│  │  └─────────────────────────────────────────────────────┘  │  │
│  │                      │                                     │  │
│  │                      ▼                                     │  │
│  │            Main context receives summary                   │  │
│  │            Main context writes artifacts                   │  │
│  └───────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

### Component Design

| Component | Responsibility | New/Modified |
|-----------|---------------|--------------|
| `.claude/agents/*.md` | Agent definitions (YAML frontmatter + system prompt) | **New** |
| `.claude/commands/*.md` | Command definitions (orchestration, human gates) | Modified |
| `genies/*_SYSTEM_PROMPT.md` | Source system prompts (reused for agents) | Unchanged |
| `install.sh` | Installer adds agents directory | Modified |

### Data Flow

**Current (Commands Only):**
```
User → /discover topic
         ↓
    Main context: Scout persona activated
         ↓
    Main context: Read files, grep, explore (pollutes context)
         ↓
    Main context: Generate Opportunity Snapshot
         ↓
    Main context: Write to docs/analysis/
         ↓
    Main context: All exploration data remains in context
```

**Proposed (Hybrid):**
```
User → /discover topic
         ↓
    Main context: Command parses input
         ↓
    Main context: Task(subagent_type='scout', prompt=topic)
         ↓
    ┌──────────────────────────────────────┐
    │ Agent subcontext (isolated):         │
    │   Scout agent: Read files, grep      │
    │   Scout agent: Explore codebase      │
    │   Scout agent: Analyze evidence      │
    │   Scout agent: Generate summary      │
    │   Returns: Opportunity Snapshot text │
    └──────────────────────────────────────┘
         ↓
    Main context: Receives distilled snapshot (not raw exploration)
         ↓
    Main context: Writes artifact to docs/analysis/
         ↓
    Main context: Clean for next phase
```

---

## 3. Interfaces & Contracts

### Agent Definition Format

```yaml
# .claude/agents/scout.md
---
name: scout
description: Discovery specialist for exploring problems and surfacing assumptions
tools: Read, Glob, Grep, WebFetch, WebSearch
model: inherit
---

# Scout Agent

[Content from genies/scout/SCOUT_SYSTEM_PROMPT.md]

## Agent-Specific Behavior

When invoked as an agent:
- Return findings as structured markdown (Opportunity Snapshot format)
- Do NOT write files (return content for main thread to write)
- Focus on distillation — return essential insights, not raw data
```

### Agent Result Format (Distillation Standard)

All agents MUST return results in this structured format to minimize context pollution:

```markdown
## Agent Result: [Agent Name]

**Task:** [Original prompt/topic]
**Status:** complete | partial | blocked
**Confidence:** high | medium | low

### Findings
[Structured output in genie's template format - e.g., Opportunity Snapshot for Scout]

### Files Examined
- [List of key files read, max 10]

### Recommended Next Steps
- [Actionable items for orchestrator]

### Blockers (if any)
- [Issues requiring Navigator/escalation]
```

**Rationale:** This format ensures agents return distilled summaries, not raw exploration transcripts. The orchestrator receives only actionable information.

### Agent Tool Configuration

**Principle:** Deny-all, then allowlist only required tools per role.

| Genie | Agent Mode Tools | Bash Allowlist | Rationale |
|-------|-----------------|----------------|-----------|
| Scout | Read, Glob, Grep, WebFetch, WebSearch | None | Research-only, no execution |
| Architect | Read, Glob, Grep, Bash | `ls`, `tree`, `git log`, `git diff`, `git show` | Design exploration, read-only system inspection |
| Critic | Read, Glob, Grep, Bash | `npm test`, `npm run test`, `pytest`, `jest`, `cargo test`, `git diff` | Review requires test execution |
| Crafter | Read, Write, Edit, Glob, Grep, Bash | `npm test`, `npm run build`, `tsc`, `eslint` | **Can be agent** with gated writes (see below) |
| Shaper | **Command-only** | N/A | Requires Navigator interaction (AskUserQuestion) |
| Tidier | Read, Glob, Grep, Bash | `git log`, `git diff` | Analysis only; actual refactoring in main thread |

**Crafter Agent Clarification:**

Crafter CAN work as an agent if write operations are properly gated:
- Agent produces code changes and returns them as structured diff/content
- Main thread reviews and applies changes (or rejects)
- Hooks can validate file modifications before execution
- This enables parallel implementation + review preparation

However, for initial implementation, keeping Crafter in main thread is safer until the pattern is validated with read-only agents.

### Command-Agent Coordination Contract

```markdown
## Command Responsibilities (Main Context)
- Parse user input and flags
- Decide whether to use agent vs direct execution
- Spawn agent with Task() tool
- Receive agent result
- Write artifacts to filesystem
- Present summary to user
- Maintain decision gates

## Agent Responsibilities (Subcontext)
- Execute specialized work in isolation
- Return distilled results (not raw data)
- Follow genie system prompt behavior
- Do NOT write files or make commits
- Do NOT interact with user (no AskUserQuestion)
```

### External Integrations

| Integration | Contract | Notes |
|-------------|----------|-------|
| Claude Code Task tool | `Task(subagent_type='name', prompt='...')` | Native Claude Code mechanism |
| Agent discovery | `.claude/agents/*.md` with YAML frontmatter | Hot-reloaded by Claude Code |
| Tool permissions | `tools:` field in agent frontmatter | Principle of least privilege |

### Hooks for Agent Coordination (Optional Enhancement)

Claude Code hooks can gate agent transitions and capture results:

```json
// .claude/settings.local.json (example)
{
  "hooks": {
    "SubagentStop": [
      {
        "matcher": ".*",
        "command": "echo '[$(date)] Agent completed' >> .claude/agent-log.txt"
      }
    ],
    "PreToolUse": [
      {
        "matcher": "Write|Edit",
        "command": "echo 'Write operation: $TOOL_INPUT' >> .claude/write-audit.txt"
      }
    ]
  }
}
```

**Hook Use Cases:**
- `SubagentStop`: Log agent completions, promote artifacts to shared location
- `PreToolUse`: Validate write commands before execution, block dangerous operations
- Audit trail for all agent activity

**Note:** Hooks are optional for MVP. Implement after core agent pattern is validated.

### CLAUDE.md Role in Agent Convergence

The project's `CLAUDE.md` file is critical for agent consistency:

```markdown
# In CLAUDE.md - Agent Conventions Section

## Agent Output Standards
- All agents use the Agent Result Format (see design doc)
- Findings section uses genie-specific templates
- Maximum 10 files listed in "Files Examined"
- Blockers always escalated to Navigator

## Context Boundaries
- Agents do NOT write files directly
- Agents do NOT use AskUserQuestion
- Agents return content; orchestrator writes artifacts
```

**Rationale:** When CLAUDE.md encodes conventions, all agents converge on shared standards, producing consistent and compressible results. This reduces context pollution and improves handoff quality.

---

## 4. Pattern Adherence

### Patterns Applied

- **Command Pattern:** Commands encapsulate orchestration decisions, agents encapsulate execution
- **Facade Pattern:** Commands provide simple interface; agents handle complex exploration
- **Single Responsibility:** Commands control flow; agents do specialized work
- **Dependency Inversion:** Commands depend on agent interface, not implementation

### Project Conventions Followed

- [x] Markdown-based configuration (consistent with commands)
- [x] YAML frontmatter for metadata (Claude Code standard)
- [x] Genie system prompts as authoritative source
- [x] Structured output templates maintained
- [x] Document trail preserved

### Deviations from Convention

| Deviation | Justification |
|-----------|---------------|
| Research agents return content instead of writing | Design choice for coordination simplicity (not technical limitation) |
| Shaper stays command-only | Requires Navigator interaction (AskUserQuestion) |

### Write Coordination: Trade-off Analysis

**Key Finding:** Agents CAN write files — this is a safety recommendation, not a technical constraint.

#### Three Write Patterns

| Pattern | How It Works | Best For |
|---------|--------------|----------|
| **1. Return Content** | Agent returns content; main thread writes | High-stakes artifacts needing review |
| **2. Hook-Gated Writes** | Agent writes; PreToolUse hook validates | High-volume, lower-stakes outputs |
| **3. Isolated Workspace** | Agent writes to dedicated branch/worktree | Parallel implementation work |

#### Trade-off Matrix

| Factor | Agent Writes Directly | Main Thread Writes |
|--------|----------------------|-------------------|
| Context efficiency | **Better** — no content round-trip | Worse — content in main context |
| Coordination risk | Higher — multi-agent conflicts | **Lower** — single control point |
| Parallelism | **Enables** concurrent work | Sequential bottleneck |
| Auditability | Harder — distributed writes | **Easier** — centralized |
| Human oversight | Requires hooks | **Natural** checkpoint |

#### Genie-Specific Recommendations

| Genie | Write Pattern | Rationale |
|-------|---------------|-----------|
| Scout | Return Content | Discovery artifacts need Navigator review |
| Architect | Return Content | Design documents are high-stakes |
| Critic | Return Content | Review findings need human judgment |
| Tidier | **Hook-Gated or Return** | Refactoring analysis vs actual changes |
| Crafter | **Isolated Workspace** | Enables parallel implementation with review |

#### Crafter Agent: Isolated Workspace Pattern

Crafter CAN be an effective agent using git worktree isolation:

```
/deliver feature-x --agent --branch=feature-x-impl
    ↓
Crafter agent: Works in dedicated worktree
    ↓
Crafter agent: Writes code, runs tests
    ↓
Returns: Branch name + implementation summary
    ↓
Main thread: Reviews diff, merges or requests changes
```

**Benefits:**
- Full write capability without coordination conflicts
- Natural code review checkpoint (PR/merge)
- Parallel Crafters on different features

**Requirements:**
- Git worktree setup per agent
- Clear branch naming convention
- Main thread handles merge decisions

---

## 5. Technical Decisions

| Decision | Options Considered | Choice | Rationale |
|----------|-------------------|--------|-----------|
| Agent invocation | Automatic vs explicit | Explicit via command flags | User controls when to use agents vs direct; transparency |
| Agent file location | `genies/` vs `.claude/agents/` | `.claude/agents/` | Claude Code native discovery path; separate concerns |
| System prompt reuse | Copy vs reference | Embed subset + agent-specific additions | Agents need modified behavior (no writes) |
| Write coordination | Agent writes vs main thread writes | Main thread writes | Avoids merge conflicts; single source of truth |
| Parallel execution | Sequential default vs parallel default | Sequential default, parallel opt-in | Predictable behavior; parallel for explicit flags |

---

## 6. Implementation Guidance

### Module Structure

```
.claude/
├── commands/
│   ├── discover.md          # Modified: can spawn scout agent
│   ├── design.md             # Modified: can spawn architect agent
│   ├── discern.md            # Modified: can spawn critic agent
│   └── ... (others unchanged initially)
│
└── agents/                   # NEW
    ├── scout.md              # Scout agent definition
    ├── architect.md          # Architect agent definition
    ├── critic.md             # Critic agent definition
    └── tidier.md             # Tidier agent definition

genies/                       # Unchanged (source of truth)
├── scout/
├── architect/
├── ...

install.sh                    # Modified: adds agents/ directory
```

### Implementation Sequence

1. [ ] **Create Scout agent definition** — First agent to validate pattern
   - Create `.claude/agents/scout.md`
   - Embed core Scout system prompt
   - Add agent-specific behaviors (no writes, return summary)
   - Configure tools: Read, Glob, Grep, WebFetch, WebSearch

2. [ ] **Test Scout agent in isolation**
   - Invoke via `Task(subagent_type='scout', prompt='...')`
   - Verify context isolation (main context stays clean)
   - Verify output quality matches command-based discovery

3. [ ] **Modify `/discover` command for hybrid mode**
   - Add `--agent` flag to use agent mode
   - Default behavior unchanged (command mode)
   - Command receives agent result, writes artifact

4. [ ] **Create remaining agents (Architect, Critic, Tidier)**
   - Follow validated Scout pattern
   - Configure appropriate tool access per genie

5. [ ] **Implement parallel patterns**
   - `/discover:feasibility` spawns Scout + Architect in parallel
   - Coordinate results, single artifact output

6. [ ] **Update installer**
   - Add `agents/` directory creation
   - Option to install agents: `--with-agents`

### Key Considerations

- **Must do:**
  - Agents return structured output (not raw exploration data)
  - Main thread writes all artifacts (no agent file writes)
  - Clear separation: agents research, commands orchestrate

- **Should do:**
  - Preserve backward compatibility (commands work without agents)
  - Document when to use agent mode vs command mode
  - Add `--agent` flag rather than changing default behavior

- **Nice to have:**
  - Automatic agent selection based on task complexity
  - Progress indicators for long-running agents
  - Agent result caching for repeated queries

---

## 7. Error Handling & Edge Cases

| Scenario | Expected Behavior | Handling |
|----------|-------------------|----------|
| Agent fails/times out | Return partial results or error | Command reports failure, offers retry or fallback to direct mode |
| Agent returns empty | No results found | Command reports, suggests different approach |
| Agent exceeds scope | Tries to write files | Tool permissions block; agent returns content instead |
| Multiple agents conflict | Concurrent results disagree | Command presents both, Navigator decides |

### Failure Modes

- **Graceful degradation:** If agent mode fails, fall back to direct command execution
- **Critical failures:** Agent crash → main thread reports error, preserves context

---

## 8. Performance Considerations

### Expected Load

- Agent invocations: 1-3 per major workflow phase
- Parallel agents: Up to 2-3 concurrent (Scout + Architect, Crafter + Critic prep)

### Potential Bottlenecks

- **Agent startup latency:** Each agent invocation has overhead
  - Mitigation: Use agents for substantial work, not trivial queries

- **Result transfer size:** Large agent outputs consume main context
  - Mitigation: Agents distill results; return summaries not raw data

### Optimization Opportunities

- **Parallel execution:** `/discover:feasibility` runs Scout + Architect concurrently
- **Cached research:** Agent results could be cached for repeated topics (future)

### Context Management for Long Workflows

For multi-phase workflows (e.g., full `/feature` lifecycle), context accumulation is a risk:

**Problem:** Even with agents, the main thread accumulates summaries over 5+ phases.

**Mitigation Strategies:**

1. **Periodic context checkpoints:**
   - After each phase, write summary to `docs/context/current_work.md`
   - Main thread can reference file instead of holding full history

2. **Agent result compaction:**
   - Agent results follow strict format (max ~500 lines)
   - Only "Findings" and "Next Steps" sections are critical
   - "Files Examined" can be truncated in subsequent references

3. **Phase isolation:**
   - Each command invocation is semi-independent
   - Reference artifacts by path, not inline content
   - Use `/context:recall` to retrieve past work instead of carrying forward

4. **Automatic compaction (future):**
   - Claude Code supports context compaction for long-running agents
   - Consider enabling for agents expected to run >5 minutes

**Best Practice:** Write artifacts to disk; reference by path. The document trail (`docs/analysis/`) is the persistent memory, not the conversation context.

---

## 9. Security Considerations

### Threat Model

- **Data sensitivity:** Agents read codebase files (same as commands)
- **Attack surface:** Agent tool permissions limit blast radius

### Security Measures

- [x] Principle of least privilege — agents get minimal tools needed
- [x] No write permissions for research agents (Scout, Architect, Critic)
- [x] Bash access restricted to read-only commands where applicable
- [x] Agent isolation prevents cross-contamination

---

## 10. Testing Strategy

### Unit Tests

| Component | Test Focus | Priority |
|-----------|-----------|----------|
| Scout agent | Returns valid Opportunity Snapshot format | High |
| Agent tool restrictions | Blocked from write operations | High |
| Command-agent coordination | Results flow correctly to main thread | High |

### Integration Tests

- [ ] `/discover topic` with `--agent` flag produces same quality as command mode
- [ ] Agent result written correctly to `docs/analysis/`
- [ ] Parallel agents (Scout + Architect) coordinate correctly

### E2E Tests

- [ ] Full `/feature` workflow with agent-based discovery
- [ ] Context size comparison: agent mode vs command mode

### Test Data Requirements

- Sample topic for discovery testing
- Codebase with sufficient complexity for meaningful exploration

---

## 11. Rollback / Feature Flag Plan

### Feature Flag

- **Name:** `--agent` flag on commands (opt-in)
- **Default:** off (commands work as before)
- **Behavior when off:** Direct command execution (current behavior)

### Rollback Procedure

1. Remove `--agent` flags from workflow
2. Commands continue working as before
3. Optionally: `rm -rf .claude/agents/` to remove agent definitions

### Monitoring

- **Metrics to watch:** Agent execution time, result quality
- **Alerts:** Agent failures, empty results

---

## 12. Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Agent output quality differs from command | Medium | Medium | Test extensively before adoption; allow fallback |
| User confusion (when to use agent vs command) | Medium | Low | Clear documentation; sensible defaults |
| Context overhead from agent results | Low | Medium | Enforce distillation format; max ~500 lines per result |
| Coordination complexity | Medium | Medium | Start simple (one agent); expand incrementally |
| Agent returns raw data instead of summary | Medium | High | Strict result format in agent prompt; validate output |
| Long workflow context accumulation | Medium | Medium | Write to disk, reference by path; use `/context:recall` |
| Permission sprawl across agents | Low | High | Deny-all default; explicit allowlist per agent |
| Agents diverge on conventions | Medium | Medium | Encode standards in CLAUDE.md; agents read at start |

### Accepted Risks

- **Learning curve:** Users must understand dual modes — acceptable given opt-in design
- **Shaper stays command-only:** Requires Navigator interaction — inherent limitation
- **Initial Crafter as command-only:** Safer until write-gating pattern validated

---

## 13. Open Questions for Crafter

- [ ] **Agent prompt length:** How much of genie system prompt to embed vs reference?
- [ ] **Result format:** Exact markdown structure for agent return values?
- [ ] **Flag naming:** `--agent` vs `--isolated` vs `--background`?
- [ ] **Installer behavior:** Always install agents, or opt-in `--with-agents`?

---

## 14. Routing

**Recommended route:**
- [x] **Crafter** — Design complete, ready for implementation
- [ ] Shaper — N/A (scope is clear)
- [ ] Scout — N/A (technical design, not discovery)
- [ ] Navigator — Approve before proceeding (significant architecture addition)

**Rationale:** The design is complete with clear implementation steps. Navigator approval recommended before implementation as this introduces a new architectural pattern.

---

## 15. Artifacts Created

- **Design saved to:** `docs/analysis/20251205_design_agents_complement_commands.md`
- **ADR created:** No (can create ADR-001 if Navigator approves)
- **Architecture docs updated:** No (will update after implementation)

---

# Summary for Navigator

This design proposes **adding Claude Code native agents as a parallel invocation path** for research-heavy genies (Scout, Architect, Critic, Tidier), while keeping commands as the orchestration layer.

**Key benefits:**
- Context isolation (agents explore without polluting main context)
- Parallel execution potential (concurrent research phases)
- Cleaner handoffs (distilled results, not raw exploration data)

**Key constraints:**
- Agents can't write files (main thread coordinates artifacts)
- Some genies stay command-only (Crafter, Shaper need main thread)
- Opt-in via flags (no change to default behavior)

**Recommended next step:** Implement Scout agent as proof-of-concept, validate pattern, then expand.

---

## Appendix: Context Management Best Practices Alignment

This design was reviewed against Claude Code best practices for context management. Key alignments and corrections:

### Aligned with Best Practices

| Best Practice | Design Implementation |
|---------------|----------------------|
| Subagents return summaries, not transcripts | Agent Result Format enforces structured distillation |
| Write authority by role | Main thread coordinates all writes; agents propose |
| Deny-all + allowlist tool permissions | Explicit Bash allowlists per agent role |
| Orchestrator maintains global state | Commands orchestrate; agents execute specialized work |
| CLAUDE.md encodes conventions | Agent conventions section added to CLAUDE.md template |

### Corrections Made During Review

1. **Added Agent Result Format** — Standardized output structure to prevent raw data dumps
2. **Explicit Bash allowlists** — Changed from vague "Bash(read-only)" to specific command lists
3. **CLAUDE.md role documented** — Added section on encoding agent conventions
4. **Hooks for gating** — Added optional SubagentStop/PreToolUse hook patterns
5. **Context compaction strategies** — Added mitigation for long workflow accumulation
6. **Write coordination analysis** — Corrected "agents can't write" to "design choice for coordination"
7. **Three write patterns documented** — Return Content, Hook-Gated, Isolated Workspace
8. **Crafter agent enabled** — Isolated Workspace pattern allows parallel implementation
9. **Additional risks identified** — Permission sprawl, convention divergence, raw data returns

### Critical Correction: Agent Write Capabilities

**Original assumption:** "Agents can't write files directly — Technical constraint"

**Corrected understanding:** Agents CAN write files. The architecture provides:
- **OS-level sandboxing** — Restricts WHERE agents can write
- **Hook validation** — Gates WHAT agents can write
- **Permission model** — Requires explicit approval by default

The "main thread writes" pattern is a **coordination design choice**, not a technical limitation. Trade-offs:

| Main Thread Writes | Agent Writes Directly |
|-------------------|----------------------|
| Simpler coordination | Better context efficiency |
| Natural review checkpoint | Enables parallelism |
| Single audit trail | Requires hook infrastructure |

**Recommendation:** Use appropriate pattern per genie role (see Write Coordination section).

### Key Context Management Principles

1. **Write artifacts to disk, reference by path** — The document trail is persistent memory
2. **Agents distill, orchestrators decide** — No raw exploration data in main context
3. **Conventions in CLAUDE.md** — All agents converge on shared standards
4. **Phase isolation** — Each command semi-independent; use `/context:recall` for history

---

# End of Design Document
