# /shape [input]

Activate Shaper genie to define problem boundaries and create a shaped work contract.

---

## Arguments

- `input` - Discovery document, backlog item, or problem statement (required)
- Optional flags:
  - `--appetite` - Just appetite and boundaries
  - `--risks` - Focus on assumption/risk identification
  - `--options` - Generate options without full contract

---

## Genie Invoked

**Shaper** - Problem definer combining:
- Ryan Singer (Shape Up)
- Appetite-based scoping
- Anti-pattern detection

---

## Context Loading

**READ (automatic):**
- docs/analysis/YYYYMMDD_discover_{topic}.md (if from discovery)
- OR backlog item provided
- docs/context/recent_decisions.md
- Product principles (if defined)
- Strategic goals (if defined)

**RECALL:**
- Past shaping on related topics
- Related constraints and decisions

---

## Context Writing

**WRITE:**
- docs/backlog/{priority}-{topic}.md

**UPDATE:**
- docs/context/current_work.md

---

## Output

Produces a **Shaped Work Contract** containing:
1. Problem Frame - What we're solving and why
2. Appetite - Time budget and boundaries
3. Solution Sketch - Rough approach (not detailed spec)
4. Rabbit Holes - What to avoid
5. Acceptance Criteria - How we'll know it's done
6. Handoff - Ready for design?

---

## Sub-Commands

| Command | Purpose |
|---------|---------|
| `/shape:appetite [input]` | Just appetite and boundaries |
| `/shape:risks [input]` | Focus on assumption/risk identification |
| `/shape:options [input]` | Generate options without full contract |

---

## Usage Examples

```
/shape docs/analysis/20251203_discover_auth.md
> [Shaper produces Shaped Work Contract]
> Saved to docs/backlog/P2-auth-improvements.md
>
> Appetite: 2 weeks
> Solution sketch: Implement refresh tokens with sliding window
> Key rabbit holes: Don't rebuild entire auth system
>
> Next: /handoff shape design

/shape:appetite "add dark mode"
> Appetite assessment: Small batch (3 days max)
> Boundaries: CSS variables only, no component changes
```

---

## Routing

After shaping:
- If ready for technical design: `/handoff shape design`
- If appetite unclear: `/shape:appetite` then full `/shape`
- If high risk: Flag for Navigator review

---

## Notes

- Sets boundaries BEFORE deep technical work
- Prevents scope creep through explicit appetite
- Creates clear contract between discovery and delivery
- Anti-pattern: shaping as detailed specification
