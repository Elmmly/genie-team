---
type: discover
topic: "provider-scoped-npm-installation"
reasoning_mode: deep
status: active
created: "2026-04-02"
---

# Opportunity Snapshot: Provider-Scoped npm Installation

## 1. Discovery Question

**Original:** Investigate the feasibility of provider-scoped npm installation for genie-team, where install.sh accepts a provider selection and only installs the relevant SDK dependencies.

**Reframed:** 89MB of 208MB total node_modules (43%) comes from four provider SDKs that are mutually exclusive at runtime. Users pick one provider. What npm mechanisms and code patterns exist to avoid installing the unused 70-80MB?

## 2. Observed Behaviors / Signals

- **Four provider SDKs as hard dependencies.** `package.json` lists `@anthropic-ai/claude-agent-sdk` (57MB), `@google/genai` (14MB), `openai` (13MB), and `@anthropic-ai/sdk` (5.1MB) as regular dependencies. All four install on every `npm install`.
- **Provider selection is already a runtime concept.** `cli.ts` has a `createExecutor()` switch on provider name. Users pass `--provider openai` or set it in `genie-config.yaml`. Only one provider client is instantiated per run.
- **Clean file isolation.** Each provider lives in its own file: `src/providers/openai-client.ts`, `src/providers/google-client.ts`, `src/providers/anthropic-client.ts`. The Tier 1 executor (`claude-agent-executor.ts`) is also isolated. No provider SDK is imported outside its own file except in `cli.ts` which imports all three client classes at the top level.
- **Static imports everywhere.** All provider files use top-level `import` statements. `cli.ts` statically imports all three LLMClient classes. TypeScript compiles with `module: Node16`, `type: module` in package.json -- ESM throughout.
- **install.sh already does `npm install` then `npm link`.** The build step is `npm install --ignore-scripts && npm run build && npm link`. There is no provider-scoped logic today.

## 3. Pain Points / Friction Areas

- **Install size.** 89MB of SDK dependencies for a tool where most users will use exactly one provider. The `claude-agent-sdk` alone is 57MB and is the default provider -- users who only use Claude still get OpenAI and Google SDKs.
- **Install time.** npm install takes longer than necessary. On CI (GitHub Actions), this bloats cache and job time.
- **No partial install path.** Users who fork/clone and want a lightweight install have no mechanism to skip unused providers.
- **npm link propagates everything.** When globally linked, the full node_modules including all providers travels with the binary.

## 4. JTBD / User Moments

**Primary Job:** "When installing genie-team as a CLI tool, a developer wants to install only the provider SDK they actually use so they can keep their environment lean and install fast."

**Secondary Job:** "When adding a new provider later, a developer wants to install its SDK without reinstalling everything so they can incrementally expand their setup."

## 5. Assumptions & Evidence

| Assumption | Type | Confidence | Evidence For | Evidence Against |
|------------|------|------------|--------------|------------------|
| Users use only one provider per installation | Value | High | `createExecutor()` switch in cli.ts instantiates exactly one provider. Config has a single `provider` field. CLI flag `--provider` takes one value. | A user *could* run different invocations with different `--provider` flags. The daemon could theoretically mix providers across items (though it currently does not). |
| Dynamic imports work with `module: Node16` in TypeScript | Feasibility | High | TypeScript docs confirm `await import()` is fully supported with `module: Node16`. The project is pure ESM (`"type": "module"`). Dynamic import returns `Promise<typeof import("module")>` which preserves full type information. | No evidence against. This is well-established behavior since TypeScript 2.4+. |
| `peerDependencies` + `peerDependenciesMeta` is the right npm mechanism | Feasibility | High | npm docs state optional peer deps are NOT auto-installed. This matches the "install what you need" pattern exactly. LangChain uses this pattern (community package lists integrations as optional peers). Vercel AI SDK uses separate packages (more extreme version of same idea). | pnpm has had bugs where `autoInstallPeers` ignores the optional flag. Yarn classic handles peer deps differently. Users on non-npm managers may get unexpected behavior. |
| `optionalDependencies` is an alternative | Feasibility | Medium | npm DOES install optionalDependencies by default but won't fail if they can't install. Can be skipped with `--omit=optional`. | This is backwards from what we want -- we want "don't install by default, add on demand." Optional deps are for platform-specific native modules, not provider selection. Wrong semantic. |
| Runtime error from missing dynamic import is catchable and clear | Feasibility | High | `await import("openai")` throws `ERR_MODULE_NOT_FOUND` which is a standard Node.js error. It is catchable with try/catch and the error message includes the package name. | The error message is Node-internal (`Cannot find package 'openai'`), not user-friendly without wrapping. Must provide clear guidance on what to install. |
| This saves meaningful disk/time | Value | Medium | 89MB is 43% of node_modules. The `claude-agent-sdk` (57MB) is the largest single dependency. A Claude-only user would save ~32MB (openai + google + anthropic-sdk). An OpenAI-only user would save ~76MB. | npm deduplication means some transitive deps are shared. Actual savings may be less than the naive sum. Install time savings depend on network and cache state. |

