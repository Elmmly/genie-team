---
type: discover
topic: "AI Agent Memory & Knowledge Management Landscape"
reasoning_mode: deep
status: complete
created: "2026-03-21"
---

# Opportunity Snapshot: AI Agent Memory & Knowledge Management Landscape

## 1. Discovery Question

**Original:** Research the current landscape of memory and knowledge management solutions for AI agent systems -- structured memory frameworks, vector databases, hybrid approaches, sync mechanisms, and memory taxonomies.

**Reframed:** What are the proven, production-ready approaches for giving AI agents persistent, retrievable memory -- and what are the real trade-offs between file-based simplicity, vector-semantic systems, and hybrid architectures in a CLI-tool context?

---

## 2. Observed Behaviors / Signals

### Market Consolidation (2025-2026)

The AI agent memory space has exploded into a distinct product category. At least 8 dedicated memory frameworks now compete, up from essentially zero in early 2024. Key players have raised significant funding:
- **Mem0**: $24M Series A (October 2025, YC-backed). 186M API calls/quarter by Q3 2025.
- **Zep**: Pivoted from open-source to cloud-first with Graphiti (temporal knowledge graphs) as the open-source component.
- **Letta**: Full agent runtime with self-editing memory, #1 on Terminal-Bench (model-agnostic).

### The Filesystem Benchmark Surprise

Letta's own benchmarking revealed that a simple filesystem-based agent using GPT-4o mini scored **74.0% on LoCoMo**, surpassing Mem0's graph variant at 68.5%. The explanation: LLMs have extensive pretraining on filesystem operations (grep, file search, open/close). Familiarity of interface matters as much as retrieval sophistication.

### Memory Taxonomy Convergence

