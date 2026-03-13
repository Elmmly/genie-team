---
spec_version: "1.0"
type: shaped-work
id: P0-typescript-sdk-migration
title: "TypeScript Migration via Claude Agent SDK"
status: designed
created: 2026-03-12
appetite: big
priority: P0
author: shaper
spec_ref: docs/specs/platform/sdk-orchestrator.md
discovery_ref: null
spike_ref: null
adr_refs:
  - docs/decisions/ADR-005-sdk-integrated-orchestrator.md
depends_on:
  - docs/decisions/ADR-005-sdk-integrated-orchestrator.md
acceptance_criteria:
  - id: AC-1
    description: >-
      TypeScript project initialized with package.json, tsconfig.json,
      vitest config, and @anthropic-ai/claude-agent-sdk dependency. Entry
      point `genies-core` compiles to executable via tsx or compiled JS.
      Existing `genies` shell script delegates to `genies-core` when
      available, preserving backward compatibility.
    status: pending
  - id: AC-2
    description: >-
      `genies check` subcommand implemented in TypeScript as the SDK pilot.
      Checks Claude CLI, auth method, billing mode, gh auth, MCP servers,
      install status, git state, and genie-config.yaml validity. Reports
      OK/WARN/FAIL with actionable guidance. Exit code 0 on pass, 1 on fail.
      This validates the TS toolchain and replaces AC-2 from
      P1-environment-health.
    status: pending
  - id: AC-3
    description: >-
      Core `runPhase()` function implemented using Agent SDK `query()`.
      Accepts phase name, input path, tool allowlist, max turns, max budget,
      model override, and session ID for resume. Returns typed result with
      session ID, token counts, cost, and output text. Replaces the
      `run_phase()` bash function from scripts/genies.
    status: pending
  - id: AC-4
    description: >-
      SDK invocations set `settingSources: ["project"]` and
      `systemPrompt: { type: "preset", preset: "claude_code" }` to ensure
      CLAUDE.md, rules, skills, and agent definitions are loaded. Validated
      by test that checks project context is present in agent behavior.
    status: pending
  - id: AC-5
    description: >-
      Session management carries context across phases via SDK `resume`
      parameter. Scout session ID passed to Shaper, Shaper to Architect,
      etc. `--no-resume` flag starts fresh sessions. Session IDs logged
      for debugging.
    status: pending
  - id: AC-6
    description: >-
      Auth mode control implemented: `--auth oauth` unsets ANTHROPIC_API_KEY
      in SDK child environment; `--auth apikey` requires it. Default detects
      and reports billing mode. Preflight displays billing mode before
      spawning any SDK sessions.
    status: pending
  - id: AC-7
    description: >-
      Model tier configuration via genie-config.yaml: tiers (reasoning,
      default, fast) mapped to model IDs, per-genie assignments. SDK
      `query()` receives model override from config. `genies models`
      subcommand displays configuration. Config searched at project then
      global scope.
    status: pending
  - id: AC-8
    description: >-
      Batch execution reimplemented using async/await and Promise.all()
      with configurable concurrency limit. Replaces the bash polling-based
      worker pool. Each worker operates in an isolated git worktree.
      Errors collected and reported after all workers complete.
    status: pending
  - id: AC-9
    description: >-
      SDK hooks used for real-time execution governance: PostToolUse tracks
      artifact creation, Stop logs phase completion with cost, and
      maxBudgetUsd enforces per-session spending caps. Hook events written
      to structured log file for observability.
    status: pending
---

# Shaped Work Contract: TypeScript Migration via Claude Agent SDK

## Problem

Genie-team's 12,000 lines of shell scripting have hit their ceiling. The core `genies` orchestrator (2,567 lines) uses hand-rolled YAML parsing via sed chains, a 223-line polling-based parallel worker pool, non-atomic frontmatter updates with race conditions in batch mode, and silent jq degradation. Every new feature (auth control, model routing, observability) makes the fragility worse.

