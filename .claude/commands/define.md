# /define [input]

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
- docs/specs/{domain}/ directories (to discover existing specs and domains)
- docs/decisions/ADR-*.md (scan for existing ADRs relevant to the domain or topic)

**RECALL:**
- Past shaping on related topics
- Related constraints and decisions

---

## Context Writing

**WRITE:**
- docs/backlog/{priority}-{topic}.md
- docs/decisions/ADR-{NNN}-{slug}.md (proposed ADR, when architectural choice detected — see below)

**UPDATE:**
- docs/context/current_work.md
- Backlog frontmatter: add `spec_ref: docs/specs/{domain}/{capability}.md`
- Backlog frontmatter: add `adr_refs` array if proposed ADRs were created

---

## Output

Produces a **Shaped Work Contract** containing:
1. Problem Frame - What we're solving and why
2. Appetite - Time budget and boundaries
3. Solution Sketch - Rough approach (not detailed spec)
4. Rabbit Holes - What to avoid
5. Acceptance Criteria - How we'll know it's done
6. Behavioral Delta - What existing spec behavior is changing (when applicable)
7. Handoff - Ready for design?

---

## Spec Lifecycle Behavior

When `/define` shapes work, it also manages the persistent spec for the capability being shaped.

### Behavioral Delta (when changing an existing capability)

When the work being shaped modifies an existing capability that has a spec:

1. **Discover the existing spec:**
   - If `spec_ref` is provided in the input: Load that spec directly
   - If no `spec_ref`: Search `docs/specs/{domain}/` for a spec matching the capability. Present matches to the user for confirmation:
     > Found spec that may cover this capability: docs/specs/{domain}/{capability}.md — is this the right spec? [Y/n/other path]
   - If no matching spec found: Skip delta (this is new capability work)
2. **Document the behavioral delta** in the shaped work contract as a dedicated section:
   ```markdown
   ## Behavioral Delta

   **Spec:** docs/specs/{domain}/{capability}.md

   ### Current Behavior
   - AC-{N}: {quote the current AC description from the spec}
   - AC-{M}: {quote the current AC description from the spec}

   ### Proposed Changes
   - AC-{N}: {what this AC will change to, and why}
   - AC-{M}: {what this AC will change to, and why}
   - AC-NEW: {new acceptance criteria being added, and why}

   ### Rationale
   {Why these changes are needed — from discovery findings or problem statement}
   ```
3. **Tag affected ACs:** Reference which spec ACs will be modified, added, or deprecated
4. **Set `spec_ref`** on the backlog item linking to the spec that will be updated

### New Capability (no existing spec)

When shaping work for a capability that has no existing spec:

1. **Ask the user for the domain:** Present the existing domains found in `docs/specs/` subdirectories and ask:
   > Which domain does this capability belong to? Existing domains: [{list}]. Or enter a new domain name.
2. **Create the spec** at `docs/specs/{domain}/{capability}.md` with `status: active`, `domain: {domain}`, and acceptance_criteria from the shaped contract
3. **Link the backlog item:** Add `spec_ref: docs/specs/{domain}/{capability}.md` to the backlog item frontmatter
4. **Create domain directory:** If `docs/specs/{domain}/` does not exist, create it

---

## Architectural Decision Detection

While shaping work, `/define` checks whether the behavioral delta involves an architectural choice — a decision about HOW to build, not just WHAT changes.

### Threshold Check

Create a proposed ADR ONLY when BOTH conditions are true:
1. **Multiple viable alternatives exist** — There is a genuine choice between technical approaches
2. **Hard to reverse OR affects multiple domains** — The decision has lasting consequences

### Proposed ADR Workflow

When the threshold is met:

1. **Determine next ADR number** by scanning `docs/decisions/ADR-*.md` (increment highest found; start at ADR-001 if none exist beyond ADR-000)
2. **Create** `docs/decisions/ADR-{NNN}-{slug}.md` with `status: proposed`
3. **Fill in Context section** — What is the issue motivating this decision? (captured while the problem is fresh)
4. **Fill in Alternatives Considered table** — Options with pros/cons (captured while alternatives are being evaluated)
5. **Leave Decision section as placeholder:** "To be determined by /design"
6. **Leave Consequences section as placeholder:** "To be assessed after decision"
7. **Add `adr_refs`** to the backlog item frontmatter

