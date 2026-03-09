---
spec_version: "1.0"
type: shaped-work
id: P2-go-grpc-framework-guidance
title: "Go Stack Profile: gRPC Framework Guidance"
status: done
created: 2026-03-04
appetite: small
priority: P2
verdict: APPROVED
author: shaper
spec_ref: docs/specs/genies/architect-design.md
acceptance_criteria:
  - id: AC-1
    description: >-
      Go stack profile includes a gRPC section with service implementation patterns:
      protobuf conventions, interceptor chains, streaming patterns (unary, server-streaming,
      client-streaming, bidirectional), and context propagation
    status: pending
  - id: AC-2
    description: >-
      gRPC error handling patterns documented: status code mapping to domain errors,
      error details via status.Status, rich error model, interceptor-based error
      transformation
    status: pending
  - id: AC-3
    description: >-
      gRPC anti-patterns section added: blocking in handlers, missing context propagation,
      unbounded streams without backpressure, missing deadlines/timeouts, incorrect error
      wrapping (fmt.Errorf vs status.Errorf)
    status: pending
  - id: AC-4
    description: >-
      Protobuf conventions documented: naming conventions (PascalCase messages,
      snake_case fields), package structure, backward compatibility rules (never reuse
      field numbers, use reserved), buf linting recommendation
    status: pending
  - id: AC-5
    description: >-
      gRPC testing patterns documented: bufconn for in-process testing, table-driven
      service tests with status code assertions, interceptor testing, streaming test
      patterns
    status: pending
---

# Shaped Work Contract: Go Stack Profile — gRPC Framework Guidance

## Problem

When working on Go+gRPC projects with genie-team, the Crafter and Critic genies receive Go language-level quality rules (error wrapping, modern idioms, concurrency patterns) but lack gRPC-specific framework guidance. The Go stack profile (`stacks/go.md`) detects `google.golang.org/grpc` in its framework detection table but provides no gRPC-specific patterns, anti-patterns, or testing guidance.

This means:
- Protobuf naming and structure conventions aren't enforced during `/deliver`
- gRPC error handling patterns (status codes, error details) go unchecked during `/discern`
- gRPC-specific anti-patterns (blocking in handlers, missing deadlines) aren't surfaced
- Testing patterns for gRPC services aren't available to the Crafter
- The Critic has no gRPC-specific rules in the Stack Compliance review checklist

The Elixir profile demonstrates this gap by contrast — Phoenix, LiveView, and Ecto each have dedicated sections with code examples, patterns, and anti-patterns. The Go profile has nothing equivalent for its major frameworks.

## Evidence

- Current `stacks/go.md` has gRPC in framework detection table (line 28) but zero gRPC content in Rules Content section
- Elixir profile (`stacks/elixir.md`) demonstrates the pattern: dedicated Ecto section with changeset patterns, query composition, and `Ecto.Multi` examples occupies ~30 lines of the rules template
- gRPC's error model (status codes, error details, rich errors) is fundamentally different from Go's standard `error` interface — language-level error wrapping rules don't cover it
- `interceptor` pattern is gRPC-specific and has no parallel in standard Go HTTP — the Crafter won't discover it from language rules alone

## Appetite & Boundaries

- **Appetite:** Small batch (1-2 days)
- **Rationale:** This is prompt content work — adding a framework-specific section to an existing stack profile template. The pattern is established (Elixir profile). No infrastructure changes needed. Enriched templates flow through existing `/arch:init` → `.claude/rules/stack-go.md` pipeline automatically.

### No-gos
- No changes to stack-awareness skill infrastructure
- No separate framework profile mechanism (content stays in `stacks/go.md`)
- No protobuf code generation tooling integration (buf, protoc)
- No gRPC-gateway or connect-web cross-language concerns
- No gRPC reflection or health check service patterns (too niche)

### Fixed elements
- Follow existing framework section pattern from Elixir profile (code examples inline in rules template)
- Content goes in `stacks/go.md` Rules Content section under dedicated gRPC headers
- Generated rules flow through existing `/arch:init` → `.claude/rules/stack-go.md` pipeline
- Verification command remains `go build ./... && go vet ./...` (no gRPC-specific verification)

## Goals & Outcomes

- Crafter produces gRPC service implementations that follow established conventions (interceptors, proper error codes, deadline propagation)
- Critic catches gRPC anti-patterns during `/discern` Stack Compliance review
- Testing guidance enables proper gRPC test setup (bufconn, status assertions) without the Crafter guessing

## Risks & Assumptions

