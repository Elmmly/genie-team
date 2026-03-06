# TypeScript Stack Profile

Stack profile template for TypeScript projects. Used by `/arch:init` to generate project-specific configuration.

## Detection

| Indicator | Source |
|-----------|--------|
| `tsconfig.json` | Primary indicator |
| `package.json` → `typescript` | Version source |
| `package.json` → `type: "module"` | ESM vs CJS |

## Version Detection

```
jq -r '.devDependencies.typescript // .dependencies.typescript // "unknown"' package.json
```

## Framework Detection

| File/Dependency | Framework |
|----------------|-----------|
| `next.config.*` | Next.js |
| `nuxt.config.*` | Nuxt |
| `angular.json` | Angular |
| `svelte.config.*` | SvelteKit |
| `remix.config.*` or `@remix-run/*` | Remix |
| `express` in deps | Express.js |
| `fastify` in deps | Fastify |
| `@nestjs/core` in deps | NestJS |

## Rules Content

Generate as `.claude/rules/stack-typescript.md`:

```markdown
# TypeScript Stack Rules

## Version: TypeScript {version}

## Strict Type Safety
- Enable `strict: true` in tsconfig.json
- NEVER use `any` — use `unknown` with type guards instead
- NEVER use `@ts-ignore` or `@ts-expect-error` — fix the type error
- Use discriminated unions for state modeling
- Prefer `interface` for object shapes, `type` for unions/intersections

## Modern Patterns
- Use `satisfies` operator for type-safe config objects
- Use `const` assertions for literal types: `as const`
- Use template literal types for string patterns
- Prefer `Map`/`Set` over plain objects for dynamic keys

## Error Handling
- Use typed error classes extending `Error`
- Always set `cause` on wrapped errors: `new Error('msg', { cause: err })`
- Use `unknown` for catch clause variables (TS 4.4+)
- Never throw strings — always throw Error objects

## Import Conventions
- Use ESM imports (`import`/`export`), not CommonJS (`require`)
- Use path aliases from tsconfig for deep imports
- Prefer named exports over default exports

## Next.js App Router
- **Server Components** (default) — use for data fetching, backend access, sensitive logic
- **Client Components** (`'use client'`) — ONLY when the component needs: event handlers, useState, useEffect, or browser APIs
- Data fetching in Server Components with caching:
  ```typescript
  // Server Component — preferred
  async function UserList() {
    const users = await fetch('/api/users', { next: { revalidate: 60 } })
    return <List data={await users.json()} />
  }
  ```
- **Server Actions** (`'use server'`) — use for mutations, not API route handlers for form submissions
- **Layouts** (`layout.tsx`) — shared UI that persists across navigations (nav, sidebar). Do NOT fetch data in layouts.
- **Pages** (`page.tsx`) — route-specific content and data fetching
- **Middleware** (`middleware.ts`) — auth redirects, geo-routing, headers. Keep thin — runs on every matched request.
- **Environment variables:** `NEXT_PUBLIC_` prefix required for client-side access. Server-only secrets MUST NOT use this prefix.

## React Patterns
- **Hooks rules:** Call hooks at the top level only — never inside conditions, loops, or nested functions
- **Custom hooks:** Extract reusable stateful logic into `use{Name}` hooks when shared across 2+ components
- **State management:**
  - `useState` — component-specific UI state
  - Lifted state — shared between siblings via closest common parent
  - Context — truly global state (theme, auth, locale) — NOT for data fetching or frequently-changing values
- **Performance (measure first, optimize second):**
  - `React.memo` — skip re-renders for leaf components with stable props
  - `useMemo` — cache expensive computations, NOT every variable
  - `useCallback` — stabilize function refs passed to memoized children
  - Don't optimize until you've measured. Premature memoization adds complexity without measurable benefit.
- **Composition:** Prefer children, render props, or compound components over prop drilling

## Anti-Patterns
- No `any` type — use `unknown` with narrowing
- No `@ts-ignore` — fix the underlying type error
- No `as` type assertions without runtime validation
- No `!` non-null assertions — use proper null checks
- No `== null` without `strictNullChecks` enabled
- No `'use client'` unless the component needs event handlers, useState, useEffect, or browser APIs
- No `useEffect` + client-side `fetch` for data that can be fetched in a Server Component
- No `NEXT_PUBLIC_` prefix on secrets or server-only configuration
- No data fetching in `layout.tsx` — use `page.tsx` or Server Components
- No hooks inside conditions or loops — call at top level only
- No derived state in `useState` — compute from existing state/props inline
- No premature `React.memo`/`useMemo`/`useCallback` — measure performance first
- No direct DOM manipulation (`document.querySelector`) in React components — use refs

## Verification
After editing TypeScript files, run: `tsc --noEmit`
```

## CLAUDE.md Section

Append to `## Tech Stack` in CLAUDE.md:

```markdown
### TypeScript {version}
**Build & verify:** `tsc --noEmit && npm test`
**Strict types:** `strict: true` in tsconfig — no `any`, no `@ts-ignore`
**Error handling:** Typed error classes with `cause` chaining
**Imports:** ESM (`import`/`export`), path aliases, named exports
**Next.js:** Server Components by default, `'use client'` only for interactivity, server-side `fetch()` with revalidation
**React:** Hooks at top level only, composition over prop drilling, memoize only after measuring
```

## Settings Permissions

Merge into `.claude/settings.json` `permissions.allow`:

```json
["Bash(tsc *)", "Bash(npx tsc*)", "Bash(npm test*)", "Bash(npm run *)", "Bash(npx vitest*)", "Bash(npx eslint*)"]
```

## Hook Verification

File extension match: `.ts`, `.tsx`
Verification command: `npx tsc --noEmit`
Fallback: `npx tsc --noEmit --pretty 2>&1 | head -20`

## Test Framework Detection

| Dependency | Framework | Command |
|-----------|-----------|---------|
| `vitest` | Vitest | `npx vitest run` |
| `jest` | Jest | `npx jest` |
| `@testing-library/*` | Testing Library | User-centric queries (getByRole, getByText) — avoid getByTestId |
| `mocha` | Mocha | `npx mocha` |
| `playwright` | Playwright | `npx playwright test` |
| `cypress` | Cypress | `npx cypress run` |

## Known Pitfalls

1. **No auto type-checking**: Claude writes TS but doesn't verify compilation. The `tsc --noEmit` hook catches this.
2. **`any` escape hatch**: Claude defaults to `any` under complexity pressure. Rules must explicitly forbid it.
3. **Stale type definitions**: `@types/*` packages may lag behind library versions. Note version alignment.
4. **ESM/CJS confusion**: Mixed module systems cause runtime errors. Detect from `package.json` `type` field.
5. **React version patterns**: React 18+ uses concurrent features (Suspense, transitions, useId) not available in 17. Detect version from deps — React 18+ allows async Server Components; React 17 requires client-side data fetching.
6. **Unnecessary 'use client'**: Claude defaults to Client Components for everything. Without rules, most components get `'use client'` even when they have no interactivity — losing Server Component benefits (smaller bundles, direct backend access, streaming).
7. **Client-side data fetching in Next.js**: Claude uses `useEffect` + `fetch` patterns from SPA-era React instead of Server Component `fetch()`. This loses caching, streaming, and server-side rendering benefits.
8. **Stale closures in effects**: Claude frequently omits dependencies from `useEffect`/`useMemo`/`useCallback` arrays, creating stale closure bugs where callbacks capture initial values and never see updates.
9. **Premature memoization**: Claude wraps everything in `useMemo`/`useCallback`/`React.memo`. Each has overhead — the comparison cost may exceed the re-render cost for simple components.
