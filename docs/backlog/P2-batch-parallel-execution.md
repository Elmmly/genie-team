---
spec_version: "1.0"
type: shaped-work
id: batch-parallel-execution
title: "Batch and Parallel Genie Execution"
status: shaped
created: 2026-02-04
appetite: medium
priority: P2
target_project: genie-team
author: shaper
depends_on:
  - progress-streaming-protocol
  - crafter-repo-aware-execution
tags: [orchestration, parallel, workers, scaling]
spec_ref: docs/specs/parallel-execution.md
acceptance_criteria:
  - id: AC-1
    description: "Multiple genie executions can run concurrently without interference"
    status: pending
  - id: AC-2
    description: "Each execution has isolated workspace and context"
    status: pending
  - id: AC-3
    description: "Progress events from parallel executions are tagged with workflow_id"
    status: pending
  - id: AC-4
    description: "Configurable concurrency limit prevents resource exhaustion"
    status: pending
  - id: AC-5
    description: "Job queue supports priority ordering (urgent changes first)"
    status: pending
  - id: AC-6
    description: "Failed jobs can be retried with exponential backoff"
    status: pending
---

# Shaped Work Contract: Batch and Parallel Genie Execution

> **Schema:** `schemas/shaped-work-contract.schema.md` v1.0
>
> **Status progression:** shaped -> designed -> implemented -> reviewed -> done

## Problem / Opportunity Statement

**Original input:** Genie execution is sequential; managing multiple products requires serial invocation.

**Reframed problem:** How do we enable multiple genie executions to run in parallel with proper isolation, while providing a unified view of progress and results?

## Evidence & Insights

- **From Discovery:** `docs/analysis/20260204_discover_multi_product_orchestration.md`
- **Behavioral Signals:** 5-10 minutes context switching per product; sequential execution bottleneck
- **JTBD:** "When I have multiple products to manage, I want genies running on all of them so I can batch-review results."

## Appetite & Boundaries

- **Appetite:** Medium (3-5 days)
- **Boundaries:**
  - Concurrent execution with isolation
  - Job queue with priority support
  - Concurrency limits (configurable)
  - Retry mechanism for transient failures
  - Progress aggregation from multiple workers
- **No-gos:**
  - No distributed workers (single machine initially)
  - No cross-product coordination (each workflow independent)
  - No resource preemption (jobs run to completion)
- **Fixed elements:**
  - Must respect LLM API rate limits
  - Must clean up on failure

## Goals

**Outcome Hypothesis:** "We believe parallel execution will reduce time to process N products from O(N) to O(1) with sufficient workers, increasing throughput by 5x."

**Success Signals:**
- 5 concurrent workflows complete in time of 1 sequential
- No cross-contamination between parallel executions
- Rate limit errors handled gracefully with backoff

## Risks & Assumptions

| Assumption | Type | Fastest Test |
|------------|------|--------------|
| LLM rate limits allow 5 concurrent calls | feasibility | Test: 5 parallel API calls |
| Workspace isolation prevents conflicts | feasibility | Test: 2 concurrent Crafters on same repo |
| Memory usage scales linearly | feasibility | Profile: 1, 3, 5 concurrent executions |

## Options (Ranked)

### Option 1: Worker Pool with Job Queue (Recommended)
- **Description:** Fixed pool of workers; jobs queued with priority; workers pull jobs
- **Pros:** Controlled concurrency; priority support; clean failure handling
- **Cons:** Queue management overhead
- **Appetite fit:** Good

### Option 2: Goroutine per Execution
- **Description:** Spawn goroutine for each execution; semaphore for concurrency limit
- **Pros:** Simpler; no queue infrastructure
- **Cons:** No priority; harder to manage retries
- **Appetite fit:** Tight

## Dependencies

- P1-progress-streaming-protocol (blocking — need event tagging)
- P1-crafter-repo-aware-execution (blocking — need workspace isolation)

