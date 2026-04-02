---
adr_version: "1.0"
type: adr
id: ADR-008
title: "Distribution Models and Provider Installation"
status: accepted
created: 2026-04-02
deciders: [shaper, navigator]
tags: [architecture, distribution, npm, installation, providers]
---

# ADR-008: Distribution Models and Provider Installation

## Context

Genie-team supports multiple AI providers (ADR-007) with provider SDKs as optional peer dependencies (P1-provider-scoped-installation). The tool needs to work across three distribution models:

1. **`git clone` + `install.sh`** — developer install, repo on disk
2. **`npm install -g genie-team`** — published package, no repo checkout
3. **`npx genies-core`** — ephemeral, zero persistent state

Each model has different constraints on where provider SDK dependencies can be installed and persisted.

### The Problem

`genies-core install openai` needs a persistent `node_modules/` to install into. Where that lives depends on how the tool was installed:

| Model | Binary location | node_modules location | Persistent? |
|-------|----------------|----------------------|-------------|
| git clone + npm link | `<repo>/dist/index.js` (symlinked) | `<repo>/node_modules/` | Yes |
| npm install -g | `<global-modules>/genie-team/dist/index.js` | `<global-modules>/genie-team/node_modules/` | Yes |
| npx | Temporary cache | Temporary cache | No |

### Alternatives Considered

| Alternative | Pros | Cons | Why Not |
|-------------|------|------|---------|
| **A: npx limited to info commands** | Simple, no workarounds. npx users can still explore (`check`, `providers`, `--help`). Execution requires proper install. | npx users can't run `genies-core run` | **Accepted** — npx is for exploration, not autonomous AI execution |
| **B: Default provider as regular dep** | npx works with Claude out of the box | Contradicts "no auto-install" principle; 57MB always ships | Violates P1 design decision |
| **C: GENIES_PROVIDER_PATH env var** | npx could use a persistent provider location | Adds complexity; user must manage a directory; fragile | Over-engineering for a niche use case |
| **D: Bundle all providers** | Everything always works | Defeats the purpose of scoped installation; 89MB always ships | Directly contradicts P1 |

## Decision

**Accepted.** Support models 1 and 2 fully. Model 3 (npx) is limited to informational commands.

### How it works

`genies-core install <provider>` resolves the genie-team package root from `__dirname` (the binary's own location → `dist/` → parent directory). This works identically for both git clone and npm global install because both have `node_modules/` as a sibling to `dist/`.

```
# git clone
<repo>/dist/index.js   →  __dirname = <repo>/dist/  →  parent = <repo>/
<repo>/node_modules/   ←  npm install openai here

# npm -g
<global>/genie-team/dist/index.js  →  __dirname = <global>/genie-team/dist/  →  parent = <global>/genie-team/
<global>/genie-team/node_modules/  ←  npm install openai here
```

### npx behavior

When run via npx, `genies-core run` detects that no providers are installed and shows:

```
Error: Provider 'claude' is not installed.
Provider execution requires a persistent install:
  npm install -g genie-team
Then: genies-core install claude
```

Info commands work via npx: `npx genies-core --help`, `npx genies-core providers`, `npx genies-core check`.

## Consequences

**Positive:**
- Single `__dirname` resolution works for both persistent install models
- No special casing between git clone and npm global
- npx users get a clear path to full installation
- Info commands via npx are useful for "what is this tool?"

**Negative:**
- npx users cannot run `genies-core run` — must do a proper install first
- Global npm install requires write access to global `node_modules/` for `genies-core install`
- If the git clone repo is moved after `npm link`, the global binary breaks (npm link limitation, not specific to provider installation)

**Deferred:**
- If npx demand materializes, revisit option C (persistent provider path) or consider a "zero-dep mode" that uses the Anthropic/OpenAI/Google REST APIs directly without SDK packages
