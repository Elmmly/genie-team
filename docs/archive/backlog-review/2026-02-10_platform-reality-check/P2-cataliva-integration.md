---
spec_version: "1.0"
type: shaped-work
id: cataliva-integration
title: "Cataliva Integration — Multi-Product Orchestration Pilot"
status: superseded
created: 2026-02-04
superseded: 2026-02-10
superseded_by: docs/backlog/P1-autonomous-execution-readiness.md
superseded_reason: "Genie-team side absorbed into P1-autonomous-execution-readiness; Cataliva side belongs in Cataliva's backlog"
appetite: big
priority: P2
target_project: genie-team
author: shaper
depends_on: [worker-execution]
tags: [cataliva, orchestration, multi-product, dashboard, streaming]
acceptance_criteria:
  - id: AC-1
    description: "Job dispatcher spawns genie-team --worker CLI processes from Cataliva"
    status: pending
  - id: AC-2
    description: "Progress streaming captures CLI stdout in real-time for dashboard display"
    status: pending
  - id: AC-3
    description: "Status tracking maps CLI output events to job states (pending, running, success, failed)"
    status: pending
  - id: AC-4
    description: "Batch approval UX allows reviewing multiple gates in one session"
    status: pending
  - id: AC-5
    description: "Worker pool supports running parallel CLI processes across products"
    status: pending
  - id: AC-6
    description: "Pilot validates architecture with 2hearted product as first integration"
    status: pending
---

# Shaped Work Contract: Cataliva Integration

> **Schema:** `schemas/shaped-work-contract.schema.md` v1.0
>
> **Status progression:** shaped -> designed -> implemented -> reviewed -> done

## Problem / Opportunity Statement

**Original input:** `docs/analysis/20260204_discover_multi_product_orchestration.md`

**Reframed problem:** How do we enable Cataliva (a dashboard application) to orchestrate genie-team across multiple products, dispatching work and streaming progress in real-time?

## Evidence & Insights

- **From Discovery:** Managing multiple products requires central orchestration
- **Architecture Decision:** ADR-001 established Thin Orchestrator (Model A) approach
- **Pilot Product:** 2hearted provides concrete validation target
- **Current State:** Each product runs genie-team independently; no cross-product visibility

**JTBD:**
"When managing multiple products, I want to dispatch AI development work from a central dashboard so I can track progress and approve gates without context-switching."

## Appetite & Boundaries

- **Appetite:** Big (3-4 weeks)
- **Boundaries:**
  - Job dispatcher spawning CLI processes
  - Progress streaming from CLI stdout
  - Status tracking and job state management
  - Batch approval UX for multiple gates
  - Worker pool for parallel execution
  - Pilot with 2hearted product
- **No-gos:**
  - No in-process genie execution (use CLI spawning per ADR-001)
  - No shared runtime state between Cataliva and genies
  - No LLM provider abstraction (deferred with genie-core)
  - No real-time collaboration features (future)
- **Fixed elements:**
  - Must use Thin Orchestrator architecture (ADR-001)
  - Must work with unmodified genie-team CLI
  - Must support --worker flag from P1-worker-execution

## Goals

**Outcome Hypothesis:** "We believe Cataliva integration will reduce context-switching overhead by 80% when managing multiple products and provide visibility into AI development progress."

**Success Signals:**
- Trigger "Crafter implements feature on 2hearted" from Cataliva dashboard
- Watch progress stream in real-time
- Review and approve PR from Cataliva
- Multiple products can run in parallel

## Dependencies

- **Required:** P1-worker-execution (must complete first)
- **Optional:** P1-progress-streaming-protocol (enhances experience)
- **External:** Cataliva dashboard application (separate codebase)

## Risks & Assumptions

| Assumption | Type | Fastest Test |
|------------|------|--------------|
| Process spawning latency is acceptable (<2s) | Feasibility | Measure: time from dispatch to first output |
| CLI stdout provides sufficient progress info | Usability | Test: stream existing genie output, assess usefulness |
| Parallel CLI processes don't contend | Feasibility | Load test: 5 concurrent workers |
| Batch approval UX reduces review fatigue | Value | Usability test with real user |

## Solution Sketch

### Architecture (Per ADR-001)

```
┌─────────────────────────────────────────────────────┐
│  Cataliva Dashboard                                 │
│  ├── Product Registry (2hearted, cataliva, ...)    │
│  ├── Job Queue (pending, running, completed)       │
│  ├── Progress Monitor (streams from workers)       │
│  └── Approval UI (batch review gates)              │
└─────────────────────────────────────────────────────┘
                        ↓ spawns
              Worker Process Pool
              ├── Worker 1: 2hearted /deliver
              ├── Worker 2: cataliva /design
              └── Worker 3: (idle)
                        ↓ runs
              $ genie-team --worker /deliver ...
                        ↓ streams
              stdout → Progress Monitor
                        ↓ creates
              PR → Approval Queue
```

