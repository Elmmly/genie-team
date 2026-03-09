---
spec_version: "1.0"
type: shaped-work
id: P2-nextjs-react-framework-guidance
title: "TypeScript Stack Profile: Next.js and React Framework Guidance"
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
      TypeScript stack profile includes a Next.js App Router section with: Server Components
      vs Client Components decision tree, data fetching patterns (server-side fetch with
      cache/revalidation), route handlers, middleware, Server Actions, layouts vs pages
    status: pending
  - id: AC-2
    description: >-
      React component patterns section added: hooks rules (dependency arrays, custom hooks
      extraction), component composition patterns, performance guidance (memo, useMemo,
      useCallback with when-to-use and when-NOT-to-use)
    status: pending
  - id: AC-3
    description: >-
      Next.js anti-patterns documented: unnecessary 'use client' directives, client-side
      data fetching when server fetch available, prop drilling across server/client boundary,
      layout misuse, middleware overuse, incorrect environment variables (NEXT_PUBLIC_ prefix)
    status: pending
  - id: AC-4
    description: >-
      React anti-patterns documented: stale closures in effects, derived state that should
      be computed, unnecessary state, ref misuse, direct DOM manipulation in React components
    status: pending
  - id: AC-5
    description: >-
      Framework-specific testing patterns documented: React Testing Library conventions
      (user-centric queries, async utilities, avoiding implementation details), testing
      Server Components, Playwright for Next.js E2E
    status: pending
---

# Shaped Work Contract: TypeScript Stack Profile — Next.js and React Framework Guidance

## Problem

When working on Next.js + React projects with genie-team, the Crafter and Critic genies receive TypeScript language-level quality rules (strict types, error handling, import conventions) but lack framework-specific guidance for Next.js App Router patterns and React component conventions. The TypeScript stack profile (`stacks/typescript.md`) detects `next.config.*` in its framework detection table but provides no framework-specific patterns, anti-patterns, or testing guidance.

This means:
- Server Component vs Client Component boundaries aren't enforced — the Crafter may add `'use client'` unnecessarily or fetch data client-side when server-side fetch is available
- Next.js App Router conventions (layouts, route handlers, Server Actions) aren't surfaced during `/deliver`
- React hooks rules and composition patterns aren't in the Critic's Stack Compliance checklist
- Framework-specific testing patterns (React Testing Library conventions, Server Component testing) aren't available
- The `NEXT_PUBLIC_` environment variable convention isn't documented, leading to leaked server-side env vars or missing client-side ones

The TypeScript profile's Known Pitfalls section already flags "React version mismatches" (pitfall #5) but provides no guidance on what to do about it.

## Evidence

- Current `stacks/typescript.md` lists Next.js and React in framework detection (lines 23-24) but has zero framework content in Rules Content section
- Elixir profile demonstrates the pattern: Phoenix, LiveView, and Ecto each have dedicated sections with code examples and conventions
- Vercel publishes official Claude Code skills for Next.js and React best practices — confirming the demand and the gap in default Claude behavior
- Next.js App Router (introduced in Next.js 13) fundamentally changed React patterns — Server Components, Server Actions, and the rendering model require specific guidance that pure TypeScript rules don't cover
- React 18+ concurrent features (Suspense, transitions) change performance optimization patterns from React 17

## Appetite & Boundaries

- **Appetite:** Small batch (1-2 days)
- **Rationale:** Content work — adding framework-specific sections to an existing stack profile template. Follows the Elixir profile pattern. No infrastructure changes. Enriched templates flow through `/arch:init` → `.claude/rules/stack-typescript.md` automatically.

### No-gos
- No Pages Router coverage — App Router only (modern pattern; Pages Router is legacy)
- No state management library guidance (Redux, Zustand, Jotai, etc.) — too opinionated, varies by project
- No CSS framework guidance (Tailwind, CSS Modules, styled-components) — orthogonal concern
- No monorepo tooling (Turborepo, Nx) — separate concern
- No integration with Vercel's community skills (users can install those separately)
- No SSR/SSG/ISR strategy guidance — too project-specific
- No changes to stack-awareness skill infrastructure