Meanwhile, the Claude Agent SDK provides programmatic capabilities that `claude -p` cannot match: hooks for execution governance, per-session budget caps, session resume across phases, and structured output validation. These are exactly the capabilities genie-team needs for enterprise scalability — but they're only accessible from TypeScript.

**Who's affected:** Every genie-team user and contributor. Shell fragility causes silent failures in batch/daemon mode. Lack of SDK governance means no real-time cost control or quality enforcement during autonomous execution.

**Evidence:**
- Shell audit: 26 scripts, ~12,000 lines, 14 critical/high-risk pain points identified (strong)
- SDK spike: strict superset of `claude -p` with ~15 new capabilities (strong)
- SDK wraps Claude Code CLI internally — same auth, same billing, no new runtime dependency since users already have Node.js (strong)
- Multi-provider analysis confirmed single-provider (Claude) is the right strategy (strong)

## Appetite & Boundaries

- **Appetite:** Big batch (1-2 weeks per phase, ~6 weeks total across 4 phases)
- **Phased delivery:**
  - Phase 0: TS toolchain + `genies check` pilot (1 week)
  - Phase 1: Core `runPhase()` + session management (2-3 weeks)
  - Phase 2: Batch/daemon migration (2-3 weeks)
  - Phase 3: Shell decommission + cleanup (1 week)
- **No-gos:**
  - No multi-LLM provider support — single provider (Anthropic) by design
  - No big-bang rewrite — incremental migration with shell fallback at each phase
  - No changes to Claude Code hooks — must remain shell scripts per platform contract
  - No custom agent runtime — SDK provides the execution engine
  - No changes to prompt definitions — markdown commands/agents/skills stay as-is
- **Fixed elements:**
  - `genies` shell entry point preserved as thin wrapper delegating to TypeScript
  - CLI contract (`docs/architecture/cli-contract.md`) remains valid
  - Git worktree isolation model preserved
  - All existing genie workflow phases and artifact formats unchanged

## Goals & Outcomes

1. **Governance:** Real-time cost control via SDK `maxBudgetUsd` and hooks — no more $7+ surprise runs
2. **Reliability:** Typed YAML/JSON parsing, proper error handling, atomic file operations — no more silent failures
3. **Velocity:** Jest/Vitest testing replaces 7,000 lines of custom bash test framework
4. **Cost optimization:** Model tier routing (Opus for reasoning, Haiku for review) can reduce per-phase costs by 30-50%
5. **Extensibility:** New features (observability, auth control, model routing) built on solid foundation instead of sed chains
6. **Contribution:** TypeScript codebase is more approachable for contributors than 2,567-line bash monolith

## Behavioral Delta

**Spec:** docs/specs/platform/installation-system.md (minor change only)

### Current Behavior
- AC-1: install.sh installs shell scripts to PATH

### Proposed Changes
- AC-1: install.sh installs TypeScript-compiled `genies-core` alongside shell wrapper; shell `genies` delegates to `genies-core` when present
- AC-NEW: 9 new ACs in new spec `docs/specs/platform/sdk-orchestrator.md`

### Rationale
The SDK orchestrator is a new capability that subsumes P1-environment-health (check, auth control, model tiers are all delivered here). The install system spec gets a minor delta for distribution; the bulk lives in a new spec.

## Risks & Assumptions

| Assumption | Type | Test |
|------------|------|------|
| SDK `query()` handles all `run_phase()` patterns (tool allowlisting, turns, resume, verdict parsing) | Feasibility | Phase 0 pilot proves the pattern with `genies check` |
| `settingSources: ["project"]` loads CLAUDE.md, rules, skills, agents correctly | Feasibility | Automated test in Phase 0 validates project context loading |
| Incremental migration works — TS orchestrator coexists with shell scripts | Feasibility | Phase 0 proves coexistence (shell wrapper delegates to TS) |
| Node.js is available on all target environments | Usability | Claude Code already requires Node.js; no new dependency |
| SDK API is stable enough to depend on | Feasibility | Pin SDK version; abstract behind internal interface |

