# /discover [topic]

Activate Scout genie to explore opportunities and surface assumptions.

---

## Arguments

- `topic` - What to discover (required)
- Optional flags:
  - `--assumptions` - Focus on assumption mapping only
  - `--evidence` - Focus on evidence gathering only
  - `--feasibility` - Include Architect feasibility check

---

## Agent Identity

Read and internalize `.claude/agents/scout.md` for your identity, charter, and judgment rules.

---

## Context Loading

**READ (automatic):**
- CLAUDE.md
- docs/context/system_architecture.md
- docs/context/recent_decisions.md
- docs/decisions/ADR-*.md (scan for ADRs relevant to the discovery topic)
- Any provided telemetry/data

**RECALL (if topic matches past work):**
- Previous discovery on this topic
- Related decisions

---

## Context Writing

**WRITE:**
- docs/analysis/YYYYMMDD_discover_{topic}.md

**UPDATE:**
- docs/context/current_work.md (mark discovery in progress)

---

## Output

Produces an **Opportunity Snapshot** containing:
1. Context Summary - What we know
2. Opportunity Frame - Jobs, outcomes, JTBD
3. Evidence Analysis - Data, quotes, observations
4. Assumption Map - Risky assumptions to test
5. Recommended Path - What to do next
6. Architecture Context - Relevant ADRs that inform the discovery topic (if they exist)

---

## Sub-Commands

| Command | Purpose |
|---------|---------|
| `/discover:assumptions [topic]` | Assumption mapping only |
| `/discover:evidence [topic]` | Evidence gathering only |
| `/discover:feasibility [topic]` | Include Architect feasibility |

---

## Usage Examples

```
/discover "user authentication improvements"
> [Scout produces Opportunity Snapshot]
> Saved to docs/analysis/20251203_discover_auth.md
>
> Key findings:
> - Users frustrated with SSO login failures
> - Token expiry too aggressive
> - No refresh token mechanism
>
> Next: /handoff discover shape

/discover:feasibility "real-time notifications"
> [Scout + Architect collaboration]
> Opportunity identified + technical feasibility assessed
```

---

## Routing

After discovery:
- If ready to scope: `/handoff discover shape`
- If more evidence needed: Continue discovery
- If technically complex: `/discover:feasibility`

---

## Notes

- Problem-first orientation (not solution-first)
- Surfaces assumptions before investment
- Creates document trail for future reference
- Run /context:recall first to avoid duplicate work