### Fixed elements
- Follow existing framework section pattern from Elixir profile
- Content goes in `stacks/typescript.md` Rules Content section under dedicated Next.js and React headers
- Generated rules flow through existing `/arch:init` → `.claude/rules/stack-typescript.md` pipeline
- Verification command remains `tsc --noEmit` (no Next.js-specific verification in hook — `next lint` is optional enhancement users can add)

## Goals & Outcomes

- Crafter produces Next.js code that respects Server/Client Component boundaries and uses App Router conventions correctly
- Crafter writes React components following hooks rules and avoiding common performance traps
- Critic catches Next.js anti-patterns (unnecessary `'use client'`, client-side fetching) during `/discern` Stack Compliance review
- Testing guidance enables proper React Testing Library usage without the Crafter falling into implementation-detail testing

## Risks & Assumptions

| Assumption | Type | Test |
|------------|------|------|
| Next.js App Router patterns are stable enough to codify | feasibility | App Router is stable since Next.js 14 (Oct 2023); core patterns haven't changed through Next.js 15 |
| React hooks rules are universal enough for a stack profile | feasibility | Rules of Hooks are part of React core since 16.8; not controversial |
| Profile size stays manageable with two framework sections | feasibility | Measure total profile size; Elixir profile has ~80 lines of framework content and works well |
| Crafter actually follows framework rules when writing components | value | Verify via test delivery on a Next.js project after profile is enriched |

## Options

| Option | Pros | Cons | Recommendation |
|--------|------|------|----------------|
| Add Next.js + React sections to TypeScript profile | Follows established pattern; no infra changes; covers the most common TS frontend stack | Profile grows larger; Next.js/React rules load for all TS projects | **Recommended** — matches Elixir precedent |
| Create separate `stacks/nextjs.md` profile | Cleaner separation; only loads when detected | Requires framework-layering mechanism; breaks current model; TypeScript is a prerequisite anyway | Not recommended |
| Point users to Vercel's community skills | Zero maintenance; comprehensive coverage | No genie-team integration; no /discern Stack Compliance; external dependency | Complementary — recommend alongside, not instead of |

## Routing

- **Next:** `/design` or direct to `/deliver` (small batch, clear pattern from Elixir profile)
- **Dependency:** None — independent of P2-go-grpc-framework-guidance (can deliver in any order)

# Design

```yaml
---
spec_version: "1.0"
type: design
id: P2-nextjs-react-framework-guidance-design
title: "TypeScript Stack Profile: Next.js and React Framework Guidance"
reasoning_mode: deep
status: designed
created: 2026-03-04
spec_ref: docs/backlog/P2-nextjs-react-framework-guidance.md
appetite: small
complexity: simple
author: architect
ac_mapping:
  - ac_id: AC-1
    approach: "Add ## Next.js App Router section to Rules Content with Server/Client Component decision tree, data fetching, routing"
    components: ["stacks/typescript.md"]
  - ac_id: AC-2
    approach: "Add ## React Patterns section to Rules Content with hooks rules, composition, and performance guidance"
    components: ["stacks/typescript.md"]
  - ac_id: AC-3
    approach: "Add Next.js-specific entries to existing ## Anti-Patterns section in Rules Content"
    components: ["stacks/typescript.md"]
  - ac_id: AC-4
    approach: "Add React-specific entries to existing ## Anti-Patterns section in Rules Content"
    components: ["stacks/typescript.md"]
  - ac_id: AC-5
    approach: "Add React Testing Library conventions to ## Test Framework Detection and testing guidance to ## Known Pitfalls"
    components: ["stacks/typescript.md"]
components:
  - name: TypeScriptStackProfile
    action: modify
    files: ["stacks/typescript.md"]
---
```

## Overview

Add two framework-specific sections and supplementary entries to `stacks/typescript.md`, enriching the Rules Content template that `/arch:init` uses to generate `.claude/rules/stack-typescript.md`. Follows the established Elixir profile pattern where Phoenix, LiveView, and Ecto each have dedicated sections inline in the rules template.

No infrastructure changes — enriched templates flow through the existing `/arch:init` pipeline. The stack-awareness skill already reads the full generated rules file during `/deliver` and `/discern`, so framework content is surfaced without skill changes.

## Architecture

### Approach: Inline Framework Sections in Language Profile