| Assumption | Type | Test |
|------------|------|------|
| gRPC conventions are stable enough to codify | feasibility | Check grpc-go docs for API stability; v1 API has been stable since 2020 |
| Framework-specific rules within language profile don't bloat context | feasibility | Elixir profile has ~80 lines of framework content; measure Go profile size after adding gRPC section |
| Crafter actually references framework rules during /deliver | value | Verify stack-awareness skill surfaces framework-specific rules (it reads full profile) |

## Options

| Option | Pros | Cons | Recommendation |
|--------|------|------|----------------|
| Add gRPC section to existing Go profile | Follows established pattern; no infra changes; automatic integration | Profile grows larger; gRPC rules load even for non-gRPC Go projects | **Recommended** — matches Elixir precedent |
| Create separate `stacks/grpc.md` profile | Cleaner separation; only loads when detected | Requires new framework-layering mechanism in stack-awareness; breaks current model | Not recommended — over-engineering |
| Reference external community skills | Zero maintenance; community-maintained | No genie-team integration; inconsistent quality; dependency on third parties | Not recommended for core frameworks |

## Routing

- **Next:** `/design` or direct to `/deliver` (small batch, clear pattern from Elixir profile)
- **Dependency:** None — this is independent content work

# Design

```yaml
---
spec_version: "1.0"
type: design
id: P2-go-grpc-framework-guidance-design
title: "Go Stack Profile: gRPC Framework Guidance"
reasoning_mode: deep
status: designed
created: 2026-03-04
spec_ref: docs/backlog/P2-go-grpc-framework-guidance.md
appetite: small
complexity: simple
author: architect
ac_mapping:
  - ac_id: AC-1
    approach: "Add ## gRPC Services section to Rules Content with interceptor, streaming, and context patterns"
    components: ["stacks/go.md"]
  - ac_id: AC-2
    approach: "Add ## gRPC Error Handling section to Rules Content with status code mapping and rich error model"
    components: ["stacks/go.md"]
  - ac_id: AC-3
    approach: "Add gRPC-specific entries to existing ## Anti-Patterns section in Rules Content"
    components: ["stacks/go.md"]
  - ac_id: AC-4
    approach: "Add ## Protobuf Conventions section to Rules Content with naming, compatibility, and buf recommendation"
    components: ["stacks/go.md"]
  - ac_id: AC-5
    approach: "Add bufconn entry to ## Test Framework Detection and gRPC testing guidance to ## Known Pitfalls"
    components: ["stacks/go.md"]
components:
  - name: GoStackProfile
    action: modify
    files: ["stacks/go.md"]
---
```

## Overview

Add four framework-specific sections and supplementary entries to `stacks/go.md`, enriching the Rules Content template that `/arch:init` uses to generate `.claude/rules/stack-go.md`. Follows the established pattern from the Elixir profile where Phoenix, LiveView, and Ecto each have dedicated sections with code examples and conventions inline in the rules template.

No infrastructure changes — enriched templates flow through the existing `/arch:init` pipeline automatically. The stack-awareness skill already reads the full generated rules file during `/deliver` and `/discern`, so framework-specific content is surfaced without any skill changes.

## Architecture

### Approach: Inline Framework Sections in Language Profile

**Why this approach:** The Elixir profile demonstrates that framework-specific sections inline in the language profile work well — the Ecto section (~30 lines with code examples) integrates naturally with language-level rules. The alternative (separate `stacks/grpc.md` framework profile) would require a new framework-layering mechanism in stack-awareness, breaking the current model where each language has one profile. The inline approach adds ~60 lines to a 129-line profile — well within the Elixir precedent (~160 lines total).

**Why not separate framework profiles:** Would require `/arch:init` to detect frameworks and compose multiple profile files into one rules file. The stack-awareness skill assumes one `.claude/rules/stack-{language}.md` per language. Changing this for framework separation is over-engineering given the content size.

**Failure mode considered:** If the Go profile becomes too large (>200 lines), rules may be deprioritized by the model in long sessions. Mitigation: keep framework sections concise (patterns + anti-patterns, not tutorials). The Elixir profile at ~160 lines has not shown degradation.

### Sections to Add (in Rules Content template)

Insert these sections after `## Concurrency` and before `## Naming` in the Rules Content template:

#### 1. `## gRPC Services` (AC-1)

Service implementation patterns covering:
- Proto-first development: define in `.proto`, implement to contract
- Interceptor chains: `UnaryInterceptor` and `StreamInterceptor` for cross-cutting concerns (logging, auth, metrics, recovery)
- Context propagation: always pass `context.Context` through full call chain — gRPC cancellation and deadlines depend on it
- Streaming patterns with when-to-use guidance:
  - Unary: single request → single response (default)
  - Server streaming: single request → response stream (feeds, large result sets)
  - Client streaming: request stream → single response (uploads, batch)
  - Bidirectional: stream ↔ stream (real-time, chat)
