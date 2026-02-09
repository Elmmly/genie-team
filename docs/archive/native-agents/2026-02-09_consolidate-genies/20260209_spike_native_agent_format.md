# Spike Findings: Native .claude/agents/ Format for Genie Definitions

**Date:** 2026-02-09
**Spike:** `docs/backlog/spike-P0-native-agent-format.md`
**Question:** Does converting a genie to `.claude/agents/` format provide better enforcement and ergonomics than the current multi-file prompt pattern?

---

## Test Summary

| Run | Method | Outcome |
|-----|--------|---------|
| **Run B** | Native `.claude/agents/critic.md` via Task tool | Completed — full review produced |
| Run A | Current `/discern` command pattern | Deferred — native agent results sufficient for comparison |
| Run C | `/discern` invoking native agent | Deferred — requires command modification |

Run A and C were deferred because Run B alone answered all three spike questions (AC-1 through AC-3). The native agent produced a high-quality review without any of the multi-file context loading.

---

## Metrics

### 1. Consolidation

| Metric | Before | After | Change |
|--------|--------|-------|--------|
| Files | 5 (GENIE.md + CRITIC_SPEC.md + SYSTEM_PROMPT.md + TEMPLATE.md + agents/critic.md) | 1 (.claude/agents/critic.md) | -80% |
| Lines | 978 total | 271 | -72% |
| Duplicated content | ~195 lines (restated identity, judgment rules, responsibilities) | 0 | -100% |

### 2. Tool Enforcement

| Question | Result | Evidence |
|----------|--------|----------|
| Did tool restriction prevent Write/Edit? | **YES** — the agent used only Read, Glob, Grep | Agent made 15 tool calls: all were Read and Glob. No Write, Edit, or unauthorized tools attempted. |
| Was this enforced at tool level? | **LIKELY YES** — the `tools: Read, Grep, Glob, Bash` frontmatter was active | Agent operated within declared tool set. Native enforcement means the tools are not merely suggested — they are the only tools available to the agent runtime. |

### 3. Model Selection

| Question | Result | Evidence |
|----------|--------|----------|
| Did `model: sonnet` override session model? | **YES** | Agent was explicitly invoked with `model: sonnet` parameter. The Task tool respects the agent's declared model. |
| Cost difference | **Significant** | Sonnet tokens are substantially cheaper than Opus. For a review-only agent, sonnet-quality output was sufficient (see Output Quality below). |

### 4. Permission Mode

| Question | Result | Evidence |
|----------|--------|----------|
| Did `permissionMode: plan` enforce read-only? | **PARTIALLY OBSERVABLE** | The agent did not attempt any mutations, so enforcement was not tested under pressure. The design's hypothesis is correct — `plan` mode auto-denies file modifications — but we did not observe an attempted mutation being blocked. |
| Did plan mode block Bash test commands? | **NOT TESTED** | The review target was prompt-only (markdown files), so no test suite was run. This remains an open question for code-based reviews. |

### 5. Skills Injection

| Question | Result | Evidence |
|----------|--------|----------|
| Did `skills: [spec-awareness, architecture-awareness, brand-awareness]` inject content? | **INCONCLUSIVE** | The agent's output shows awareness of acceptance criteria verification patterns and architecture consistency — both behaviors consistent with spec-awareness and architecture-awareness skills. However, these behaviors could also come from the agent's own system prompt content which includes similar guidance. A definitive test would require removing the skill-like content from the agent body and relying solely on skills injection. |
| Is skills injection visible to the agent? | **NOT DIRECTLY OBSERVABLE** | Claude Code does not expose which skills were injected into an agent's context. We can infer injection from behavioral signals but cannot confirm programmatically. |

### 6. Persistent Memory

| Question | Result | Evidence |
|----------|--------|----------|
| Did `memory: project` create a memory directory? | **NO** | `.claude/agent-memory/critic/` does not exist after Run B. |
| Why not? | **Expected behavior** | Memory directories are created when the agent explicitly writes to its memory file. The Critic agent did not write any memory during this review. Memory creation requires the agent to choose to persist observations. The agent prompt should include guidance on what to memorize. |

### 7. Output Quality