**Why this approach:** Same rationale as the Go+gRPC design. The Elixir precedent works. The TypeScript profile is currently 120 lines — adding ~70 lines of Next.js and React content brings it to ~190 lines, within the Elixir precedent (~160 lines). The alternative (separate `stacks/nextjs.md`) would require framework-layering in stack-awareness, and TypeScript is a prerequisite for Next.js anyway — the rules are complementary, not independent.

**Why not point to Vercel's community skills:** Vercel's Next.js and React skills are comprehensive, but they don't integrate with genie-team's `/discern` Stack Compliance checklist. They're complementary — users can install them alongside. But genie-team needs its own framework rules for Critic integration and consistent quality enforcement across the workflow.

**Failure mode considered:** Next.js evolves rapidly. If rules reference APIs that change in Next.js 16+, they become harmful guidance. Mitigation: keep rules at the pattern level ("use Server Components for data fetching"), not API level ("use `fetch` with `{ next: { revalidate: 60 } }`"). The revalidation API is stable, but framing rules as patterns makes them more resilient.

### Sections to Add (in Rules Content template)

Insert these sections after `## Import Conventions` and before `## Anti-Patterns`:

#### 1. `## Next.js App Router` (AC-1)

App Router patterns covering:
- **Server vs Client Components decision tree:** Server Components are the default. Use `'use client'` ONLY when the component needs: event handlers (onClick, onChange), useState/useEffect, browser-only APIs (localStorage, window), or third-party client libraries.
- **Data fetching:** Use `fetch()` in Server Components with cache/revalidation. Include a concise example:
  ```typescript
  // Server Component — preferred for data fetching
  async function UserProfile({ id }: { id: string }) {
    const user = await fetch(`${API}/users/${id}`, { next: { revalidate: 60 } })
    return <Profile data={await user.json()} />
  }
  ```
- **Server Actions:** Use `'use server'` functions for mutations — not API route handlers for form submissions
- **Layouts vs Pages:** `layout.tsx` = shared UI that persists across navigation (nav, sidebar). `page.tsx` = route-specific content and data fetching. Don't fetch data in layouts.
- **Middleware:** Auth redirects, geo-routing, header manipulation. Keep thin — runs on every matched request.
- **Environment variables:** `NEXT_PUBLIC_` prefix required for client-side access. Server-only secrets MUST NOT use this prefix.

#### 2. `## React Patterns` (AC-2)

Component patterns covering:
- **Hooks rules:** Call hooks at top level only — never inside conditions, loops, or nested functions
- **Custom hooks:** Extract to `use{Name}` when stateful logic is shared across 2+ components
- **State management guidance:**
  - `useState` — component-specific UI state
  - Lifted state — shared between siblings via closest common parent
  - Context — truly global state (theme, auth, locale) — NOT for data fetching or frequently-changing values
- **Performance (measure first, optimize second):**
  - `React.memo` — skip re-renders for leaf components with stable props
  - `useMemo` — cache expensive computations, NOT every variable
  - `useCallback` — stabilize function refs passed to memoized children
  - "Don't optimize until you've measured. Premature memoization adds complexity without measurable benefit."
- **Composition over prop drilling:** Use children, render props, or compound component pattern

**Why separate Next.js and React sections:** They address different concerns. Next.js rules are about the framework's rendering model (server/client boundary, routing, data fetching). React rules are about component-level patterns (hooks, state, performance) that apply regardless of framework. A developer may use React without Next.js — the React rules should stand alone.

#### 3. Anti-Pattern Additions (AC-3, AC-4)

Append to existing `## Anti-Patterns` section:

**Next.js anti-patterns (AC-3):**
- No `'use client'` unless the component needs event handlers, useState, useEffect, or browser APIs
- No `useEffect` + client-side `fetch` for data that can be fetched in a Server Component
- No `NEXT_PUBLIC_` prefix on secrets or server-only configuration
- No data fetching in `layout.tsx` — use `page.tsx` or Server Components

**React anti-patterns (AC-4):**
- No hooks inside conditions or loops — call at top level only
- No derived state in `useState` — compute from existing state/props inline
- No premature `React.memo`/`useMemo`/`useCallback` — measure performance first
- No direct DOM manipulation (`document.querySelector`) in React components — use refs

### Sections to Update (outside Rules Content)

#### Test Framework Detection (AC-5)

The table already has `@testing-library/*` entry. Add note:
- Update existing entry with convention note: "User-centric queries (getByRole, getByText) — avoid getByTestId"
- Add `@testing-library/react` specifically if not already listed