### Job Dispatcher

```typescript
interface Job {
  id: string;
  product: string;
  command: string;  // e.g., "/deliver docs/backlog/P1-feature.md"
  status: "pending" | "running" | "success" | "failed";
  output: string[];
  pr_url?: string;
}

function dispatch(job: Job): Process {
  const proc = spawn("genie-team", [
    "--worker",
    job.command,
    "--repo", job.product.repo_url,
  ]);

  proc.stdout.on("data", (chunk) => {
    job.output.push(chunk.toString());
    emit("progress", job.id, chunk);
  });

  return proc;
}
```

### Progress Streaming Protocol

CLI outputs structured events (already defined in P1-progress-streaming-protocol):

```json
{"event": "phase_start", "phase": "deliver", "timestamp": "..."}
{"event": "file_write", "path": "src/auth.ts", "lines": 42}
{"event": "phase_end", "phase": "deliver", "status": "success"}
```

Dashboard parses these events to update job state and progress indicators.

### Batch Approval UX

```
┌─────────────────────────────────────────────────────┐
│  Pending Approvals (3)                              │
├─────────────────────────────────────────────────────┤
│  □ 2hearted: PR #42 - Add user authentication      │
│    [View Diff] [View Design Doc] [Approve] [Reject]│
│                                                     │
│  □ cataliva: PR #15 - Fix job dispatcher race      │
│    [View Diff] [View Design Doc] [Approve] [Reject]│
│                                                     │
│  □ 2hearted: PR #43 - Add password reset           │
│    [View Diff] [View Design Doc] [Approve] [Reject]│
├─────────────────────────────────────────────────────┤
│  [Approve All Selected] [Reject All Selected]       │
└─────────────────────────────────────────────────────┘
```

### Worker Pool

```typescript
class WorkerPool {
  private workers: Map<string, Process> = new Map();
  private maxConcurrent: number = 3;

  async run(job: Job): Promise<void> {
    if (this.workers.size >= this.maxConcurrent) {
      await this.waitForSlot();
    }

    const proc = dispatch(job);
    this.workers.set(job.id, proc);

    proc.on("exit", () => {
      this.workers.delete(job.id);
    });
  }
}
```

### Pilot: 2hearted

First integration target:
- Product: 2hearted (existing project)
- Workflows: /discover, /define, /design, /deliver
- Success metric: End-to-end feature implementation from Cataliva dispatch

## Options (Ranked)

### Option 1: CLI Spawning (Recommended, per ADR-001)
- **Description:** Cataliva spawns genie-team CLI processes
- **Pros:** CLI unchanged, clear process boundaries, easy debugging
- **Cons:** Process overhead, no shared state
- **Appetite fit:** Good

### Option 2: genie-core Library
- **Description:** Extract shared library for in-process execution
- **Pros:** Lower latency, shared state
- **Cons:** Major refactoring, breaks stability constraint
- **Appetite fit:** Too big (deferred)

## Routing

- [x] **Architect** — Needs design for job dispatcher, progress protocol, and worker pool

**Rationale:** Orchestration involves multiple components with coordination requirements.

## Artifacts

- **Contract saved to:** `docs/backlog/P2-cataliva-integration.md`
- **Discovery referenced:** `docs/analysis/20260204_discover_multi_product_orchestration.md`
- **ADR referenced:** `docs/decisions/ADR-001-thin-orchestrator.md`
- **Depends on:** `docs/backlog/P1-worker-execution.md`

---

## Superseded — 2026-02-10

**Reason:** Per ADR-001 (Thin Orchestrator), Cataliva spawns CLI processes. The job dispatcher, worker pool, progress monitor, batch approval UX, and dashboard described here are all **Cataliva application features** — they belong in Cataliva's codebase, not genie-team's.

Genie-team's role in the Cataliva integration is to be a well-behaved CLI that produces structured, parseable output. This means:
1. **Streaming conventions** — Map genie workflow phases to native `stream-json` events
2. **Safety rules** — Branch naming, no force push, conventional commits for autonomous execution
3. **Machine-readable document trail** — Already exists (YAML frontmatter on all artifacts)
4. **CLI contract documentation** — How Cataliva invokes commands, what to parse, expected outputs

These are absorbed into `P1-autonomous-execution-readiness.md`.

**What moves to Cataliva's backlog:**
- Job dispatcher spawning CLI processes
- Progress streaming dashboard (consuming native stream-json)
- Status tracking and job state management
- Batch approval UX for multiple gates
- Worker pool for parallel execution
- Pilot with 2hearted product