### Example

```
/define docs/analysis/20260127_discover_notifications.md
> ...
> Architectural choice detected: How to deliver real-time notifications
> Alternatives: WebSockets, Server-Sent Events, Polling
> This is hard to reverse (protocol choice affects all clients)
>
> Created: docs/decisions/ADR-004-real-time-notification-delivery.md (proposed)
> adr_refs added to backlog item
```

### When NOT to Create a Proposed ADR

- The change is purely behavioral (WHAT changes, not HOW)
- Only one viable approach exists
- The choice is easily reversible
- The decision is scoped to a single component's internals

---

## Sub-Commands

| Command | Purpose |
|---------|---------|
| `/define:appetite [input]` | Just appetite and boundaries |
| `/define:risks [input]` | Focus on assumption/risk identification |
| `/define:options [input]` | Generate options without full contract |

---

## Usage Examples

```
/define docs/analysis/20251203_discover_auth.md
> [Shaper produces Shaped Work Contract]
> Saved to docs/backlog/P2-auth-improvements.md
>
> Found spec: docs/specs/identity/token-authentication.md
>
> ## Behavioral Delta
> **Spec:** docs/specs/identity/token-authentication.md
> ### Current Behavior
> - AC-2: Tokens expire after 15 minutes with no renewal mechanism
> ### Proposed Changes
> - AC-2: Tokens expire after 1 hour with sliding window refresh
> - AC-NEW: Refresh token rotation with 7-day absolute expiry
> ### Rationale
> Users are frustrated by frequent re-authentication. Discovery found 40% of
> support tickets relate to expired sessions.
>
> spec_ref set in backlog item
>
> Appetite: 2 weeks
> Next: /handoff define design

/define "add payment processing"
> [Shaper produces Shaped Work Contract]
>
> No existing spec found for this capability.
> Which domain does this capability belong to?
> Existing domains: identity, workflow
> > billing
>
> Created: docs/specs/billing/payment-processing.md (status: active)
> spec_ref set in backlog item
> Saved to docs/backlog/P1-payment-processing.md

/define:appetite "add dark mode"
> Appetite assessment: Small batch (3 days max)
> Boundaries: CSS variables only, no component changes
```

---

## Routing

After defining:
- If ready for technical design: `/handoff define design`
- If appetite unclear: `/define:appetite` then full `/define`
- If high risk: Flag for Navigator review

---

## Notes

- Sets boundaries BEFORE deep technical work
- Prevents scope creep through explicit appetite
- Creates clear contract between discovery and delivery
- Anti-pattern: defining as detailed specification
- Behavioral delta makes change proposals explicit and traceable

---

## Workshop Mode (`--workshop`)

**MANDATORY: When `$ARGUMENTS` contains `--workshop`, you MUST follow the interactive workshop phases below instead of producing a batch Shaped Work Contract. The final output is identical — a Shaped Work Contract — but the user participates in key tradeoff decisions along the way.**

When `$ARGUMENTS` does NOT contain `--workshop`, ignore this entire section and follow the standard batch flow above.

---

### Workshop Phase 1: Problem Framing

Present 2-3 reframings of the problem and let the user pick the direction.

1. **Read** the input (discovery document, backlog item, or problem statement)
2. **Generate 2-3 problem reframings** — each should be solution-free and articulate a different angle on the underlying problem
3. **Use AskUserQuestion** to present the options:
   - Each option is a 1-sentence problem statement
   - Include a brief note on what this framing emphasizes (e.g., "Emphasizes user friction" vs "Emphasizes operational cost")
4. **Capture** the user's choice — this becomes the Problem/Opportunity Statement in the final contract

**Output:** Locked problem framing for the contract.

---

### Workshop Phase 2: Appetite Explorer

**MANDATORY: You MUST produce a viewable HTML artifact. Do NOT describe appetite tiers in a text table.**