## Options

| Option | Pros | Cons | Recommendation |
|--------|------|------|----------------|
| A: Phased TS migration via SDK | Incremental, SDK governance, each phase ships value | 6-week total timeline; two-language coexistence during transition | **Recommended** |
| B: Go rewrite (keep CLI spawning) | Single binary, great CLI ergonomics | Loses SDK integration (hooks, budget, sessions, structured output) | Not recommended — ceiling too low |
| C: Shell hardening (no migration) | Zero migration cost | Fragility worsens with every feature; no SDK governance possible | Not recommended — deferring inevitable |

## Routing

**Next:** `/design` — Architect designs the TypeScript project structure, SDK integration pattern, shell-to-TS delegation mechanism, and phased migration plan. Then Crafter implements Phase 0 (pilot).

**Subsumes:** P1-environment-health ACs are delivered within this item (check = Phase 0 pilot; auth/model tiers = Phase 1). P1-environment-health should be marked `superseded` after this item begins delivery.

---

# Design

> Appended by `/design` on 2026-03-12. Reasoning mode: deep.

## Design Summary

Migrate genie-team's orchestration from a 2,567-line bash monolith to a TypeScript project using the Claude Agent SDK. The shell `genies` script becomes a thin wrapper that delegates to the compiled TypeScript `genies-core` binary. The migration is incremental: each phase ships independently and the shell fallback remains functional until Phase 3 decommissions it.

## Project Structure

```
src/
├── index.ts                  # CLI entry point (genies-core)
├── cli.ts                    # Argument parsing, command routing
├── config/
│   ├── phase-config.ts       # Phase definitions, tool allowlists, turn budgets
│   └── genie-config.ts       # genie-config.yaml loader (tiers, model mapping)
├── core/
│   ├── phase-executor.ts     # runPhase() via SDK query(), retry logic
│   ├── prompt-builder.ts     # Phase prompt construction with context/mode injection
│   ├── session-manager.ts    # Cross-phase session ID tracking and resume gating
│   ├── verdict-detector.ts   # APPROVED/BLOCKED/CHANGES_REQUESTED parsing
│   ├── artifact-parser.ts    # Extract docs/ paths from phase output
│   └── frontmatter.ts        # YAML frontmatter read/write (js-yaml, atomic writes)
├── execution/
│   ├── single-item.ts        # Single-item phase loop (discover → done)
│   ├── batch-executor.ts     # Parallel/sequential batch with Promise.allSettled
│   ├── daemon-executor.ts    # Continuous polling loop with cycle/cost budgets
│   └── finisher.ts           # Complete stalled genie/* branches
├── environment/
│   ├── check.ts             # genies check checks
│   ├── preflight.ts          # Pre-execution validation
│   └── auth.ts               # OAuth vs API key detection, billing mode control
├── hooks/
│   ├── artifact-tracker.ts   # PostToolUse: track Write operations
│   ├── cost-logger.ts        # Stop: log phase cost to JSONL
│   └── budget-gate.ts        # maxBudgetUsd enforcement
├── git/
│   ├── worktree.ts           # Create/remove/list worktrees via execa
│   ├── branch.ts             # Branch naming, default branch detection
│   └── integration.ts        # Merge/PR creation (gh CLI via execa)
└── types/
    ├── phase.ts              # Phase, PhaseResult, PhaseConfig types
    ├── config.ts             # GenieConfig, ModelTier types
    └── sdk.ts                # SDK option/result type wrappers

tests/
├── unit/
│   ├── phase-executor.test.ts
│   ├── verdict-detector.test.ts
│   ├── frontmatter.test.ts
│   ├── genie-config.test.ts
│   ├── auth.test.ts
│   └── prompt-builder.test.ts
├── integration/
│   ├── check.test.ts
│   ├── single-item.test.ts
│   └── sdk-context.test.ts   # Validates CLAUDE.md loading
└── fixtures/
    ├── backlog-items/
    └── genie-configs/

package.json
tsconfig.json
vitest.config.ts
```

