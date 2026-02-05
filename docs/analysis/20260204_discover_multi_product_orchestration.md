---
type: discover
concept: orchestration
enhancement: multi-product-parallel-execution
status: active
created: 2026-02-04
---

# Opportunity Snapshot: Multi-Product Orchestration

**Created:** 2026-02-04
**Status:** Discovery Complete

---

## 1. Discovery Question

**Original input:** How can genies work across multiple products simultaneously?

**Reframed question:** What orchestration capabilities are needed for the Genie Team to run parallel workflows across products, stream progress to a central command center, and maintain context isolation?

---

## 2. Observed Behaviors / Signals

- **Single-product focus:** Current CLI workflow targets one repo at a time
- **No cross-product visibility:** User must switch contexts to manage multiple products
- **Sequential execution:** Only one genie runs at a time per session
- **No progress aggregation:** Progress from multiple products isn't unified

---

## 3. Pain Points / Friction Areas

- **Context switching:** Managing 3+ products requires constant mental switching
- **Missed opportunities:** Similar issues across products not recognized as patterns
- **Serial bottleneck:** Waiting for one product's workflow before starting another
- **No portfolio view:** Can't see overall health across all products at once

---

## 4. Telemetry Patterns

> No telemetry available — genie-team is CLI-based

- **Estimated overhead:** 5-10 minutes context switching per product
- **Concurrency potential:** Most genie phases are independent, could run in parallel

---

## 5. JTBD / User Moments

**Primary Job:**
"When I manage multiple products, I want genies running workflows on all of them simultaneously so I can review approvals in batch rather than sequential sessions."

**Related Jobs:**
- "When Scout finds an opportunity in one product, check if related issues exist in other products"
- "When I have 10 minutes, review all pending gates across products at once"
- "When Crafter finishes on product A, start the next product automatically"

**Key Moments:**
- Morning review: What happened overnight across all products?
- Batch approval: 5 pending gates across 3 products
- Pattern recognition: Same TODO appears in multiple products

---

## 6. Assumptions & Evidence

### Assumption 1: Parallel execution doesn't degrade quality
- **Type:** value
- **What we believe:** Multiple genies running in parallel produce same quality as sequential
- **Evidence for:** Genies are stateless; no shared context between products
- **Evidence against:** Shared LLM rate limits could cause contention
- **Confidence:** high
- **Test idea:** Run same workflow parallel vs. sequential, compare output quality

### Assumption 2: Progress streaming is scalable
- **Type:** feasibility
- **What we believe:** SSE can handle streaming from 10+ concurrent workflows
- **Evidence for:** SSE is proven for high-throughput streaming
- **Evidence against:** Connection limits may require multiplexing
- **Confidence:** high
- **Test idea:** Load test: 10 concurrent SSE streams

### Assumption 3: Cross-product patterns are valuable
- **Type:** value
- **What we believe:** Identifying similar signals across products provides actionable insights
- **Evidence for:** Same bug often appears in multiple codebases
- **Evidence against:** May create alert fatigue if over-correlated
- **Confidence:** medium
- **Test idea:** Scan 3 products for TODOs, measure overlap %

---

## 7. Technical / Architectural Signals

- **Feasibility:** moderate — requires worker pool and job queue
- **Constraints:** Rate limits on LLM APIs; credential isolation per product
- **Dependencies:** Worker execution environment; Redis Streams for job queue
- **Architecture fit:** Natural extension of workflow orchestrator
- **Risks:** Cost scaling; runaway parallel execution
- **Needs Architect spike:** yes — for worker pool sizing and job prioritization

---

## 8. Opportunity Areas (Unshaped)

- **Opportunity 1: Progress streaming protocol** — Standard format for streaming genie progress to orchestrator
- **Opportunity 2: Parallel job execution** — Worker pool that runs multiple genies concurrently
- **Opportunity 3: Cross-product signals** — Identify patterns across products
- **Opportunity 4: Batch approval UX** — Review and approve multiple gates at once

---

## 9. Evidence Gaps

- **Missing data:** Typical concurrency needs (how many products, how often)
- **Unanswered questions:** Optimal worker pool size per customer
- **Research needed:** LLM rate limit strategies for parallel execution

---

## 10. Recommended Next Steps

- [ ] Define progress streaming protocol (event types, payload format)
- [ ] Spike: Worker pool with 3 concurrent genie executions
- [ ] Research Redis Streams for job queue patterns
- [ ] Design job prioritization (FIFO vs. priority queue)
- [ ] Prototype multi-product dashboard view

---

## 11. Routing Recommendation

**Recommended route:**
- [x] **Ready for Shaper** - Problem understood, ready to shape

**Rationale:** The orchestration needs are clear and can be shaped into incremental capabilities. Start with progress streaming protocol as foundation.

---

## 12. Artifacts Created

- **Snapshot saved to:** `docs/analysis/20260204_discover_multi_product_orchestration.md`
- **Backlog items created:** yes
  - `docs/backlog/architect/P1-progress-streaming-protocol.md`
  - `docs/backlog/architect/P2-batch-parallel-execution.md`

---

## 13. Notes for Future Discovery

- **Team coordination:** Multiple humans approving the same gate (consensus)
- **Cost allocation:** How to attribute LLM costs per product
- **Priority scheduling:** High-priority products get resources first

---

# End of Opportunity Snapshot
