---
spec_version: "1.0"
type: shaped-work
id: progress-streaming-protocol
title: "Progress Streaming Protocol for Genie Execution"
status: shaped
created: 2026-02-04
appetite: small
priority: P1
target_project: genie-team
author: shaper
depends_on: []
tags: [streaming, protocol, orchestration, observability]
spec_ref: docs/specs/progress-streaming.md
acceptance_criteria:
  - id: AC-1
    description: "Genie execution emits structured progress events to stdout or callback"
    status: pending
  - id: AC-2
    description: "Progress events include: phase_start, tool_call, tool_result, content_delta, phase_complete"
    status: pending
  - id: AC-3
    description: "Events are JSON-serializable with consistent schema"
    status: pending
  - id: AC-4
    description: "Progress stream can be consumed by external orchestrators via callback or pipe"
    status: pending
  - id: AC-5
    description: "Final event includes summary: tokens used, tools called, artifacts produced"
    status: pending
---

# Shaped Work Contract: Progress Streaming Protocol for Genie Execution

> **Schema:** `schemas/shaped-work-contract.schema.md` v1.0
>
> **Status progression:** shaped -> designed -> implemented -> reviewed -> done

## Problem / Opportunity Statement

**Original input:** Genie execution is opaque; no visibility into what the genie is doing until it completes.

**Reframed problem:** How do we enable external orchestrators (Cataliva, CLI, dashboards) to receive real-time progress from genie execution in a standardized format?

## Evidence & Insights

- **From Discovery:** `docs/analysis/20260204_discover_multi_product_orchestration.md`
- **Behavioral Signals:** Users wait for genie completion with no feedback; debugging requires log diving
- **JTBD:** "When a genie is running, I want to see what it's doing so I can understand progress and debug issues."

## Appetite & Boundaries

- **Appetite:** Small (1-2 days)
- **Boundaries:**
  - Define progress event schema (JSON)
  - Emit events during execution via callback/stdout
  - Include tool calls and results
  - Summary event at completion
- **No-gos:**
  - No SSE server implementation (that's orchestrator responsibility)
  - No persistence of progress events (ephemeral stream)
  - No progress event replay
- **Fixed elements:**
  - Must be JSON for interoperability
  - Must include timestamps for all events

## Goals

**Outcome Hypothesis:** "We believe a progress streaming protocol will enable orchestrators to provide real-time visibility, reducing perceived wait time and improving debugging."

**Success Signals:**
- Events parsed without error by Cataliva orchestrator
- Progress visible within 1 second of genie activity
- Debugging time reduced by 50% (log diving → event inspection)

## Risks & Assumptions

| Assumption | Type | Fastest Test |
|------------|------|--------------|
| JSON events don't significantly impact performance | feasibility | Benchmark: with vs. without event emission |
| Event granularity is sufficient for debugging | usability | User test: debug issue using only events |
| Protocol is extensible for future event types | feasibility | Add test event type without breaking consumers |

## Options (Ranked)

### Option 1: Callback-Based Event Emission (Recommended)
- **Description:** Genie executor accepts optional progress callback; emits events via callback
- **Pros:** Flexible; works for CLI, HTTP, tests; no stdout pollution
- **Cons:** Requires callback plumbing
- **Appetite fit:** Good

### Option 2: Stdout JSON Lines
- **Description:** Emit newline-delimited JSON to stdout
- **Pros:** Simple; universal; pipe-friendly
- **Cons:** Mixes with other stdout; requires careful parsing
- **Appetite fit:** Good (alternative)

## Dependencies

- None — foundational protocol

## Routing

- [x] **Architect** — Needs schema design for event types

**Rationale:** Protocol design requires careful schema definition for interoperability.

## Solution Sketch

### Event Schema

```typescript
interface ProgressEvent {
  type: "phase_start" | "tool_call" | "tool_result" | "content_delta" | "phase_complete" | "error";
  timestamp: string;      // ISO 8601
  workflow_id: string;
  genie: string;          // scout, shaper, architect, crafter, critic, tidier
  payload: EventPayload;
}

interface PhaseStartPayload {
  phase: string;          // discover, define, design, deliver, discern
  input_ref?: string;     // Reference to input artifact
}

interface ToolCallPayload {
  tool: string;           // web_search, read_file, etc.
  input: object;          // Tool input parameters
  call_id: string;        // For correlating with result
}

interface ToolResultPayload {
  call_id: string;
  tool: string;
  success: boolean;
  output?: string;        // Truncated if large
  error?: string;
}

interface ContentDeltaPayload {
  delta: string;          // Incremental text
  section?: string;       // Which section being written
}

interface PhaseCompletePayload {
  phase: string;
  output_ref?: string;    // Reference to output artifact
  summary: {
    tokens_used: number;
    tools_called: number;
    duration_ms: number;
  };
}

interface ErrorPayload {
  code: string;
  message: string;
  recoverable: boolean;
}
```

### Event Flow Example

```json
{"type":"phase_start","timestamp":"2026-02-04T10:00:00Z","workflow_id":"abc123","genie":"crafter","payload":{"phase":"deliver","input_ref":"docs/backlog/P1-auth.md"}}

{"type":"tool_call","timestamp":"2026-02-04T10:00:01Z","workflow_id":"abc123","genie":"crafter","payload":{"tool":"read_file","input":{"path":"src/auth/login.ts"},"call_id":"tc_001"}}

{"type":"tool_result","timestamp":"2026-02-04T10:00:02Z","workflow_id":"abc123","genie":"crafter","payload":{"call_id":"tc_001","tool":"read_file","success":true,"output":"[truncated: 2000 chars]"}}

{"type":"content_delta","timestamp":"2026-02-04T10:00:05Z","workflow_id":"abc123","genie":"crafter","payload":{"delta":"## Implementation\n\nAdding user authentication..."}}

{"type":"phase_complete","timestamp":"2026-02-04T10:02:00Z","workflow_id":"abc123","genie":"crafter","payload":{"phase":"deliver","output_ref":"artifacts/abc123/execution_report.md","summary":{"tokens_used":15000,"tools_called":12,"duration_ms":120000}}}
```

### Consumer Interface

```go
// Genie executor with progress callback
type ProgressCallback func(event ProgressEvent)

func ExecuteGenie(
    genie GenieType,
    input string,
    tools []Tool,
    onProgress ProgressCallback,  // Optional callback
) (output string, err error)
```

### CLI Integration

```bash
# Stream progress to stderr (human-readable summary)
genie crafter --input design.md --progress

# Stream progress as JSON (machine-readable)
genie crafter --input design.md --progress-json | jq
```

## Artifacts

- **Contract saved to:** `docs/backlog/P1-progress-streaming-protocol.md`
- **Discovery referenced:** `docs/analysis/20260204_discover_multi_product_orchestration.md`