## Key Interfaces

### PhaseConfig (replaces bash arrays at lines 21-34)

```typescript
interface PhaseDefinition {
  name: Phase;
  defaultTurns: number;
  minTurns: number;
  tools: string[];
}

type Phase = 'discover' | 'define' | 'design' | 'deliver' | 'discern' | 'commit' | 'done';

const PHASES: Record<Phase, PhaseDefinition> = {
  discover: { name: 'discover', defaultTurns: 50, minTurns: 0, tools: ['Read','Grep','Glob','WebSearch','WebFetch','Task'] },
  define:   { name: 'define',   defaultTurns: 50, minTurns: 0, tools: ['Read','Grep','Glob','Write','Task'] },
  design:   { name: 'design',   defaultTurns: 50, minTurns: 0, tools: ['Read','Grep','Glob','Write','Edit','Task'] },
  deliver:  { name: 'deliver',  defaultTurns: 100, minTurns: 3, tools: ['Read','Grep','Glob','Write','Edit','Bash','Task'] },
  discern:  { name: 'discern',  defaultTurns: 50, minTurns: 0, tools: ['Read','Grep','Glob','Bash','Task'] },
  commit:   { name: 'commit',   defaultTurns: 10, minTurns: 0, tools: ['Bash'] },
  done:     { name: 'done',     defaultTurns: 20, minTurns: 0, tools: ['Read','Grep','Glob','Write','Edit','Bash'] },
};
```

### PhaseExecutor (replaces run_phase() at lines 707-803)

```typescript
interface PhaseOptions {
  phase: Phase;
  input: string;
  cwd: string;
  sessionId?: string;        // For --resume
  model?: string;            // From genie-config tier
  maxTurns?: number;         // Override default
  maxBudgetUsd?: number;     // SDK-only capability
  authMode?: 'oauth' | 'apikey';
  skipPermissions?: boolean;
  hooks?: ExecutionHooks;
}

interface PhaseResult {
  output: string;
  sessionId: string;
  numTurns: number;
  inputTokens: number;
  outputTokens: number;
  costUsd: number;
  artifacts: string[];       // File paths detected via hooks
}

async function runPhase(options: PhaseOptions): Promise<PhaseResult> {
  const config = PHASES[options.phase];
  const prompt = buildPrompt(options.phase, options.input, options.cwd);

  const env = { ...process.env };
  if (options.authMode === 'oauth') delete env.ANTHROPIC_API_KEY;

  const result = await query({
    prompt,
    options: {
      maxTurns: options.maxTurns ?? config.defaultTurns,
      allowedTools: config.tools,
      model: options.model,
      maxBudgetUsd: options.maxBudgetUsd,
      permissionMode: options.skipPermissions ? 'dangerouslySkipPermissions' : undefined,
      cwd: options.cwd,
      resume: options.sessionId,
      settingSources: ['project'],
      systemPrompt: { type: 'preset', preset: 'claude_code' },
      env,
      hooks: options.hooks ? buildSdkHooks(options.hooks) : undefined,
    },
  });

  return parsePhaseResult(result);
}
```

### GenieConfig (replaces hardcoded model defaults)

```yaml
# ~/.claude/genie-config.yaml
tiers:
  reasoning: claude-opus-4-6
  default: claude-sonnet-4-6
  fast: claude-haiku-4-5

genies:
  scout: reasoning
  shaper: default
  architect: reasoning
  crafter: default
  critic: fast
  tidier: default
  designer: default

# Optional overrides
auth: oauth          # default auth mode for headless
budgetPerPhase: 5.0  # default maxBudgetUsd per phase
```