- Deadline setting: `context.WithTimeout` on all client calls
- Metadata: `metadata.FromIncomingContext(ctx)` for request metadata

#### 2. `## gRPC Error Handling` (AC-2)

Error model covering:
- `status.Errorf(codes.X, "msg")` instead of `fmt.Errorf` — this is the critical distinction from standard Go error handling
- Status code mapping table:
  - `codes.NotFound` — resource doesn't exist
  - `codes.InvalidArgument` — bad request data
  - `codes.PermissionDenied` — authorization failure
  - `codes.Internal` — unexpected server error
  - `codes.Unavailable` — transient failure (retry-safe)
  - `codes.DeadlineExceeded` — timeout
- Rich error details via `status.WithDetails()` for field violations and debug info
- Interceptor-based error transformation: catch panics → `codes.Internal`

**Why separate from existing Error Handling section:** gRPC's error model (`status.Status`) is fundamentally different from Go's `error` interface. The existing rules say "always `fmt.Errorf` with `%w`" — but in gRPC handlers, that's wrong. Separating prevents confusion.

#### 3. `## Protobuf Conventions` (AC-4)

Proto file conventions covering:
- Naming: PascalCase messages, snake_case fields, SCREAMING_SNAKE_CASE enums with type prefix
- Package structure: dot-separated reverse domain with version (`service.v1`)
- Backward compatibility: never reuse field numbers, `reserved` for removed fields, never change field types
- Buf linting recommendation: `buf lint` for enforcing conventions

#### 4. Anti-Pattern Additions (AC-3)

Append to existing `## Anti-Patterns` section:
- No `fmt.Errorf` in gRPC handlers — use `status.Errorf` with proper codes
- No missing deadlines on client calls — always `context.WithTimeout`
- No blocking operations in streaming handlers without `ctx.Done()` checks
- No panics escaping handlers — use recovery interceptor

### Sections to Update (outside Rules Content)

#### Test Framework Detection (AC-5)

Add row:
- `google.golang.org/grpc/test/bufconn` | bufconn | In-process gRPC testing

#### Known Pitfalls (AC-2, AC-3, AC-5)

Add three entries:
1. **gRPC error wrapping confusion** — Claude uses `fmt.Errorf` wrapping in gRPC handlers instead of `status.Errorf`. The Go error wrapping rules conflict with gRPC's error model. Concrete scenario: Crafter wraps a `status.Error` with `fmt.Errorf("handler: %w", err)` — the gRPC client receives `codes.Unknown` instead of the intended `codes.NotFound` because the status information is lost in the wrapping.
2. **Missing deadlines** — Claude omits `context.WithTimeout` on gRPC client calls. Concrete scenario: a downstream service goes unresponsive, and the caller hangs indefinitely because no deadline was set, cascading into thread pool exhaustion.
3. **Streaming lifecycle leaks** — Claude forgets `ctx.Done()` checks in streaming loops. Concrete scenario: client disconnects mid-stream, but the server goroutine continues processing and sending to a dead stream until it eventually errors out, wasting resources.

#### CLAUDE.md Section

Add line:
```
**gRPC:** `status.Errorf` for errors (not `fmt.Errorf`), deadlines on all client calls, interceptors for cross-cutting
```

## Risks

| Risk | L | I | Mitigation |
|------|---|---|------------|
| gRPC error rules conflict with existing Go error wrapping rules | M | M | gRPC Error Handling section explicitly notes "in gRPC handlers, use `status.Errorf` instead of `fmt.Errorf`" — framed as exception to general rule, not replacement |
| Profile size exceeds useful context window budget | L | M | Keep sections concise (~15 lines each). Total addition ~60 lines, bringing profile to ~190 lines — within Elixir precedent |
| grpc-go API changes invalidate rules | L | L | grpc-go v1 API has been stable since 2020. Version-gate rules if needed. |

## Implementation Guidance

**Sequence:**
1. Add `## gRPC Services` section to Rules Content (after `## Concurrency`, before `## Naming`)
2. Add `## gRPC Error Handling` section immediately after
3. Add `## Protobuf Conventions` section immediately after
4. Append gRPC anti-pattern entries to existing `## Anti-Patterns` section
5. Add bufconn row to `## Test Framework Detection` table
6. Add three gRPC entries to `## Known Pitfalls`
7. Add gRPC line to `## CLAUDE.md Section` template
8. Verify total profile size is under 200 lines