1. **Analyze** the problem framing and generate concrete scope items that could fit in each appetite tier
2. **Write** an HTML file to the scratchpad directory using the Write tool:

   **File path:** `{scratchpad}/workshop/appetite-explorer.html`

   The HTML file MUST be self-contained (inline CSS, no external dependencies) and include:

   **Three-column layout: Small Batch (1-2 days) | Medium Batch (3-5 days) | Big Batch (1-2 weeks)**

   Each column contains:
   - **Tier header** with time budget
   - **Scope items** as a list — each item is a concrete capability or change (not vague categories)
   - **Color coding per item:**
     - Green (`#22c55e`) — Included in this tier
     - Yellow (`#eab308`) — Stretch / maybe fits
     - Red (`#ef4444`) — Excluded from this tier
   - **Risk indicator** at column footer: Low / Medium / High risk for this tier
   - **Tradeoff summary** at bottom: "You get X but not Y"

   Layout: Clean card-based grid with clear tier headers. Minimum 300px per column. White or light gray background. Each scope item as a pill or row with its color indicator.

3. **Tell the user** to open the file: `open {scratchpad}/workshop/appetite-explorer.html`
4. **Use AskUserQuestion:** "Which appetite tier fits this work?" with options for each tier plus "Adjust scope" to remix
5. If user selects "Adjust scope" or uses "Other": **Regenerate the HTML** with adjusted items and tell user to refresh

**Output:** Locked appetite tier and scope items for the contract.

---

### Workshop Phase 3: Option Exploration

**MANDATORY: You MUST produce a viewable HTML artifact. Do NOT describe options in a text table.**

1. **Generate 2-3 solution directions** — each is a rough approach (not detailed spec), scoped to the chosen appetite tier
2. **Write** an HTML file to the scratchpad directory using the Write tool:

   **File path:** `{scratchpad}/workshop/option-comparison.html`

   The HTML file MUST be self-contained (inline CSS) and show **cards side-by-side**, one per option:

   Each option card includes:
   - **Option name** and 1-sentence description
   - **Evaluation bars** (visual, not text) for these dimensions:
     - Effort — Low / Medium / High (green → yellow → red bar)
     - Risk — Low / Medium / High
     - Strategic Alignment — Low / Medium / High
     - Dependencies — None / Few / Many
     - Reversibility — Easy / Moderate / Hard
   - Each bar is a horizontal colored bar showing the rating visually
   - **Bottom line:** 1-sentence tradeoff summary (e.g., "Fast to build but harder to extend later")

   Layout: Cards sit side-by-side for direct visual comparison. Minimum 280px per card.

3. **Tell the user** to open the file: `open {scratchpad}/workshop/option-comparison.html`
4. **Use AskUserQuestion:** "Which direction?" with options for each approach plus "Remix"
5. If user wants a remix: **Regenerate the HTML** with refined options

**Output:** Locked solution direction for the contract.

---

### Workshop Phase 4: Scope Negotiation

Present the in/out boundary proposals and let the user adjust.

1. **Based on** the chosen appetite and solution direction, generate:
   - **In scope** — concrete list of what's included
   - **No-gos** — explicitly excluded items
   - **Fixed elements** — things that cannot change
   - **Rabbit holes** — risks to avoid
2. **Use AskUserQuestion:** "Do these boundaries look right?" with options:
   - "Yes, proceed to contract"
   - "Adjust in-scope items"
   - "Adjust no-gos"
   - "Adjust both"
3. If user wants adjustments: Discuss adjustments, then re-present boundaries via AskUserQuestion until confirmed

**Output:** Locked boundaries for the contract.

---

### Workshop Phase 5: Consolidation

Write the standard Shaped Work Contract using all decisions captured in Phases 1-4.

1. **Write** the Shaped Work Contract to `docs/backlog/{priority}-{topic}.md` using the same template and format as batch mode
2. The contract MUST include all standard sections (Problem, Evidence, Appetite, Goals, Risks, Options, Dependencies, Routing)
3. **Additionally**, note in the contract narrative which decisions were made interactively:
   - "Problem framing chosen from 3 alternatives in workshop"
   - "Appetite set to {tier} after reviewing scope explorer"
   - "Solution direction chosen from {N} options"
4. Follow all standard Spec Lifecycle Behavior and Architectural Decision Detection from the batch flow
5. **Report completion** as in batch mode

**Output:** Standard Shaped Work Contract — identical format to batch mode.

ARGUMENTS: $ARGUMENTS
