---
spec_version: "1.0"
type: shaped-work
id: P1-provider-scoped-installation
title: "Provider-Scoped Installation"
status: shaped
created: 2026-04-02
appetite: medium
priority: P1
author: shaper
spec_ref: null
discovery_ref: docs/analysis/20260402_discover_provider-scoped-installation.md
adr_refs: []
depends_on:
  - docs/decisions/ADR-007-multi-provider-phase-execution.md
acceptance_criteria:
  - id: AC-1
    description: >-
      install.sh global requires --provider flag. Without it, prints
      available providers and exits. Accepts one or more: --provider claude
      --provider openai. Installs only the selected SDK(s).
    status: pending
  - id: AC-2
    description: >-
      Provider SDKs moved from dependencies to peerDependencies with
      peerDependenciesMeta optional:true. npm install alone installs
      core deps only — no provider SDKs.
    status: pending
  - id: AC-3
    description: >-
      genies-core install <provider> command installs the provider SDK
      into the genie-team repo's node_modules. Resolves repo path from
      the binary's location. Works when globally linked via npm link.
    status: pending
  - id: AC-4
    description: >-
      Provider clients use dynamic import(). If the SDK is not installed,
      a clear error message tells the user how to install it:
      "Provider 'openai' is not installed. Install with: genies-core install openai"
    status: pending
  - id: AC-5
    description: >-
      genies-core providers shows three states per provider:
      [ready] (installed + key set), [installed, no key] (installed,
      key missing), [not installed] (SDK not present).
    status: pending
  - id: AC-6
    description: >-
      genies-core check degrades gracefully when Claude CLI is not
      present. Shows informational note instead of failure when the
      configured provider is not claude.
    status: pending
  - id: AC-7
    description: >-
      Provider selection is runtime, not install-time. Users can switch
      providers via --provider flag or genie-config.yaml at any time.
      Installing a provider makes it available; config/flags choose it.
    status: pending
---

# Provider-Scoped Installation

## Problem

Users install 89MB of provider SDKs (43% of total node_modules) when they only use one. A Claude-only user gets OpenAI and Google SDKs they'll never use. An OpenAI user gets the 57MB Claude Agent SDK.

Provider selection already exists at runtime (`--provider` flag, `genie-config.yaml`). But the install step doesn't respect it — every provider SDK ships with every installation.

## Evidence

- Provider SDK sizes: claude-agent-sdk 57MB, @google/genai 14MB, openai 13MB, @anthropic-ai/sdk 5.1MB
- Total provider SDKs: 89MB of 208MB node_modules
- Each provider is isolated in its own file — no cross-provider imports
- Established pattern: Vercel AI SDK, LangChain JS, Prisma all use "core + user-selected provider"
- npm `peerDependencies` + `peerDependenciesMeta` optional is the right mechanism (npm 7+)
- Dynamic `import()` fully supported in the project's ESM + Node16 config

## Appetite

**Medium batch — 3-5 days.**

This is a package.json restructure + dynamic import refactor + install.sh update + new CLI command. The code architecture is already perfect (isolated providers, `createExecutor()` switch). Most of the work is in error handling, the install command, and testing the npm link + peer deps interaction.

## Consumer Experience

### First install
```bash
./install.sh global
# Error: Choose a provider with --provider flag.
# Available: claude, anthropic, openai, google
# Example: ./install.sh global --provider claude

./install.sh global --provider claude
# Installs core + @anthropic-ai/claude-agent-sdk

./install.sh global --provider claude --provider openai
# Installs core + claude-agent-sdk + openai
```

### Adding a provider later
```bash
genies-core install openai
# → npm install openai (in genie-team repo)
# Installed provider: openai

genies-core install google
# Installed provider: google
```

### Checking what's available
```bash
genies-core providers
# Available Providers
# ────────────────────────────────────────────────────────────
#   claude       Tier 1  [ready] (default)
#   anthropic    Tier 2  [not installed]         genies-core install anthropic
#   openai       Tier 2  [installed, no key]     Set OPENAI_API_KEY
#   google       Tier 2  [ready]
```

### Switching providers
```bash
# Via config (persistent)
# genie-config.yaml → provider: openai

# Via flag (per invocation)
genies-core run --provider google --model gemini-2.0-flash "topic"

# No lock-in — install what you might use, switch freely
```

### Missing provider at runtime
```bash
genies-core run --provider openai "topic"
# Error: Provider 'openai' is not installed.
# Install with: genies-core install openai
```

## Solution Sketch

### package.json changes
```json
{
  "dependencies": {
    "commander": "...",
    "execa": "...",
    "js-yaml": "...",
    "p-limit": "...",
    "glob": "..."
  },
  "peerDependencies": {
    "@anthropic-ai/claude-agent-sdk": "^0.2.76",
    "@anthropic-ai/sdk": "^4.0.0",
    "openai": "^6.0.0",
    "@google/genai": "^1.0.0"
  },
  "peerDependenciesMeta": {
    "@anthropic-ai/claude-agent-sdk": { "optional": true },
    "@anthropic-ai/sdk": { "optional": true },
    "openai": { "optional": true },
    "@google/genai": { "optional": true }
  }
}
```

### Dynamic import in createExecutor()
```typescript
case "openai": {
  try {
    const { OpenAILLMClient } = await import("./providers/openai-client.js");
    // ...
  } catch {
    throw new Error(
      "Provider 'openai' is not installed.\n" +
      "Install with: genies-core install openai"
    );
  }
}
```

### Provider SDK mapping
| Provider flag | npm package |
|--------------|-------------|
| claude | @anthropic-ai/claude-agent-sdk |
| anthropic | @anthropic-ai/sdk |
| openai | openai |
| google | @google/genai |

### genies-core install command
- Resolves genie-team repo root from `__dirname` (binary is in `dist/`)
- Runs `npm install <package>` in that directory
- Reports success/failure

### install.sh --provider flag
- Parses `--provider` flags (one or more)
- After core `npm install`, runs `npm install <package>` for each selected provider
- Before `npm link`

## Rabbit Holes

- **Don't split into separate npm packages** (Vercel AI SDK pattern). Genie-team is a CLI tool, not a library ecosystem. Monorepo complexity for no benefit.
- **Don't use optionalDependencies.** They install by default — opposite of what we want.
- **Don't auto-install providers.** If the user didn't ask for it, don't install it. Even Claude.
- **Don't break tsc.** TypeScript needs types at compile time even for dynamic imports. The provider .ts files can keep static imports — they compile fine. Only the *loading* of the compiled .js at runtime is dynamic.

## No-gos

- No provider auto-detection from environment (don't guess based on which API keys are set)
- No provider migration tooling (switching providers doesn't require data migration)
- No provider-specific config schemas (keep genie-config.yaml uniform)

## Dependencies

- ADR-007 multi-provider architecture (done)
- All four provider clients implemented (done)
- `genies-core providers` command exists (done — needs update for three-state)

## Risks

| Risk | Mitigation |
|------|------------|
| npm link + peer deps interaction untested | Test during implementation — quick spike |
| tsc compile needs SDK types even when not installed | Provider .ts files keep static imports; types available via peerDependencies at dev time |
| Users confused by "choose a provider" on first install | Clear error message with examples; README updated |
| pnpm/yarn handle peer deps differently | Document npm as supported; note pnpm/yarn workarounds |

## Routing

Ready for design → deliver. No architectural decisions needed — uses established npm patterns.

# End of Shaped Work Contract
