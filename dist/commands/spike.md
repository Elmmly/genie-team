# /spike [question]

Technical investigation workflow: discover → design (feasibility only).

---

## Arguments

- `question` - Technical question to investigate (required)
- Optional flags:
  - `--time-box` - Maximum time to spend (default: 2 hours)
  - `--prototype` - Build throwaway prototype

---

## Purpose

Spikes answer technical questions before committing to full implementation:
- "Can we use WebSockets for this?"
- "How would we integrate with API X?"
- "What's the performance of approach Y?"

---

## Workflow

```
/spike "can we use GraphQL subscriptions for real-time updates?"
    │
    ├─→ /discover (scoped to question)
    │   └─→ Research existing approaches
    │   └─→ Identify constraints
    │   └─→ Map assumptions
    │
    └─→ /design:spike [discovery]
        └─→ Feasibility assessment
        └─→ Technical approach (if feasible)
        └─→ Risks and tradeoffs
        └─→ Recommendation
```

---

## Output

```markdown
# Spike: [Question]

**Question:** [Technical question]
**Time spent:** [Hours]
**Verdict:** [Feasible / Not Feasible / Needs More Investigation]

## Findings
[What we learned]

## Approach (if feasible)
[How we would do it]

## Risks
[Technical risks]

## Recommendation
[What to do next]
```

---

## Usage Examples

```
/spike "can we use WebSockets for real-time notifications?"
> Spike started: WebSocket feasibility
> Time box: 2 hours
>
> Discovery:
> - Current architecture supports long-polling
> - Redis available for pub/sub
> - ~5000 concurrent users expected
>
> Feasibility:
> Verdict: FEASIBLE with caveats
>
> Approach:
> - Use Socket.io for WebSocket abstraction
> - Redis adapter for horizontal scaling
> - Fallback to SSE for older clients
>
> Risks:
> - Connection limits on current hosting
> - Need sticky sessions or Redis
>
> Recommendation:
> Proceed with shaped work, allocate 1 week appetite

/spike --prototype "GraphQL code generation"
> Spike with prototype
> [Creates throwaway implementation]
> Prototype: /tmp/graphql-spike/
> Learning: Works but requires schema-first approach
```

---

## Routing

After spike:
- **Feasible**: Proceed to `/shape` with findings
- **Not feasible**: Document why, consider alternatives
- **Needs more**: Extend time box or split into sub-spikes

---

## Notes

- Time-boxed investigation
- No production code written
- Answers specific technical questions
- Reduces risk before commitment
- Prototypes are throwaway (not production)