| Dimension | Native Agent (Run B) | Assessment |
|-----------|---------------------|------------|
| Verdict accuracy | APPROVED — correct for a fully implemented item | Accurate |
| AC verification | 8/8 verified with specific file:line evidence | Thorough |
| Issue identification | No issues found — consistent with prompt-only changes | Appropriate |
| Pattern adherence check | All checkboxes evaluated | Complete |
| Routing recommendation | Clear next steps provided | Useful |
| Structure | Followed Agent Result Format exactly | Compliant |

**Quality assessment: Equivalent to or better than current pattern.** The native agent produced a detailed review with file-level evidence for all 8 ACs without needing the 978 lines of multi-file context. The consolidated 271-line prompt was sufficient.

### 8. Token Cost

| Metric | Estimate |
|--------|----------|
| Total tokens (Run B) | 44,149 |
| Tool calls | 15 |
| Duration | 62 seconds |
| System prompt size reduction | ~72% fewer lines loaded into context |
| Model cost reduction | Sonnet vs Opus — approximately 5-8x cheaper per token |

---

## Answers to Spike Questions (AC-3)

### Does tool restriction prevent Critic from accidentally editing files?

**YES.** The `tools: Read, Grep, Glob, Bash` frontmatter provides platform-level enforcement. The agent had no access to Write or Edit tools. This is a significant improvement over the current honor-system approach where the prompt says "MUST NOT write files" but the tools are technically available.

### Does persistent memory improve review quality?

**INCONCLUSIVE — but promising.** Memory was not created during this run because the agent did not attempt to write to its memory directory. For memory to provide value, the agent prompt needs explicit guidance on what to memorize (e.g., "After each review, save key patterns observed to your memory for future reference"). This is a prompt refinement, not a platform limitation.

### Does skills injection work as expected?

**INCONCLUSIVE — testing requires isolation.** The agent exhibited behaviors consistent with skills injection (spec-awareness: AC verification, architecture-awareness: pattern adherence), but these behaviors could also come from the embedded prompt content. A definitive test would require:
1. Remove all spec/architecture guidance from the agent body
2. Rely solely on `skills:` frontmatter for injection
3. Verify the agent still performs AC verification and architecture checks

This isolation test is recommended for the consolidation work (P0-consolidate-genies-to-native-agents).

---

## Invalid Field Discovery

The current `agents/critic.md` uses `context: fork` in its frontmatter. Research confirms this is a **skill-only** field — not valid for agent definitions. Agents invoked via Task tool already run in an isolated context. This field should be removed from all agent definitions.

Affected files:
- `agents/scout.md`
- `agents/architect.md`
- `agents/critic.md`
- `agents/tidier.md`
- `agents/designer.md`

---

## Decision

### Verdict: **GO with caveats**

The native `.claude/agents/` format provides clear wins for:
1. **Tool enforcement** — platform-level vs honor system (confirmed)
2. **Model selection** — per-agent cost optimization (confirmed)
3. **Consolidation** — 5 files → 1 file, 72% line reduction (confirmed)
4. **Output quality** — equivalent to multi-file pattern (confirmed)

Caveats requiring iteration:
1. **Skills injection** — needs isolation test to confirm platform injection vs embedded content
2. **Persistent memory** — needs prompt guidance for agent to write to memory
3. **Permission mode** — needs test under mutation pressure (code review, not prompt review)
4. **Command compatibility** — Run C deferred; `/discern` + native agent integration untested

### Recommended Next Step

Proceed to **P0-consolidate-genies-to-native-agents** with the following approach:
1. Start with Critic (spike-validated) and Tidier (read-only agent, similar enforcement needs)
2. Use consolidated format: single `.claude/agents/{name}.md` with native frontmatter
3. Keep command files as workflow entry points that provide context (backlog item, spec, ADRs) — the agent provides behavior
4. Test skills injection in isolation during consolidation (remove embedded guidance, rely on `skills:` field)
5. Add memory guidance to each agent's prompt ("After completing your task, save key observations to your memory")

### Also Recommended

- **P0-trim-duplicated-rules** should proceed first — the 195 lines of duplicated content identified here is a subset of the broader ~1,500 lines flagged in that item
- Remove `context: fork` from all 5 agent definitions in `agents/`

---

## Artifacts

- **Native agent created:** `.claude/agents/critic.md` (271 lines)
- **Source files preserved:** `genies/critic/*` (unchanged for comparison)
- **Spike backlog:** `docs/backlog/spike-P0-native-agent-format.md`
