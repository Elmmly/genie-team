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

## Anti-Patterns
- No `any` type — use `unknown` with narrowing
- No `@ts-ignore` — fix the underlying type error
- No `as` type assertions without runtime validation
- No `!` non-null assertions — use proper null checks
- No `== null` without `strictNullChecks` enabled

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
| `@testing-library/*` | Testing Library | (used with above) |
| `mocha` | Mocha | `npx mocha` |
| `playwright` | Playwright | `npx playwright test` |
| `cypress` | Cypress | `npx cypress run` |

## Known Pitfalls

1. **No auto type-checking**: Claude writes TS but doesn't verify compilation. The `tsc --noEmit` hook catches this.
2. **`any` escape hatch**: Claude defaults to `any` under complexity pressure. Rules must explicitly forbid it.
3. **Stale type definitions**: `@types/*` packages may lag behind library versions. Note version alignment.
4. **ESM/CJS confusion**: Mixed module systems cause runtime errors. Detect from `package.json` `type` field.
5. **React version mismatches**: React 18+ requires different type patterns than React 17. Detect from deps.