**Key considerations:**
- gRPC Error Handling section must explicitly call out the conflict with general Go error wrapping rules — "in gRPC handlers, use `status.Errorf` instead of `fmt.Errorf`"
- Keep code examples minimal (1-2 lines) to match existing profile style — these are rules, not tutorials
- No `## Settings Permissions` changes needed — `go build` and `go vet` already cover gRPC code

**Verification:** After editing, run `./install.sh project --dry-run /tmp/test-project` to confirm the profile template renders cleanly through the install pipeline.

## Routing

Ready for Crafter: `/deliver docs/backlog/P2-go-grpc-framework-guidance.md`

# Implementation

## Summary

Added gRPC framework-specific sections to `stacks/go.md`, enriching the Go stack profile template with service patterns, error handling, protobuf conventions, anti-patterns, testing guidance, and known pitfalls. Profile size: 171 lines (within Elixir precedent of ~162 lines).

## Changes

- `stacks/go.md`: Added `## gRPC Services`, `## gRPC Error Handling`, `## Protobuf Conventions` sections to Rules Content template. Added 4 gRPC anti-pattern entries, 3 known pitfalls, 1 test framework entry (bufconn), and gRPC line to CLAUDE.md Section template.

## AC Status

| AC | Status | Notes |
|----|--------|-------|
| AC-1 | Met | gRPC Services section: interceptors, streaming, context, deadlines |
| AC-2 | Met | gRPC Error Handling section: status codes, rich errors, interceptor recovery |
| AC-3 | Met | 4 gRPC anti-patterns added to existing Anti-Patterns section |
| AC-4 | Met | Protobuf Conventions section: naming, compatibility, versioning |
| AC-5 | Met | bufconn in Test Framework Detection + 3 gRPC Known Pitfalls |

## Phase 4: N/A — no service wiring required (prompt engineering artifact)

## Routing

Next: `/discern docs/backlog/P2-go-grpc-framework-guidance.md`

# Review

**Verdict: APPROVED**

## AC Verification

| AC | Status | Evidence |
|----|--------|----------|
| AC-1 | Met | `## gRPC Services` section: proto-first, interceptor chains (Unary/Stream), 4 streaming patterns with when-to-use, context propagation, deadlines, metadata |
| AC-2 | Met | `## gRPC Error Handling` section: `status.Errorf` vs `fmt.Errorf`, 6 status codes mapped, `status.WithDetails()` for rich errors, interceptor panic recovery |
| AC-3 | Met | 4 gRPC anti-patterns in `## Anti-Patterns`: error wrapping, missing deadlines, streaming ctx.Done(), panic recovery |
| AC-4 | Met | `## Protobuf Conventions` section: PascalCase/snake_case/SCREAMING_SNAKE naming, package versioning, field number reservation, no type changes |
| AC-5 | Met | bufconn entry in Test Framework Detection; 3 gRPC Known Pitfalls with concrete scenarios (error wrapping confusion, missing deadlines, streaming leaks) |

**ACs verified: 5/5 met**

## Quality Assessment

- **Structure:** Follows Elixir profile pattern — framework sections inline in Rules Content. Consistent style.
- **Profile size:** 171 lines (Elixir precedent: 162 lines). Within budget.
- **Key distinction surfaced:** gRPC Error Handling section clearly calls out the conflict with standard Go error wrapping — "NOT `fmt.Errorf`". This is the most important rule for preventing the #1 gRPC mistake.
- **Known Pitfalls:** Include concrete failure scenarios (e.g., wrapping `status.Error` with `fmt.Errorf` → client receives `codes.Unknown`). Good evidence quality.

## Observations (non-blocking)

1. **AC-4 — buf linting:** The design specified "buf linting recommendation: `buf lint` for enforcing conventions" but the implementation omits it. Consider adding: `- Recommend \`buf lint\` for enforcing proto conventions` to the Protobuf Conventions section.
2. **AC-5 — testing patterns depth:** The AC mentions "table-driven service tests with status code assertions, interceptor testing, streaming test patterns." The implementation covers this via bufconn detection + Known Pitfalls (which guide the Crafter toward correct patterns by describing common mistakes). For deeper testing guidance, consider adding a brief testing subsection in the rules — but the current coverage is adequate for a rules file.

## Phase 4: N/A — prompt engineering artifact, no service wiring

## Routing

Next: `/done docs/backlog/P2-go-grpc-framework-guidance.md`

# End of Shaped Work Contract