```typescript
interface GenieConfig {
  tiers: Record<string, string>;    // tier name → model ID
  genies: Record<string, string>;   // genie name → tier name
  auth?: 'oauth' | 'apikey';
  budgetPerPhase?: number;
}

function loadConfig(cwd: string): GenieConfig {
  // Search: {cwd}/.claude/genie-config.yaml → ~/.claude/genie-config.yaml → defaults
  const projectPath = path.join(cwd, '.claude', 'genie-config.yaml');
  const globalPath = path.join(os.homedir(), '.claude', 'genie-config.yaml');

  if (fs.existsSync(projectPath)) return parseConfig(projectPath);
  if (fs.existsSync(globalPath)) return parseConfig(globalPath);
  return DEFAULT_CONFIG;
}

function getModelForPhase(config: GenieConfig, phase: Phase): string | undefined {
  const genieName = PHASE_TO_GENIE[phase]; // discover→scout, deliver→crafter, etc.
  const tierName = config.genies[genieName];
  return tierName ? config.tiers[tierName] : undefined;
}
```

### Batch Executor (replaces polling loop at lines 1988-2211)

```typescript
interface BatchItem {
  phase: Phase;
  input: string;
  slug: string;
}

async function runBatchParallel(
  items: BatchItem[],
  concurrency: number,
  options: BatchOptions,
): Promise<BatchManifest> {
  const manifest: BatchManifest = { succeeded: [], failed: [], conflicts: [] };

  // Semaphore-based concurrency control
  const semaphore = new Semaphore(concurrency);
  const results = await Promise.allSettled(
    items.map(async (item) => {
      await semaphore.acquire();
      try {
        const worktree = await createWorktree(item);
        const result = await runSingleItem(item, { cwd: worktree.path, ...options });
        return { item, result, worktree };
      } finally {
        semaphore.release();
      }
    }),
  );

  // Collect results, then serialize integration (merge/PR)
  for (const r of results) {
    if (r.status === 'fulfilled') {
      await integrateWorktree(r.value.worktree, options);
      manifest.succeeded.push(r.value.item.slug);
    } else {
      manifest.failed.push({ slug: item.slug, error: r.reason.message });
    }
  }

  return manifest;
}
```

### SDK Hooks (new capability — no bash equivalent)

```typescript
function buildSdkHooks(executionHooks: ExecutionHooks): object {
  return {
    postToolUse: [({ tool, input }) => {
      if (tool === 'Write' && input.file_path) {
        executionHooks.onArtifact(input.file_path);
      }
    }],
    stop: [({ result, cost }) => {
      executionHooks.onPhaseComplete({
        costUsd: cost,
        sessionId: result.session_id,
        numTurns: result.num_turns,
      });
    }],
  };
}

interface ExecutionHooks {
  onArtifact: (path: string) => void;
  onPhaseComplete: (metrics: PhaseMetrics) => void;
  onError?: (error: Error, phase: Phase) => void;
}
```

## Shell-to-TypeScript Delegation

The existing `genies` shell script gets a delegation preamble (inserted at top of `main`):

```bash
# Delegate to genies-core (TypeScript) if available
if command -v genies-core &>/dev/null; then
    # Pass all args through; genies-core handles subcommands it knows
    genies-core "$@"
    ec=$?
    # Exit code 127 = genies-core doesn't handle this subcommand yet → fall through to bash
    if [[ $ec -ne 127 ]]; then
        exit $ec
    fi
    # Fall through to bash implementation
fi
```

**Phase 0:** `genies-core` handles `check` and `models` subcommands only. All other commands return exit code 127 → shell fallback.

**Phase 1:** `genies-core` adds single-item execution (`run`, `session`). Shell fallback for batch/daemon.

**Phase 2:** `genies-core` adds batch and daemon. Shell fallback only for legacy subcommands.

