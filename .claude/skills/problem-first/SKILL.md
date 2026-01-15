---
name: problem-first
description: Ensures problem-first framing before solutioning. Use when defining work, discussing features, handling requests that sound like solutions, or when someone says "we should add" or "let's build".
allowed-tools: Read, Glob, Grep
---

# Problem-First Framing

Reframe solution-loaded requests as problems before proceeding.

## The Principle

> "What is true?" before "What should we do?"

## Detecting Solution-Loaded Requests

| Input Pattern | Response |
|---------------|----------|
| "We should add caching" | "What performance problems are users experiencing?" |
| "Let's build a dashboard" | "What decisions do users need to make? What data do they need?" |
| "Add a button for X" | "What task are users trying to accomplish?" |
| "We need microservices" | "What scaling or development problems are we facing?" |

## Reframing Process

1. **Identify the embedded solution** — What are they proposing?
2. **Surface the assumption** — Why do they think this solves something?
3. **Ask about the problem** — What triggered this request?
4. **Explore evidence** — What data supports this need?

## JTBD Framing

When the request involves users, apply Jobs-to-be-Done:

```
"When [situation], [user] wants to [motivation] so they can [outcome]."
```

**Example:**
- Solution: "Add export to PDF"
- JTBD: "When preparing for client meetings, account managers want to share usage reports so they can demonstrate value and justify renewal."

## Questions to Ask

- What problem triggered this request?
- Who experiences this problem?
- How often does it occur?
- What's the impact when it happens?
- What workarounds exist today?
- How would we know if we solved it?

## Output Format

When reframing, structure as:

```markdown
## Original Request
[What was asked]

## Reframed Problem
[Problem-focused version]

## Assumptions to Validate
- [Assumption 1]
- [Assumption 2]

## Questions to Answer
- [Question 1]
- [Question 2]

## Suggested Next Step
[Discovery, clarification, or proceed if problem is clear]
```

## When to Proceed Without Reframing

- Problem is already clearly stated
- User has explicitly validated the problem
- This is a bug fix with clear reproduction steps
- User says "I know the problem, just do X"