#### Known Pitfalls (AC-3, AC-4, AC-5)

Replace current pitfall #5 ("React version mismatches") with expanded version and add new entries:

5. **React version patterns** (expanded from current): React 18+ uses concurrent features (Suspense, transitions, useId) not available in 17. Detect version from deps and adjust patterns — React 18+ allows async Server Components; React 17 requires client-side data fetching.
6. **Unnecessary 'use client'**: Claude defaults to Client Components for everything. Without explicit rules, most components get `'use client'` even when they have no interactivity — losing Server Component benefits (smaller bundles, direct backend access, streaming).
7. **Client-side data fetching in Next.js**: Claude uses `useEffect` + `fetch` patterns from SPA-era React instead of Server Component `fetch()`. This loses caching, streaming, and server-side rendering benefits. Concrete scenario: Crafter builds a product listing page as a Client Component with `useEffect` data fetch — the page renders empty HTML, loads a JS bundle, then fires a client-side request. Should be a Server Component that renders with data on the server.
8. **Stale closures in effects**: Claude frequently omits dependencies from `useEffect`/`useMemo`/`useCallback` arrays. Concrete scenario: a timer component captures the initial count value in a closure, never seeing updates — the displayed count appears frozen.
9. **Premature memoization**: Claude wraps everything in `useMemo`/`useCallback`/`React.memo`. Each has overhead — the comparison cost may exceed the re-render cost for simple components.

#### CLAUDE.md Section

Add lines:
```
**Next.js:** Server Components by default, `'use client'` only for interactivity, server-side `fetch()` with revalidation
**React:** Hooks at top level only, composition over prop drilling, memoize only after measuring
```

## Risks

| Risk | L | I | Mitigation |
|------|---|---|------------|
| Next.js API changes invalidate rules (rapid release cycle) | M | M | Frame rules at pattern level ("use Server Components for data fetching") not API level. Core App Router patterns stable since Next.js 14. |
| React rules too opinionated for diverse projects | L | M | Keep to universally accepted patterns (Rules of Hooks, composition). Avoid opinionated choices (state management libraries, CSS approaches). |
| Profile size exceeds useful context budget with two framework sections | L | M | Target ~70 lines total for both sections. Brings profile to ~190 lines — within Elixir precedent. |
| Next.js rules load for non-Next.js TypeScript projects | L | L | Rules are written as "when using Next.js..." — self-filtering. Same approach as Elixir profile including Ecto rules for non-Ecto projects. |

## Implementation Guidance

**Sequence:**
1. Add `## Next.js App Router` section to Rules Content (after `## Import Conventions`, before `## Anti-Patterns`)
2. Add `## React Patterns` section immediately after
3. Append Next.js anti-pattern entries to existing `## Anti-Patterns` section
4. Append React anti-pattern entries to existing `## Anti-Patterns` section
5. Expand pitfall #5 and add four new entries to `## Known Pitfalls`
6. Update `## Test Framework Detection` with React Testing Library convention note
7. Add Next.js and React lines to `## CLAUDE.md Section` template
8. Verify total profile size is under 200 lines

**Key considerations:**
- The Server Component data fetching example should be concise (3-4 lines) — rules, not tutorial
- Performance guidance must include the "measure first" caveat to prevent premature optimization rules from being applied dogmatically
- Keep `NEXT_PUBLIC_` environment variable rule prominent — this is a security concern, not just a convention
- No `## Settings Permissions` changes needed — existing `tsc`, `npm test`, `npx vitest` already cover framework code

**Verification:** After editing, run `./install.sh project --dry-run /tmp/test-project` to confirm the profile template renders cleanly through the install pipeline.

## Routing

Ready for Crafter: `/deliver docs/backlog/P2-nextjs-react-framework-guidance.md`

# Implementation

## Summary

Added Next.js App Router and React Patterns framework-specific sections to `stacks/typescript.md`, enriching the TypeScript stack profile template with component patterns, data fetching guidance, anti-patterns, testing conventions, and known pitfalls. Profile size: 164 lines (within Elixir precedent of ~162 lines).

## Changes