### Evidence Grade Justifications

- **Dynamic import feasibility (High):** TypeScript documentation is authoritative. The project's tsconfig (`module: Node16`, `target: ES2022`) and package.json (`type: module`) are verified. This is the standard path for ESM dynamic imports. No caveats apply.
- **peerDependenciesMeta behavior (High):** npm official docs describe this behavior. Confirmed via npm feedback discussions. The LangChain ecosystem uses this at scale. The one caveat is pnpm compatibility, but genie-team's install.sh uses npm explicitly.
- **Single-provider usage (High):** Direct code evidence -- `createExecutor()` has a switch statement, config schema has `provider: string` (singular). Counter-evidence is theoretical (multi-provider in daemon) but the current code doesn't support it.
- **Size savings (Medium):** The 89MB figure comes from codebase analysis (provided in the brief), not independently measured with `du`. Actual savings post-dedup may differ. Would need `npm ls --all` and per-package size measurement to confirm.

## 6. Technical Signals

- **Feasibility:** Straightforward
- **Constraints:**
  - TypeScript type checking with dynamic imports requires `typeof import("pkg")` type annotations or import-then-cast patterns
  - Tests already mock provider packages (`vi.mock("openai")`), so test infrastructure is unaffected
  - `cli.ts` is the only file outside `src/providers/` that imports provider classes -- the refactor surface is small
  - npm link behavior with peer deps: the linked package won't have peer deps resolved unless the consumer installs them. This needs testing.
- **Needs Architect spike:** No -- the pattern is well-established and the refactor surface is small

### Alternative Framing Considered

I considered whether the real problem is "install size" or "install complexity." If install.sh adds `--provider` flags, it adds a decision point and a failure mode (user picks wrong provider, gets runtime error). The counter-argument: the current approach is simpler but wasteful. Given that provider selection already exists (`--provider` flag, config file), adding it to install is a natural extension, not new complexity. The user already makes this decision at runtime; this just moves it earlier.

## 7. Opportunity Areas (Unshaped)

1. **Provider SDKs as optional peer dependencies.** Move `openai`, `@google/genai`, `@anthropic-ai/sdk`, and `@anthropic-ai/claude-agent-sdk` from `dependencies` to `peerDependencies` with `peerDependenciesMeta: { optional: true }`. Users install the one they need.

2. **Dynamic import at provider instantiation.** Replace static imports in `cli.ts` and provider files with `await import()`. The provider client files keep their static imports (they only load if the file is dynamically imported). OR: make cli.ts dynamically import the provider file itself.

3. **install.sh provider flag.** `./install.sh global --provider claude` runs `npm install` (core deps only since SDKs are now peers) then `npm install @anthropic-ai/claude-agent-sdk` for the selected provider. `--provider all` installs everything.

4. **Clear error messages for missing providers.** When `createExecutor("openai")` is called but `openai` package is missing, surface: "Provider 'openai' requires the openai package. Install it with: npm install openai"

### Counter-Evidence for Each Opportunity

1. **Optional peers:** Users unfamiliar with peer deps may be confused by post-install warnings. npm 7+ auto-installs non-optional peers, so users expect `npm install` to "just work." Moving to optional peers means `npm install` alone produces an incomplete installation -- the tool won't work until you also install a provider. Risk: worse onboarding experience.