**Phase 3:** Shell script reduced to delegation wrapper only (~20 lines).

## Frontmatter Module (replaces sed chains)

The most fragile bash code is YAML frontmatter parsing (lines 49-123). The TypeScript replacement uses `js-yaml`:

```typescript
import yaml from 'js-yaml';
import { readFile, writeFile } from 'fs/promises';
import { lock } from 'proper-lockfile';

interface Frontmatter {
  [key: string]: unknown;
}

async function readFrontmatter(filePath: string): Promise<{ frontmatter: Frontmatter; body: string }> {
  const content = await readFile(filePath, 'utf-8');
  const match = content.match(/^---\n([\s\S]*?)\n---\n([\s\S]*)$/);
  if (!match) return { frontmatter: {}, body: content };
  return { frontmatter: yaml.load(match[1]) as Frontmatter, body: match[2] };
}

async function writeFrontmatter(filePath: string, frontmatter: Frontmatter, body: string): Promise<void> {
  const release = await lock(filePath, { retries: 3 });
  try {
    const yamlStr = yaml.dump(frontmatter, { lineWidth: -1, quotingType: '"' });
    await writeFile(filePath, `---\n${yamlStr}---\n${body}`);
  } finally {
    await release();
  }
}
```

This eliminates: sed chains for field extraction, non-atomic read-modify-write, race conditions in batch mode, and silent parsing failures on quoted/special values.

## Auth Detection (check + preflight)

```typescript
interface AuthStatus {
  method: 'oauth' | 'apikey' | 'none';
  billingMode: 'capped' | 'uncapped' | 'unknown';
  apiKeySet: boolean;
  oauthActive: boolean;
  ambiguous: boolean;  // Both OAuth and API key configured
}

async function detectAuth(): Promise<AuthStatus> {
  const apiKeySet = !!process.env.ANTHROPIC_API_KEY;
  let oauthActive = false;

  try {
    const { stdout } = await execa('claude', ['auth', 'status']);
    oauthActive = stdout.includes('Logged in');
  } catch { /* CLI not available or not logged in */ }

  const ambiguous = apiKeySet && oauthActive;
  const method = apiKeySet ? 'apikey' : oauthActive ? 'oauth' : 'none';
  const billingMode = method === 'oauth' ? 'capped' : method === 'apikey' ? 'uncapped' : 'unknown';

  return { method, billingMode, apiKeySet, oauthActive, ambiguous };
}
```

## Dependencies

```json
{
  "dependencies": {
    "@anthropic-ai/claude-agent-sdk": "^1.x",
    "js-yaml": "^4.1",
    "execa": "^9.x",
    "proper-lockfile": "^4.1",
    "commander": "^12.x"
  },
  "devDependencies": {
    "typescript": "^5.7",
    "vitest": "^3.x",
    "tsx": "^4.x",
    "@types/js-yaml": "^4.0",
    "@types/proper-lockfile": "^4.1"
  }
}
```

**Why these choices:**
- `commander` — Standard CLI framework; lighter than yargs, well-typed
- `execa` — Type-safe subprocess execution for git/gh operations
- `proper-lockfile` — Atomic file locking for concurrent frontmatter updates
- `tsx` — Run TypeScript directly during development; compile for distribution
- `js-yaml` — YAML parsing/serialization (replaces all sed chains)

## Migration Strategy

### Phase 0: Toolchain + Doctor Pilot (AC-1, AC-2) — 1 week

1. Initialize TypeScript project at `src/` with package.json, tsconfig, vitest
2. Implement `genies-core check` and `genies-core models`
3. Add delegation preamble to `scripts/genies` (exit 127 fallback)
4. install.sh: compile `genies-core` during install, add to PATH alongside `genies`
5. **Validation:** `genies check` runs in TypeScript, all other commands fall through to bash

### Phase 1: Core Execution (AC-3, AC-4, AC-5, AC-6, AC-7) — 2-3 weeks

