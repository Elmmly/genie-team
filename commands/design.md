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
- Backlog frontmatter field `spec_ref` → load the linked spec for context (ACs, domain, existing evidence)
- docs/context/system_architecture.md
- docs/context/codebase_structure.md
- Relevant code files (as needed)

**RECALL:**
- Past designs with similar patterns
- Related ADRs (Architecture Decision Records)

**SPEC LOADING:**
1. Read `spec_ref` from backlog item frontmatter
2. If `spec_ref` is present: Read the spec file. Use its acceptance_criteria and any existing evidence as design context.
3. If `spec_ref` is missing: Warn and continue without spec context:
   > This backlog item has no spec_ref. Design will proceed without spec context.
4. If `spec_ref` points to a nonexistent file: Warn and continue:
   > spec_ref points to {path} but file not found. Design will proceed without spec context.

---

## Context Writing

**UPDATE:**
- Backlog item: Append "# Design" section before "# End of Shaped Work Contract"
- Backlog frontmatter: `status: shaped` → `status: designed`
- docs/context/system_architecture.md (if architecture changes)
- docs/decisions/ADR-{N}.md (if significant decision)
- **Spec (if spec_ref exists):** Append or update "## Design Constraints" section in the spec body (see below)

> **Note:** Design content is appended directly to the backlog item rather than creating a separate analysis file. This keeps all work context in one living document.

**SPEC UPDATE (when spec_ref is present):**

After completing the design, update the linked spec:

1. **Append "## Design Constraints" section** to the spec body (or update if it already exists):
   ```markdown
   ## Design Constraints
   <!-- Updated by /design on {YYYY-MM-DD} from {backlog-item-id} -->
   - {constraint 1 from design}
   - {constraint 2 from design}
   ```
2. **Refine acceptance_criteria in frontmatter** if the design reveals new behavioral requirements:
   - Append new AC entries (never remove or rewrite existing ones)
   - New ACs get `status: pending`
   - Preserve original AC numbering; new ACs continue the sequence
3. **Do NOT change spec status** — the spec stays `active`

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