2. **Dynamic imports:** Adds async initialization to what is currently synchronous. `createExecutor()` would need to become async. The cascade is small (it's only called in CLI action handlers which are already async), but it's a change. Type inference works but the ergonomics are slightly worse -- you need `const { OpenAILLMClient } = await import("./providers/openai-client.js")` and TypeScript infers the type correctly but IDE go-to-definition may be less reliable.

3. **install.sh flag:** Adds a required decision to installation. New users following a README would need to know which provider to pick. Mitigation: default to `claude` (already the default provider). But this means `./install.sh global` silently installs only the Claude SDK -- users who later want OpenAI need to know to run an additional install step.

4. **Error messages:** This is pure upside with no meaningful counter-evidence. Even without the other changes, better error messages for missing SDKs would be valuable.

## 8. Evidence Gaps

- **Actual deduplicated size savings.** The 89MB figure is pre-dedup. Need `du -sh node_modules/@anthropic-ai node_modules/openai node_modules/@google` vs total to confirm real savings.
- **npm link + peer deps interaction.** When a globally linked package has optional peer deps, does `npm install <peer>` in the package directory make it available? Or does the consumer need to install? This needs a quick test.
- **pnpm/yarn compatibility.** If users install via pnpm, `peerDependenciesMeta` optional behavior differs. The install.sh uses npm, but users who clone the repo might use a different package manager.
- **Multi-provider usage patterns.** Do any users actually switch providers between invocations? The code supports it but we have no usage data.
- **CI impact.** What's the actual install time difference? On GitHub Actions with npm cache, the delta may be small.

## 9. Routing Recommendation

- [x] **Ready for Shaper** -- Problem understood
- [ ] **Continue Discovery** -- More exploration needed
- [ ] **Needs Architect Spike** -- Technical feasibility unclear
- [ ] **Needs Navigator Decision** -- Strategic question

**Rationale:** The problem is clear (43% of node_modules is unused provider SDKs), the npm mechanisms are well-documented and proven at scale (LangChain, Vercel AI SDK), the code architecture already isolates providers cleanly, and the refactor surface is small (cli.ts + package.json + install.sh). The two evidence gaps (npm link + peers interaction, actual dedup savings) are quick to verify during shaping and don't block the decision to proceed.

### Concrete npm Mechanism Summary

| Mechanism | Behavior | Fit for This Use Case |
|-----------|----------|-----------------------|
| `dependencies` (current) | Always installed. | No -- installs everything. |
| `optionalDependencies` | Installed by default, skippable with `--omit=optional`. Failure doesn't abort install. | Wrong semantic -- we want "not installed by default." |
| `peerDependencies` + `peerDependenciesMeta` optional | NOT installed by default (npm 7+). No warning if missing. Consumer adds what they need. | Best fit. Matches the "install what you use" pattern exactly. |
| Separate packages (Vercel AI SDK pattern) | Each provider is its own npm package. Core package has no provider deps. | Overkill -- genie-team is a single CLI tool, not a library ecosystem. Adds monorepo complexity for no benefit. |
| Post-install script | `npm install` then conditional `npm install <provider>`. | Viable as an install.sh enhancement. Works with any of the above package.json strategies. |

### Recommended Pattern (for Shaper to evaluate)

`peerDependencies` + `peerDependenciesMeta` optional in package.json. Dynamic import in `cli.ts` for the provider file. install.sh `--provider` flag that runs the base install then `npm install <selected-sdk>`. Default provider: `claude` (matching existing default).

### Established Pattern Precedents

- **Vercel AI SDK:** Separate `@ai-sdk/openai`, `@ai-sdk/anthropic`, `@ai-sdk/google` packages. User installs core + the provider they want. Most aggressive decomposition.
- **LangChain JS:** `@langchain/community` lists integrations as optional peer dependencies. User installs `@langchain/community` + `@langchain/openai` (or whatever provider). Core is a peer dep of all packages.
- **Prisma:** Separate `@prisma/adapter-pg`, `@prisma/adapter-mysql` etc. User installs the adapter for their database. Prisma 7 requires exactly one adapter.
- **All three use the same principle:** core package + user-selected provider package, never bundling all providers.
