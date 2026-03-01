---
type: analysis
topic: Context Protocol — Cataliva Integration Scoping Prompt
date: 2026-02-27
status: complete
---

# Cataliva Integration: Context Protocol Scoping Prompt

## Purpose

This document defines how Cataliva (or any external markdown-producing system) integrates with the genie-team daemon via the **context protocol** — two file-based interfaces for injecting strategic grounding and suggesting new work.

---

## What Cataliva Should Write: Topic Files

### Directory

`docs/topics/`

### Naming Convention

`YYYYMMDD-slug.md` — date-prefixed, kebab-case slug describing the topic.

Examples:
- `20260228-auth-reliability-issues.md`
- `20260301-onboarding-drop-off.md`
- `20260301-competitor-launched-feature-x.md`

### Schema Contract

```yaml
---
title: "Human-readable topic title"
status: pending
priority: P1          # P0 (critical) | P1 (high) | P2 (medium) | P3 (low)
context: "Brief background — why this topic matters now"
source: cataliva      # or: human, slack-alert, monitoring, etc.
created: 2026-02-28
---

Body markdown with additional context, evidence, links, or data that
the Scout genie should consider during discovery.

Can include:
- Customer quotes or feedback
- Metrics or telemetry snippets
- Links to external resources
- Competitive intelligence
- Screenshots or references to artifacts
```

### Required Fields

| Field | Type | Description |
|-------|------|-------------|
| `title` | string | Discovery topic — becomes the `/discover` argument |
| `status` | enum | Must be `pending` for intake. Other values are ignored. |
| `priority` | enum | `P0` through `P3`. Controls daemon processing order. |

### Optional Fields

| Field | Type | Description |
|-------|------|-------------|
| `context` | string | Brief background included as evidence in discovery |
| `source` | string | Where this topic originated |
| `created` | date | When the topic was created |

---

## Topic File Lifecycle

```
Cataliva writes docs/topics/YYYYMMDD-slug.md (status: pending)
         ↓
Daemon resolve_batch_items() scans, sets status: processing
         ↓
/discover reads file, extracts title + context, runs discovery
         ↓
/discover sets status: done, adds result_ref to topic file
         ↓
Opportunity Snapshot feeds into /define → /design → /deliver → /discern → /done
```

### Status Values

| Status | Meaning | Set By |
|--------|---------|--------|
| `pending` | Ready for intake | Cataliva |
| `processing` | Picked up by daemon, discovery in progress | Daemon |
| `done` | Discovery complete, result available | /discover command |

### Post-Discovery Fields (added by /discover)

| Field | Type | Description |
|-------|------|-------------|
| `result_ref` | path | Path to the Opportunity Snapshot output |
| `completed` | date | When discovery finished |

---

## What Cataliva Should NOT Do

1. **Do NOT write to `docs/context/`** — strategic context files are human-curated. If Cataliva has strategic updates, open a PR with proposed changes (see below).
2. **Do NOT write to `docs/backlog/`** — backlog items are created by the `/define` phase after discovery. The topic → backlog pipeline is: topic file → discover → define → backlog item.
3. **Do NOT modify topic files after writing** — once a topic has `status: pending`, the daemon owns the lifecycle. Cataliva should treat the file as immutable after creation.
4. **Do NOT set `status` to anything other than `pending`** — the daemon manages the `processing` → `done` transitions.

---

## Strategic Context Sync

Cataliva may surface strategic insights that should ground all genie work (not just one discovery topic). These go into `docs/context/` — but via pull request, not direct write.

### Process

1. Cataliva detects a strategic signal (market shift, competitor move, new data).
2. Cataliva opens a PR updating the relevant context file:
   - `docs/context/strategy.md` — direction, bets, non-goals
   - `docs/context/market.md` — landscape, alternatives, trends
   - `docs/context/season.md` — time constraints, upcoming events
   - `docs/context/assumptions.md` — validated/overturned assumptions
3. A human reviews and merges the PR.
4. The daemon picks up the updated context on the next cycle — all phases automatically see it via `build_phase_prompt()`.

### Why PRs, Not Direct Write

Strategic context shapes every phase of every backlog item. A bad strategic context file could misguide dozens of decisions. Human review is the appropriate control for this blast radius.

---

## Integration Checklist

For an external system to integrate with the context protocol:

- [ ] Can write markdown files to `docs/topics/` with correct frontmatter schema
- [ ] Sets `status: pending` on new topic files
- [ ] Uses `YYYYMMDD-slug.md` naming convention
- [ ] Does NOT write to `docs/context/` or `docs/backlog/` directly
- [ ] Can read topic file status to track lifecycle (pending → processing → done)
- [ ] Can read `result_ref` field to find discovery output
- [ ] Strategic updates go through PR process targeting `docs/context/` files

---

## Example: Complete Topic File

```markdown
---
title: "Auth service timeout spike after deploy"
status: pending
priority: P1
context: "Auth service p99 latency jumped from 200ms to 1.2s after yesterday's deploy. 3 customer complaints in Slack."
source: cataliva
created: 2026-02-28
---

## Evidence

- Datadog dashboard shows p99 spike starting 2026-02-27 14:30 UTC
- 3 customers reported "login taking forever" in #support channel
- No config changes in auth service — suspect upstream dependency

## Possible Angles

- Connection pool exhaustion under new traffic pattern
- Upstream identity provider latency change
- Missing circuit breaker on token validation path
```