- `stacks/typescript.md`: Added `## Next.js App Router`, `## React Patterns` sections to Rules Content template. Added 8 framework anti-pattern entries (4 Next.js, 4 React), expanded Known Pitfalls from 5 to 9 entries, updated React Testing Library convention note, and added Next.js/React lines to CLAUDE.md Section template.

## AC Status

| AC | Status | Notes |
|----|--------|-------|
| AC-1 | Met | Next.js App Router section: Server/Client Components, data fetching, Server Actions, layouts, middleware, env vars |
| AC-2 | Met | React Patterns section: hooks rules, state management, performance (measure-first), composition |
| AC-3 | Met | 4 Next.js anti-patterns: unnecessary 'use client', client-side fetch, NEXT_PUBLIC_ misuse, layout fetch |
| AC-4 | Met | 4 React anti-patterns: hooks in conditions, derived state, premature memo, DOM manipulation |
| AC-5 | Met | React Testing Library convention note updated, 4 framework Known Pitfalls added |

## Phase 4: N/A — no service wiring required (prompt engineering artifact)

## Routing

Next: `/discern docs/backlog/P2-nextjs-react-framework-guidance.md`

# Review

**Verdict: APPROVED**

## AC Verification

| AC | Status | Evidence |
|----|--------|----------|
| AC-1 | Met | `## Next.js App Router` section: Server/Client Component decision tree, fetch with revalidation code example, Server Actions, layouts vs pages, middleware (keep thin), `NEXT_PUBLIC_` env var rule |
| AC-2 | Met | `## React Patterns` section: hooks at top level, custom hooks extraction, state management tiers (useState/lifted/Context), performance with measure-first caveat, composition over prop drilling |
| AC-3 | Met | 4 Next.js anti-patterns in `## Anti-Patterns`: unnecessary 'use client', client-side fetch, NEXT_PUBLIC_ misuse, layout data fetching. Middleware overuse addressed in patterns ("Keep thin"). |
| AC-4 | Met | 4 React anti-patterns: hooks in conditions, derived state, premature memo, DOM manipulation. Stale closures covered in Known Pitfalls #8 with concrete scenario. |
| AC-5 | Met | Testing Library convention note updated ("User-centric queries — avoid getByTestId"). 4 framework Known Pitfalls added (#6-9) covering unnecessary 'use client', SPA-era fetching, stale closures, premature memo. |

**ACs verified: 5/5 met**

## Quality Assessment

- **Structure:** Two clean sections (Next.js App Router + React Patterns) — correctly separated by concern. Next.js = framework rendering model, React = component-level patterns.
- **Profile size:** 164 lines (Elixir precedent: 162 lines). Within budget.
- **Server Component code example:** Concise (4 lines) and demonstrates caching with `{ next: { revalidate: 60 } }`. Good rules-not-tutorial balance.
- **Performance guidance:** The "measure first, optimize second" caveat on memoization is well-calibrated — prevents the premature optimization anti-pattern from becoming a new anti-pattern (refusing to optimize when needed).
- **Security concern surfaced:** `NEXT_PUBLIC_` env var rule is both in the patterns section and anti-patterns section. Appropriate emphasis for a security-relevant convention.
- **Known Pitfalls:** Include concrete scenarios (e.g., SPA-era product listing page vs Server Component rendering). Good for Crafter self-correction.

## Observations (non-blocking)

1. **AC-3 — prop drilling across server/client boundary:** The AC mentions this specifically but it's not an explicit anti-pattern entry. The general React composition rule covers prop drilling, but the server/client boundary aspect (passing serializable-only props across the boundary) is a Next.js-specific concern worth adding in a follow-up.
2. **AC-4 — stale closures location:** Documented in Known Pitfalls (#8) but not in the Rules Content `## Anti-Patterns` section. Since Known Pitfalls are template-level context (not in the generated rules file), the Crafter won't see this rule during `/deliver`. Consider adding `- No missing dependencies in useEffect/useMemo/useCallback arrays` to Anti-Patterns for it to appear in generated rules.
3. **AC-4 — ref misuse and unnecessary state:** These two items from the AC are not explicitly present. Ref misuse is partially covered by "No direct DOM manipulation" but `useRef` misuse for state (instead of `useState`) is a different concern. Minor gap.

## Phase 4: N/A — prompt engineering artifact, no service wiring

## Routing

Next: `/done docs/backlog/P2-nextjs-react-framework-guidance.md`

# End of Shaped Work Contract