The field has converged on a four-type taxonomy (first formalized in Princeton's CoALA framework, 2023):
1. **Working memory** -- current conversation context (the context window itself)
2. **Semantic memory** -- accumulated facts, user preferences, project knowledge
3. **Episodic memory** -- past interaction logs, few-shot examples distilled from history
4. **Procedural memory** -- system prompts, decision rules, internalized skills

Every major framework (Mem0, Letta, LangMem, CrewAI) builds on this taxonomy. Alternative functional taxonomies exist (factual vs experiential vs working) but have less adoption.

### Hybrid Architecture as Default

Pure vector search is no longer state-of-the-art. The trend is toward hybrid retrieval combining:
- **Semantic similarity** (vector search)
- **Keyword/BM25** (exact match)
- **Graph traversal** (relationship navigation)
- **Temporal filtering** (validity windows, recency weighting)

Zep/Graphiti and Mem0's graph variant both implement this pattern. Benchmark evidence (Amazon/Lettria) shows hybrid GraphRAG boosts answer correctness from ~50% to 80%+ over vector-only retrieval.

---

## 3. Pain Points / Friction Areas

### A. Genie-Team's Current Memory System

Genie-team uses Claude Code's built-in file-based memory:
- `CLAUDE.md` files for project instructions (manually written)
- `MEMORY.md` auto-memory in `~/.claude/projects/` (agent-written)
- `.claude/agent-memory/{genie}/` directories with typed markdown files (user, feedback, project, reference)
- Git-tracked document trail in `docs/` for project knowledge
- Agent memory is gitignored (per-machine, per-genie)

**Current friction points:**
1. **200-line MEMORY.md cap** -- forces aggressive pruning; lossy compression of knowledge
2. **No semantic retrieval** -- memory lookup is linear scan of index file; relevance depends entirely on description quality
3. **No cross-genie memory sharing** -- each genie has isolated memory; Scout cannot access what Crafter learned
4. **No decay/relevance scoring** -- stale memories persist until manually pruned
5. **Sync is manual** -- memory is gitignored, so multi-machine setups lose agent learning
6. **No structured query** -- cannot ask "what did we learn about authentication?" without reading all files

### B. Framework-Level Friction

- **Letta requires full runtime adoption** -- cannot "plug in" as a memory layer; replaces your agent loop
- **Mem0 graph features paywalled** -- free tier is vector-only; graph memory requires $249/mo Pro
- **LangMem has severe framework lock-in** -- deep LangGraph coupling, Python-only
- **AutoGen memory is effectively deprecated** -- Microsoft shifting to Agent Framework (Azure-dependent)
- **CrewAI's unified Memory API** -- elegant but tied to CrewAI's agent model; uses ChromaDB for short-term, SQLite for long-term

### C. Vector Database Operational Burden

- **ChromaDB/Qdrant/Weaviate** require server processes or Docker containers -- friction for CLI tools
- **Embedding computation** requires either API calls (cost, latency) or local models (setup, resources)
- **sqlite-vec and LanceDB** are the only truly zero-infrastructure options

---

## 4. JTBD / User Moments

**Primary Job:** "When working across multiple sessions on a complex project, a genie wants to recall relevant past findings and decisions so it can avoid redundant work and build on prior knowledge."

**Secondary Jobs:**

- "When a Scout discovers something relevant to Crafter's upcoming work, the team wants that knowledge to transfer automatically so the Crafter doesn't have to re-discover it."

- "When switching between machines or sharing a project, a developer wants genie memory to follow the project so genies don't lose their accumulated learning."

- "When memory grows large, a genie wants irrelevant memories to fade and relevant ones to surface so it can stay within context limits without losing important knowledge."

- "When debugging a recurring issue, a genie wants to recall how similar problems were solved before so it can apply proven approaches rather than re-investigating."

---

## 5. Assumptions & Evidence

### Evidence Analysis

| Assumption | Type | Confidence | Evidence For | Evidence Against |
|------------|------|------------|--------------|------------------|
| File-based memory is sufficient for current scale | Feasibility | High | Letta benchmark: filesystem agent scored 74.0% on LoCoMo, beating Mem0 graph (68.5%). Claude Code's system works in production. Genie-team operates successfully with it today. | Only tested on LoCoMo (conversation retrieval). Does not test cross-session knowledge accumulation over months. No benchmark for structured project knowledge retrieval. |
| Semantic (vector) retrieval would improve memory quality | Value | Medium | Industry convergence toward vector + hybrid search. CrewAI, Mem0, Zep all use it. 26% accuracy improvement claimed by Mem0 on LOCOMO vs full-context. | Letta's filesystem benchmark contradicts this for simple retrieval. Embedding computation adds latency/cost. The 26% claim compares against OpenAI's memory, not filesystem approach. |
| Cross-genie memory sharing would reduce redundant work | Value | Low | Intuitive appeal. No direct evidence. Current genie isolation causes observable duplication (Scout re-discovers what previous Scout found). | Genies share the document trail (`docs/`), which may be sufficient. Memory sharing adds complexity. Risk of memory contamination between roles. |
| Memory decay/relevance scoring is needed | Usability | Low | Academic consensus (CoALA, MAGMA). Common pattern in Mem0 and Zep. 200-line cap forces manual pruning today. | Current manual pruning works. Project lifespans may be short enough that decay is unnecessary. Over-engineering risk for a prompt-engineering project. |
| Local-first vector DB is viable without infrastructure | Feasibility | High | sqlite-vec (runs in any SQLite), LanceDB (serverless, Rust), ChromaDB (embedded mode), Qdrant (in-memory mode). All proven in production. | Embedding generation still requires either API calls or local model. sqlite-vec is pure C with no dependencies. LanceDB requires Rust runtime. |
| Turso/libSQL could enable cross-machine memory sync | Feasibility | Medium | Turso has native vector search + edge replication. libSQL is production-ready SQLite fork. Embedded replicas sync automatically. | Introduces cloud dependency (Turso). CRDTs would be more appropriate for conflict-free sync but add complexity. Git-based sync (current) is simpler, if manual. |
| Knowledge graphs add meaningful value over flat vector search | Value | Medium | Zep/Graphiti: temporal knowledge graphs with validity windows. Amazon/Lettria benchmarks: hybrid GraphRAG boosts correctness from ~50% to 80%+. Mem0 graph: relationship modeling across sessions. | Requires Neo4j or similar (heavy infrastructure). Graphiti needs Neo4j backend. Letta benchmark suggests familiarity of interface matters more than retrieval sophistication. The 50%->80% improvement was on enterprise RAG, not agent memory specifically. |
| Claude Code's memory system will improve natively | Viability | Medium | Anthropic is actively developing Claude Code. Memory system already progressed from simple CLAUDE.md to typed memory files with auto-memory. Claude platform now has a formal Memory Tool API. | No public roadmap for specific improvements. Current 200-line cap suggests Anthropic may keep memory lightweight by design. Improvements may not align with genie-team's needs. |

### Confidence Grade Justifications

- **File-based sufficiency (High):** Letta's benchmark is published, reproducible, and directly relevant. Claude Code's system is battle-tested across thousands of projects. Two independent data points (benchmark + production usage) with consistent signal.

- **Vector retrieval improvement (Medium):** Multiple frameworks converge on vector search, but the Letta benchmark provides credible counter-evidence. Mem0's 26% claim is single-source (their own paper, arxiv 2504.19413) against a specific baseline. Industry adoption could reflect hype rather than proven value.

- **Cross-genie sharing (Low):** Pure intuition. No benchmarks, no user studies, no case reports on agent knowledge isolation costs. The document trail may already solve this adequately.

- **Decay/relevance (Low):** Academic papers describe the pattern. No evidence that it matters at genie-team's current scale (dozens of memories, not thousands).

---

## 6. Technical Signals

### Feasibility Assessment: **Moderate**

The technical landscape offers viable options at every complexity level:

**Tier 1 -- Zero Infrastructure (current approach + improvements):**
- Enhance file-based memory with better indexing, tagging, and search
- Add simple relevance metadata (last_accessed, access_count) to frontmatter
- Cross-genie read access to shared memory directory
- Cost: Zero. Complexity: Low.

**Tier 2 -- Embedded Vector Search (local-first):**
- sqlite-vec: SQLite extension, pure C, runs anywhere SQLite runs. No server.
- LanceDB: Serverless, Rust-based, disk-backed. "SQLite for vectors."
- ChromaDB embedded: Python in-process mode. Good API, but Python-only.
- Cost: Embedding API calls (~$0.0001/1K tokens with text-embedding-3-small). Complexity: Moderate.

**Tier 3 -- Hybrid (vectors + structured metadata):**
- Turso/libSQL: SQLite fork with native vector search + edge replication + SQL metadata
- pgvector: PostgreSQL extension, 471 QPS at 99% recall on 50M vectors (but needs PostgreSQL server)
- sqlite-vec + manual knowledge graph in SQLite tables
- Cost: Turso free tier (500 DBs, 9GB storage). Complexity: Moderate-High.

**Tier 4 -- Full Memory Platform:**
- Mem0: Framework-agnostic, managed service, graph memory at Pro tier
- Zep/Graphiti: Temporal knowledge graphs, requires Neo4j
- Cost: $19-249/mo (Mem0), cloud-dependent. Complexity: High.

### Constraints
- Genie-team is a **prompt-engineering project** -- primary artifacts are markdown, not application code
- Must work in **CLI context** -- no Docker, no server processes, no web UI required
- Must support **headless/unattended operation** (claude -p)
- TypeScript is the SDK migration target (current branch: `genie/P0-typescript-sdk-migration`)
- Agent memory is currently **gitignored** -- intentional separation of project knowledge vs agent learning

### Needs Architect Spike: **Conditional**

If the decision is to move beyond Tier 1, an Architect spike would be needed to evaluate:
- sqlite-vec vs LanceDB for the TypeScript SDK context
- Embedding model selection (local vs API)
- Memory schema design
- Migration path from current file-based system

---

## 7. Opportunity Areas (Unshaped)

### A. Memory Retrieval Quality Gap
The current system has no semantic search -- memory retrieval depends entirely on description strings in MEMORY.md. As memory accumulates, finding relevant prior knowledge becomes harder. This is a retrieval quality problem, not a storage problem.

### B. Cross-Genie Knowledge Transfer Gap
Each genie operates in memory isolation. When Scout produces findings that Crafter needs, the only transfer mechanism is the document trail (`docs/analysis/`). Informal learning (patterns noticed, failed approaches, calibration insights) does not transfer between genies.

### C. Memory Lifecycle Management Gap
No automated decay, no relevance scoring, no staleness detection. The 200-line MEMORY.md cap forces manual pruning, which means knowledge is lost when it might still be valuable. The system cannot distinguish between "old but important" and "old and irrelevant."

### D. Multi-Machine / Multi-User Memory Continuity Gap
Agent memory is gitignored and machine-local. A developer switching machines or a team sharing a project loses all genie learning. The document trail transfers, but genie calibration (feedback memories, project context) does not.

### E. Memory-Aware Context Engineering Gap
Current memory is injected wholesale into context. No mechanism to selectively load memories based on the current task. As memory grows, context budget is consumed by potentially irrelevant memories rather than task-relevant knowledge.

---

## 8. Evidence Gaps

### Critical Gaps

1. **No benchmark data for genie-team's actual retrieval patterns.** The Letta filesystem benchmark and Mem0's LOCOMO scores test conversation retrieval. Genie-team's memory is project knowledge (specs, decisions, calibrations). No benchmark tests this use case.

2. **Unknown memory volume trajectory.** How fast does genie memory grow? At current pace, will the 200-line cap become a serious bottleneck in 3 months? 6 months? Is there an inflection point where file-based search breaks down?

3. **No measurement of knowledge loss from pruning.** When MEMORY.md is pruned, does useful knowledge get discarded? How often do genies re-discover something that was previously known but pruned?

4. **Cost/benefit of embedding generation for a CLI tool.** What is the latency and dollar cost of generating embeddings for each memory write? Is it acceptable for interactive use?

5. **Claude Code native memory roadmap.** Will Anthropic improve the built-in memory system in ways that make custom solutions redundant? The formal Memory Tool API suggests investment, but direction is unclear.

### Secondary Gaps

6. **Cross-genie contamination risk.** If genies share memory, does it blur role boundaries? Does a Critic genie benefit or suffer from having Crafter's implementation memories?

7. **Turso/libSQL maturity for this use case.** Edge replication is proven for web apps. Is it appropriate for CLI tool agent memory? What is the offline experience?

8. **Real-world performance of sqlite-vec at memory scale.** Benchmarks exist for millions of vectors. What about hundreds to low thousands (genie-team's likely scale)? Is the overhead justified?

---

## 9. Detailed Framework Comparison

### Agent Memory Frameworks

| Framework | Architecture | Local-First | Lock-in | Maturity | CLI-Friendly | Best For |
|-----------|-------------|-------------|---------|----------|-------------|----------|
| **Claude Code built-in** | File-based markdown, MEMORY.md index | Yes | Claude Code only | Production | Excellent | Current genie-team setup |
| **Mem0** | Vector + graph dual-store, managed service | Partial (OSS core) | Low (framework-agnostic) | Production ($24M raised) | Moderate (Python SDK) | Framework-agnostic memory layer |
| **Letta** | Three-tier self-editing memory (core/recall/archival) | Yes (self-hosted) | High (full runtime) | Production | Poor (replaces agent loop) | Agents that manage own memory |
| **Zep/Graphiti** | Temporal knowledge graph + vector | Partial (Graphiti OSS, needs Neo4j) | Medium | Production (SOC2) | Poor (needs Neo4j) | Temporal entity tracking |
| **LangMem** | Flat key-value + vector, LangGraph-native | Yes | High (LangGraph) | Stable (MIT) | Poor (Python, LangGraph) | LangGraph ecosystem |
| **CrewAI Memory** | Unified API, ChromaDB + SQLite backend | Yes | High (CrewAI) | Stable | Poor (CrewAI runtime) | CrewAI agents |
| **Hindsight** | Multi-strategy retrieval, PostgreSQL-backed | Yes (self-hosted) | Low | Early (4K stars) | Moderate | Institutional knowledge |
| **SuperMemory** | Memory graph + RAG, managed service | No (cloud-only) | Medium | Early | Poor (cloud API) | Quick memory + RAG setup |

### Vector Databases (Local-First Focus)

| Database | Language | Server Required | Vector + SQL | Embedding Built-in | Size/Deps | CLI Suitability |
|----------|---------|----------------|-------------|-------------------|-----------|----------------|
| **sqlite-vec** | C (SQLite ext) | No | Yes (it IS SQLite) | No | Tiny (~200KB) | Excellent |
| **LanceDB** | Rust + Python/TS bindings | No | Partial (Lance format) | No | Medium | Good |
| **ChromaDB** | Python | No (embedded mode) | No | Yes (default model) | Large (Python deps) | Moderate |
| **Qdrant** | Rust | Yes (or in-memory Python) | No | No | Large (binary) | Poor for CLI |
| **Weaviate** | Go | Yes (Docker) | No | Yes (modules) | Large (Docker) | Poor for CLI |
| **Pinecone** | Cloud-only | N/A (cloud) | No | No | None (API) | Poor for CLI |
| **Turso/libSQL** | C (SQLite fork) | No (embedded) | Yes (native vector) | No | Small | Excellent |

### Sync Mechanisms

| Approach | Conflict Resolution | Offline Support | Infrastructure | Complexity | Status |
|----------|-------------------|-----------------|----------------|------------|--------|
| **Git-based** (current) | Manual merge | Full | None | Low | Working, gitignored memories don't sync |
| **Turso embedded replicas** | Last-write-wins | Read-only offline | Turso cloud | Medium | Production-ready |
| **CRDTs** (Automerge, Yjs) | Automatic merge | Full | None | High (implementation) | Mature libraries, no agent-memory implementations |
| **Cloud vector DB** | Server-authoritative | No | Cloud service | Low (API) | Production but cloud-dependent |
| **File sync** (Syncthing, rsync) | Last-write-wins | Full | Peer daemon | Low | Production, crude for structured data |

---

## 10. Routing Recommendation

- [x] **Ready for Shaper** -- Problem understood
- [ ] **Continue Discovery** -- More exploration needed
- [ ] **Needs Architect Spike** -- Technical feasibility unclear (conditional -- see below)
- [ ] **Needs Navigator Decision** -- Strategic question

**Rationale:**

The landscape is well-characterized. The problem space has five distinct opportunity areas (retrieval quality, cross-genie sharing, lifecycle management, multi-machine continuity, and context engineering). Each area has a range of solutions from simple (enhance file-based system) to complex (adopt Mem0/Zep/vector DB).

**Key strategic question for Navigator:** Should genie-team invest in memory infrastructure at all, or wait for Claude Code's native memory system to improve? The current system works. The improvements are quality-of-life, not blocking. But the 200-line cap and lack of semantic retrieval will become more painful as projects grow.

**If the decision is to invest:** Route to Shaper to define appetite and scope, then Architect spike for sqlite-vec vs LanceDB vs Turso evaluation in the TypeScript SDK context. The Tier 1 improvements (enhanced file-based system with better indexing and cross-genie read access) could be shaped immediately with no spike needed.

---

## Appendix: Key Benchmark Data Points

| Benchmark | System | Score | Notes |
|-----------|--------|-------|-------|
| LoCoMo | Letta filesystem (GPT-4o mini) | 74.0% | Simple filesystem tools, no vector DB |
| LoCoMo | Mem0 graph variant | 68.5% | Vector + knowledge graph |
| LoCoMo | Mem0 (best, from their paper) | 26% above OpenAI memory | Different baseline than Letta comparison |
| LongMemEval | Hindsight | 91.4% | Multi-strategy retrieval |
| LongMemEval | SuperMemory | 81.6% | Memory graph + RAG |
| LoCoMo | Full-context (all history in prompt) | Baseline | Higher token cost, 91% more tokens than Mem0 |

## Appendix: Sources

- [Best AI Agent Memory Systems in 2026: 8 Frameworks Compared](https://vectorize.io/articles/best-ai-agent-memory-systems)
- [Mem0 vs Letta (MemGPT): AI Agent Memory Compared](https://vectorize.io/articles/mem0-vs-letta)
- [Benchmarking AI Agent Memory: Is a Filesystem All You Need?](https://www.letta.com/blog/benchmarking-ai-agent-memory)
- [AI Agent Memory: A Comparative Analysis of LangGraph, CrewAI, and AutoGen](https://dev.to/foxgem/ai-agent-memory-a-comparative-analysis-of-langgraph-crewai-and-autogen-31dp)
- [Mem0: Building Production-Ready AI Agents with Scalable Long-Term Memory](https://arxiv.org/abs/2504.19413)
- [Mem0 raises $24M (TechCrunch)](https://techcrunch.com/2025/10/28/mem0-raises-24m-from-yc-peak-xv-and-basis-set-to-build-the-memory-layer-for-ai-apps/)
- [Zep: A Temporal Knowledge Graph Architecture for Agent Memory](https://arxiv.org/abs/2501.13956)
- [Memory in the Age of AI Agents (Survey)](https://arxiv.org/abs/2512.13564)
- [AI Agent Memory Types, Implementation, Best Practices 2026](https://47billion.com/blog/ai-agent-memory-types-implementation-best-practices/)
- [How Claude remembers your project](https://code.claude.com/docs/en/memory)
- [Claude Code Memory System: MEMORY.md and Automated Maintenance](https://ianlpaterson.com/blog/claude-code-memory-architecture/)
- [LangMem SDK](https://langchain-ai.github.io/langmem/)
- [CrewAI Memory Concepts](https://docs.crewai.com/en/concepts/memory)
- [Turso brings Native Vector Search to SQLite](https://turso.tech/blog/turso-brings-native-vector-search-to-sqlite)
- [sqlite-vec GitHub](https://github.com/asg017/sqlite-vec)
- [LanceDB](https://lancedb.com/)
- [Qdrant Edge](https://qdrant.tech/blog/qdrant-edge/)
- [Graphiti (Zep open-source)](https://github.com/getzep/graphiti)
- [PostgreSQL pgvector Guide 2026](https://www.instaclustr.com/education/vector-database/pgvector-key-features-tutorial-and-pros-and-cons-2026-guide/)
- [GraphRAG & Knowledge Graphs for 2026](https://flur.ee/fluree-blog/graphrag-knowledge-graphs-making-your-data-ai-ready-for-2026/)
- [Distributed SQLite: LibSQL and Turso in 2026](https://dev.to/dataformathub/distributed-sqlite-why-libsql-and-turso-are-the-new-standard-in-2026-58fk)
- [Agent Interfaces in 2026: Filesystem vs API vs Database](https://arize.com/blog/agent-interfaces-in-2026-filesystem-vs-api-vs-database-what-actually-works/)