1. Implement `PhaseExecutor.runPhase()` using SDK `query()`
2. Implement `SessionManager` for cross-phase resume
3. Implement `GenieConfig` loader and `--auth` flag
4. Implement `SingleItemExecutor` (phase loop with verdict gating)
5. `genies-core` handles `run` subcommand for single items
6. **Validation:** `genies run P1-item.md` works end-to-end via SDK

### Phase 2: Batch + Daemon (AC-8, AC-9) — 2-3 weeks

1. Implement `BatchExecutor` with `Promise.allSettled` and semaphore
2. Implement `DaemonExecutor` with interval loop and signal handling
3. Implement `FinisherExecutor` for stalled branch completion
4. Implement SDK hooks for artifact tracking and cost logging
5. **Validation:** `genies daemon` and `genies run --parallel 3` work via TypeScript

### Phase 3: Decommission Shell — 1 week

1. Reduce `scripts/genies` to ~20-line delegation wrapper
2. Remove bash functions that TypeScript replaces
3. Migrate remaining test assertions to vitest
4. Update install.sh to distribute compiled `genies-core`
5. **Validation:** All commands work without bash fallback (except hooks)

## Risks & Mitigations

| Risk | Severity | Mitigation |
|------|----------|------------|
| SDK `settingSources` doesn't load agent definitions correctly | High | AC-4 has explicit test; Phase 0 validates before committing to Phase 1 |
| SDK API changes break `query()` signature | Medium | Pin exact SDK version; abstract behind `PhaseExecutor` interface |
| `proper-lockfile` doesn't work across worktrees (different filesystems) | Medium | Test on macOS + Linux; fallback to `mkdir`-based locking |
| `commander` doesn't support the complex flag combinations genies uses | Low | commander handles positional + flag mixing; verified against arg list |
| tsx startup adds latency vs compiled JS | Low | Use tsx in dev; compile to JS for production install |
| Hooks order/timing differs from expected | Medium | Integration tests verify hook firing sequence |

## Implementation Guidance for Crafter

### Phase 0 Delivery Order (TDD)

1. **Test:** `genie-config.test.ts` — config loading from project/global/default paths
2. **Implement:** `config/genie-config.ts`
3. **Test:** `auth.test.ts` — OAuth vs API key detection, ambiguity warning
4. **Implement:** `environment/auth.ts`
5. **Test:** `check.test.ts` — all check categories (OK/WARN/FAIL)
6. **Implement:** `environment/check.ts`
7. **Test:** `cli.test.ts` — subcommand routing, exit code 127 fallback
8. **Implement:** `cli.ts` + `index.ts`
9. **Integration test:** `genies check` invoked via shell wrapper delegates to TypeScript
10. **Wire:** delegation preamble in `scripts/genies`

### Key Design Decisions for Crafter

- **Do NOT use classes** for simple modules — prefer exported functions with typed parameters. Classes only for stateful components (SessionManager, DaemonExecutor).
- **All git operations via `execa`** — never use Node.js git libraries (too heavy, different behavior from CLI).
- **All file writes atomic** — use `proper-lockfile` + temp file + rename pattern. Never write directly.
- **Log to stderr** — all diagnostic output to stderr so stdout is clean for programmatic consumers.
- **Exit code 127** — genies-core returns 127 for unrecognized subcommands, allowing shell fallback during migration.

## Architecture Decisions

### ADR-005: Accepted

ADR-005 (SDK-Integrated Orchestrator) is accepted with this design. The decision section and consequences are completed below. See `docs/decisions/ADR-005-sdk-integrated-orchestrator.md`.

## Diagram Updates

The L2 containers diagram should be updated after Phase 1 delivery to show `genies-core` (TypeScript) as a new container replacing the shell orchestration. The L1 system context is unchanged — external orchestrators still invoke `genies` as a CLI.
