# /design [shaped-contract]

Activate Architect genie to create technical design within shaped boundaries.

---

## Arguments

- `shaped-contract` - Path to shaped work contract (required)
- Optional flags:
  - `--interfaces` - Just interface definitions
  - `--spike` - Feasibility investigation only
  - `--review` - Review existing design

---

## Genie Invoked

**Architect** - Technical designer combining:
- Clean Architecture principles
- Interface-first design
- Pattern enforcement

---

## Context Loading

**READ (automatic):**
- docs/backlog/{priority}-{topic}.md
- docs/context/system_architecture.md
- docs/context/codebase_structure.md
- Relevant code files (as needed)

**RECALL:**
- Past designs with similar patterns
- Related ADRs (Architecture Decision Records)

---

## Context Writing

**UPDATE:**
- Backlog item: Append "# Design" section before "# End of Shaped Work Contract"
- Backlog frontmatter: `status: shaped` → `status: designed`
- docs/context/system_architecture.md (if architecture changes)
- docs/decisions/ADR-{N}.md (if significant decision)

> **Note:** Design content is appended directly to the backlog item rather than creating a separate analysis file. This keeps all work context in one living document.

---

## Output

Produces a **Design Document** containing:
1. Design Summary - What we're building
2. Component Design - Interfaces, modules, interactions
3. Data Design - Models, storage, flows
4. Integration Points - External dependencies
5. Migration Strategy - How to get there from here
6. Risks & Mitigations - Technical risks
7. Implementation Guidance - For Crafter handoff

---

## Sub-Commands

| Command | Purpose |
|---------|---------|
| `/design:interfaces [contract]` | Just interface definitions |
| `/design:spike [question]` | Feasibility investigation only |
| `/design:review [design]` | Architect reviews existing design |

---

## Usage Examples

```
/design docs/backlog/P2-auth-improvements.md
> [Architect produces Design]
> Appended to docs/backlog/P2-auth-improvements.md
> Status updated: shaped → designed
>
> Components:
> - TokenService (new)
> - AuthMiddleware (modified)
> - RefreshController (new)
>
> ADR created: ADR-015-jwt-refresh-strategy.md
>
> Next: /deliver docs/backlog/P2-auth-improvements.md

/design:spike "can we use WebSockets for notifications?"
> Feasibility: Yes, with caveats
> - Need Redis for pub/sub
> - Consider connection limits
> - Alternative: SSE for simpler cases
```

---

## Routing

After design:
- If ready for implementation: `/handoff design deliver`
- If significant decision: Create ADR, get Navigator approval
- If complexity exceeds appetite: Escalate to Shaper

---

## Notes

- Operates WITHIN shaped boundaries (not expanding scope)
- Creates clear implementation guidance
- Maintains architectural consistency
- Interfaces first, details second