## Routing

- [x] **Architect** — Needs design for worker pool and job queue

**Rationale:** Concurrency patterns require careful design to avoid race conditions and resource leaks.

## Solution Sketch

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    Worker Pool Architecture                                  │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  Job Queue (priority ordered)                                               │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │ [urgent] [normal] [normal] [low] [low] [low]                          │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
│       │                                                                      │
│       ▼                                                                      │
│  Worker Pool (configurable size, default: 3)                                 │
│  ┌───────────┐  ┌───────────┐  ┌───────────┐                              │
│  │  Worker 1 │  │  Worker 2 │  │  Worker 3 │                              │
│  │ (running) │  │ (running) │  │  (idle)   │                              │
│  │ wf_001    │  │ wf_002    │  │           │                              │
│  └───────────┘  └───────────┘  └───────────┘                              │
│       │              │                                                      │
│       ▼              ▼                                                      │
│  Progress Aggregator                                                        │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │ wf_001: phase=deliver, progress=45%, last_event=tool_call             │  │
│  │ wf_002: phase=discern, progress=80%, last_event=content_delta         │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Job Definition

```typescript
interface Job {
  id: string;
  workflow_id: string;
  product_id: string;
  genie: GenieType;
  input: string;
  priority: "urgent" | "normal" | "low";
  created_at: string;
  attempts: number;
  max_attempts: number;        // default: 3
  backoff_ms: number;          // exponential: 1000, 2000, 4000
  status: "pending" | "running" | "completed" | "failed" | "retrying";
}
```

### Worker Lifecycle

```
┌───────────────────────────────────────────────────────────────┐
│  Worker starts                                                │
│       │                                                       │
│       ▼                                                       │
│  Poll job from queue (blocking with timeout)                  │
│       │                                                       │
│       ├─► Job available: Claim job, mark "running"            │
│       │        │                                              │
│       │        ▼                                              │
│       │   Create isolated workspace                           │
│       │        │                                              │
│       │        ▼                                              │
│       │   Execute genie (with progress callback)              │
│       │        │                                              │
│       │        ├─► Success: Mark "completed", cleanup         │
│       │        │                                              │
│       │        └─► Failure: Check retries                     │
│       │                 │                                     │
│       │                 ├─► Retries left: Mark "retrying",    │
│       │                 │   requeue with backoff              │
│       │                 │                                     │
│       │                 └─► No retries: Mark "failed",        │
│       │                     notify, cleanup                   │
│       │                                                       │
│       └─► Timeout: Continue polling                           │
│                                                               │
└───────────────────────────────────────────────────────────────┘
```

### Concurrency Controls

| Control | Description | Default |
|---------|-------------|---------|
| `max_workers` | Worker pool size | 3 |
| `max_queue_size` | Pending job limit | 100 |
| `job_timeout` | Max execution time | 10 min |
| `rate_limit_buffer` | Reserve for API limits | 20% |

### Rate Limit Handling

```go
// Rate limiter shared across workers
type RateLimiter interface {
    Acquire() error     // Block until rate limit allows
    Release()           // Return capacity
}

// Worker respects rate limit before LLM calls
func (w *Worker) executeGenie(job Job) error {
    if err := w.rateLimiter.Acquire(); err != nil {
        return err  // Will trigger retry
    }
    defer w.rateLimiter.Release()

    // Execute genie...
}
```

### Progress Aggregation

```typescript
interface AggregatedProgress {
  total_jobs: number;
  completed: number;
  running: number;
  pending: number;
  failed: number;
  jobs: {
    [workflow_id: string]: {
      status: string;
      phase: string;
      progress_percent: number;
      last_event: ProgressEvent;
    };
  };
}
```

## Artifacts

- **Contract saved to:** `docs/backlog/P2-batch-parallel-execution.md`
- **Discovery referenced:** `docs/analysis/20260204_discover_multi_product_orchestration.md`
