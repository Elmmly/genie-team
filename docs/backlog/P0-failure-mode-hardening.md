---
spec_version: "1.0"
type: shaped-work
id: P0-failure-mode-hardening
title: "Harden genie-team against observed failure modes"
status: implemented
created: 2026-08-03
updated: 2026-08-03
appetite: medium
complexity: moderate
priority: P0
author: shaper
spec_ref: docs/specs/platform/installation-system.md
acceptance_criteria:
  - id: AC-1
    description: >-
      Session ground truth is automatic. A new SessionStart hook
      (matcher startup|resume|compact|clear) prints branch, last 5 commits,
      short git status, ahead/behind upstream, and advisory environment
      health (docker daemon, gh auth, listeners on common dev ports).
      Pure shell, always exit 0. Registered identically in hooks/hooks.json
      and install.sh's merge_hook_config, and a lint check fails when any
      hooks/*.sh registration drifts between the two (this also fixes the
      existing verify-stack.sh orphaning in hooks.json).
    status: pending
  - id: AC-2
    description: >-
      Post-compaction reinjection reconciles against reality:
      reinject-context.sh appends a live git-state section to the replayed
      session state, and emits git state even when no state file exists
      instead of exiting silently.
    status: pending
  - id: AC-3
    description: >-
      Session state tracking is complete and documented: track-artifacts.sh
      handles Edit payloads (registration matcher Write|Edit);
      track-command.sh records the HEAD SHA as base_commit and appends to a
      command-history section instead of overwriting the file; the state-file
      format is documented in schemas/session-state.schema.md. A new ambient
      rule rules/session-resumption.md requires re-deriving state from git
      after any resume/compaction before summarizing.
    status: pending
  - id: AC-4
    description: >-
      Root-cause discipline is in the default bugfix flow: the debugging
      skill's trigger covers any reported bug, regression, or failed fix
      (not only test failures during implementation), and /bugfix opens
      with the mandatory protocol — reproduce first, then answer
      environment-vs-code, root-cause-vs-symptom, and multiple-code-paths
      before writing code, then regression test, then fix.
    status: pending
  - id: AC-5
    description: >-
      Adversarial security review is a mandatory section of every default
      /discern review (XSS incl. inline SVG/HTML and CSS injection,
      authz/IDOR and on-behalf-of paths, SQL/command/template injection,
      secrets exposure, over-required fields, silently-failing credentials).
      Phantom subcommands /discern:security, /discern:performance,
      /discern:accept and /deliver:instrument are removed; behavior folds
      into the parent commands. agents/critic.md's security checklist is
      restored to at least CRITIC_SPEC depth including authz.
    status: pending
  - id: AC-6
    description: >-
      "Done" is a checklist, not a claim: /deliver requires an explicit
      verification block (exact test command with pass/fail counts,
      pre-existing failures named separately, build/lint state, docs
      updated, git status summary) before flipping status to implemented,
      and /done refuses to archive when the verification block is absent.
    status: pending
  - id: AC-7
    description: >-
      Creative work defaults reduce rejection rounds: /brand:image and the
      designer genie default to 3 labeled variants (A/B/C) with a one-line
      design-intent note each, restating the user's hard constraints and
      self-verifying each variant against them before presenting. A new
      ambient rule rules/content-editing.md preserves user framing when
      editing prose, forbids asserting motifs without quoting evidence, and
      requires flagging suspected typos instead of silently correcting.
    status: pending
  - id: AC-8
    description: >-
      Repo hygiene enables the above: the deprecated genies/ tree is
      deleted after porting unique content (critic authz checklist);
      references in schemas, README, CLAUDE.md, and install.sh are updated;
      make test runs real validation (hook smoke tests + vitest) instead of
      globbing a nonexistent tests/ directory; shellcheck covers the
      canonical hooks/ directory.
    status: pending
---

# Shaped Work Contract: Harden genie-team against observed failure modes

## Problem

Analysis of 17 real usage sessions (Jun–Aug 2026) surfaced six recurring failure
modes, each verified against this repo:

1. **Stale post-compaction recaps** — `hooks/reinject-context.sh` replays
   `.claude/session-state.md` without ever consulting git, and exits silently
   when no slash command started the session. `hooks/track-artifacts.sh` tracks
   only `Write`, so the state file undercounts changed files. Claude twice
   rediscovered already-landed commits and misreported uncommitted work.
2. **Silent environment breakage** — an expired GitHub token failed silently
   for ~2 months; a stopped Docker daemon and orphaned port-holders cost
   session-start time. Env-health logic exists only in `src/environment/check.ts`
   (never surfaced to the model), and `hooks/verify-stack.sh` is registered in
   install.sh's settings merge but missing from `hooks/hooks.json`.
3. **Symptom patches before root cause** — the debugging skill mandates
   reproduction-first but its trigger scopes it to test failures during
   implementation, and `/bugfix` never references it.
4. **Security review only when asked** — adversarial self-review caught real
   vulnerabilities (stored XSS via inline SVG, CSS injection) but only on
   request. `/discern:security` is advertised but has no command file; the
   critic's security checklist is a 3-checkbox stub that lost authz coverage
   in the genies→agents consolidation.
5. **"Done" as a claim** — `/deliver` flips `status: implemented` with no exit
   gate; `/done` archives with no verification.
6. **Serial rejection rounds on creative work** — regenerations dropped
   required elements; prose edits abandoned the user's framing.

## Appetite

Medium — one focused delivery pass. All changes are prompt/hook/rule artifacts
plus Makefile/install.sh plumbing; no new runtime code paths in the TypeScript
SDK.

## Solution Shape

Constraint (non-negotiable): **no new user-facing commands, no new rituals**.
Everything fires automatically (hooks), loads ambiently (rules), or strengthens
the default behavior of an existing command. Documented-but-unimplemented
subcommands fold into their parent's default flow and the phantom
advertisements are removed.

- **A. Session ground truth**: new `session-ground-truth.sh` SessionStart hook;
  git-reconciled reinjection; Edit-aware artifact tracking; command history
  with base-commit anchors; documented state-file schema; ambient
  session-resumption rule; registration-parity lint.
- **B. Root-cause discipline**: broadened debugging-skill trigger; mandatory
  protocol opening in `/bugfix`.
- **C. Default gates**: adversarial security pass in every `/discern`; deep
  critic security checklist; verification block gate in `/deliver`; archive
  refusal in `/done` without it.
- **D. Creative conventions**: 3 labeled variants with constraint
  self-verification in `/brand:image` + designer; ambient content-editing rule.
- **E. Hygiene**: delete `genies/`, update references, fix `make test`, add
  hook smoke tests, extend shellcheck coverage.

## No-Gos

- No changes to the TypeScript SDK runtime (`src/`) beyond what tests require.
- No new slash commands, flags that gate new behavior, or opt-in rituals.
- No network calls in hooks beyond the advisory `gh auth status` check.
- No blocking hooks — every hook stays advisory and exits 0.

## Rabbit Holes

- Do not rebuild session state as a daemon or JSON database — it stays a
  markdown file with a documented schema.
- Do not attempt full parity between `src/environment/check.ts` and the shell
  hook — the hook is advisory triage, not a health framework.
- Do not port the entire `genies/` spec corpus into `agents/` — only content
  verifiably lost in consolidation (critic authz checklist).

# Implementation

Delivered 2026-08-03 in a single pass (sections A–E).

## What changed

- **A — Session ground truth:** new `hooks/session-ground-truth.sh`
  (SessionStart, matcher `startup|resume|compact|clear`: branch, last 5
  commits, working-tree summary, ahead/behind, advisory docker/gh-auth/port
  health, all bounded by a perl-alarm timeout, always exit 0);
  `hooks/reinject-context.sh` now appends live git state and emits it even
  without a state file; `hooks/track-artifacts.sh` is Edit-aware and
  section-aware; `hooks/track-command.sh` records `base_commit` and appends
  to a capped Command History instead of overwriting; format documented in
  `schemas/session-state.schema.md`; new ambient rule
  `rules/session-resumption.md`. Registrations updated in BOTH
  `hooks/hooks.json` and install.sh's `merge_hook_config` (fixing the
  verify-stack.sh orphaning), with parity enforced by
  `scripts/validate/check-hook-registration.sh` (`make lint-hooks`).
- **B — Root cause:** debugging skill trigger broadened to any reported
  bug/regression/failed fix; `/bugfix` opens with the mandatory protocol
  (reproduce → environment-vs-code → root-vs-symptom → multi-path → test →
  fix), including under `--urgent`.
- **C — Default gates:** `/discern` gained a mandatory 7-vector adversarial
  security pass; phantom `:security`/`:performance`/`:accept` and
  `/deliver:instrument` advertisements removed; critic security checklist
  restored to CRITIC_SPEC depth (authz/IDOR, SVG XSS, CSS injection, silent
  credential failure) plus the lost performance checklist; `/deliver` Phase 5
  verification block gates `status: implemented`; `/done` refuses to archive
  without it.
- **D — Creative:** `/brand:image` + designer default to 3 labeled variants
  with design-intent notes and hard-constraint self-verification; new ambient
  rule `rules/content-editing.md`.
- **E — Hygiene:** `genies/` tree deleted (28 files) after porting critic
  security/performance checklists; references updated in README, CLAUDE.md,
  schema examples, install.sh (`--genies` now errors loudly); `make test` now
  fails when no tests exist and runs `tests/test_hooks.sh` (32 asserts) +
  vitest; shellcheck covers canonical `hooks/` and `tests/`.

### Verification
- **Tests:** `make test` → shell: 32 passed, 0 failed (tests/test_hooks.sh);
  vitest: 373 passed, 0 failed, 0 skipped (23 files)
- **Pre-existing failures:** one — `src/execution/batch-executor.test.ts`
  failed to import `p-limit` on the pristine tree (stale local
  `node_modules`, dependency present in package.json + lockfile). Environment
  cause, not code; fixed via `npm install`, after which all 373 pass. Not
  folded into the green claim above.
- **Build/lint:** `make lint` (shellcheck over commands/scripts/hooks/tests +
  install.sh, frontmatter + crossref validation, hook-registration parity) →
  clean; `bash -n install.sh` → clean
- **Docs updated:** README structure + hooks listing, CLAUDE.md repository
  structure, `schemas/session-state.schema.md` (new),
  `schemas/{design-document,execution-report,review-document}.schema.md`
  example paths
- **Lands as:** 5 hooks (1 new), 2 new rules, 1 new schema, 1 new validate
  script, tests/test_hooks.sh (new), 6 commands edited, 2 agents edited,
  1 skill edited, Makefile, install.sh, README.md, CLAUDE.md, this backlog
  item; genies/ (28 files) deleted

**Post-merge step:** run `./install.sh global --sync` and diff
`~/.claude/{rules,skills,commands,hooks}` against the repo — zero drift
expected (new hook + rules must land in the installed copies).

# End of Shaped Work Contract
