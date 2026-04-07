---
type: discover
topic: "Windows compatibility for genie-team"
reasoning_mode: deep
status: active
created: "2026-04-02"
---

# Opportunity Snapshot: Windows Compatibility

## 1. Discovery Question
**Original:** Investigate Windows compatibility for genie-team. Scan the codebase for every platform-specific assumption.
**Reframed:** Where do genie-team's platform assumptions create barriers for Windows users, and how severe is each barrier?

## 2. Observed Behaviors / Signals

### Shell Scripts (7 files, all `#!/bin/bash`)

Every shell script in the project assumes a Unix shell:

| File | Role | Severity |
|------|------|----------|
| `install.sh` | Primary installer (~650 lines) | **Critical** — entry point for new users |
| `scripts/genies` | Headless PDLC runner (~800+ lines) | **Critical** — main orchestration script |
| `scripts/genie-session` | Worktree session library (sourced by genies) | **Critical** — required for session management |
| `scripts/validate/lint-frontmatter-yaml.sh` | Pre-commit: YAML lint | Moderate — dev tooling |
| `scripts/validate/validate-frontmatter.sh` | Pre-commit: schema check | Moderate — dev tooling |
| `scripts/validate/check-crossrefs.sh` | Pre-commit: cross-ref integrity | Moderate — dev tooling |
| `scripts/validate/check-source-sync.sh` | Pre-commit: source/install sync | Moderate — dev tooling |
| `commands/execute.sh` | Headless execution wrapper | **High** — execution path |
| `hooks/reinject-context.sh` | Claude Code hook: session restore | **High** — depends on `jq`, `bash` |
| `hooks/track-artifacts.sh` | Claude Code hook: artifact tracking | **High** — depends on `jq`, `bash` |
| `hooks/track-command.sh` | Claude Code hook: command tracking | **High** — depends on `jq`, `bash` |
| `hooks/verify-stack.sh` | Claude Code hook: stack verification | **High** — depends on `jq`, `bash` |

**Key detail:** Claude Code on Windows uses Git Bash internally to run commands. This means `#!/bin/bash` scripts may execute correctly if invoked through Claude Code's Bash tool, but NOT when run directly from PowerShell or CMD.

### install.sh Platform-Specific Assumptions

- **Shell profile detection** (line 72-86): Checks for `~/.zshrc`, `~/.bash_profile`, `~/.bashrc`, `~/.profile` — no PowerShell profile support
- **PATH setup** (line 88-120): Appends `export PATH=...` to shell rc files — not Windows-compatible
- **`$HOME/.claude`** directory: Works on Windows if `$HOME` is defined (Git Bash sets it, PowerShell uses `$env:USERPROFILE`)
- **`chmod +x`** (lines 521, 530, 537, 645): No-op on Windows (NTFS has no execute bit)
- **`cp -r`**, **`rm -rf`**, **`mkdir -p`**: Git Bash provides these; native PowerShell does not
- **`command -v`**, **`basename`**, **`dirname`**: Git Bash builtins; not available in native PowerShell
- **Color codes via ANSI escapes**: Work in modern Windows Terminal, fail in older cmd.exe

### TypeScript — Path Construction

| Location | Code | Windows Impact |
|----------|------|----------------|
| `src/git/worktree.ts:14` | `root.split("/").at(-1)` | **Breaks on Windows** — Windows git returns backslash paths from some commands |
| `src/git/worktree.ts:48` | `` `${dirname(root)}/${repoName(root)}--${item}` `` | **Breaks on Windows** — hardcoded `/` separator instead of `path.join` |
| `src/core/frontmatter.ts:70` | `join(dirname(filePath), tmpName)` | **Works** — uses `path.join` |
| `src/execution/item-resolver.ts:29` | `join(projectRoot, "docs", "backlog")` | **Works** — uses `path.join` |
| `src/cli.ts:17-19` | `fileURLToPath`, `dirname`, `join` | **Works** — proper Node.js path APIs |
| `src/config/genie-config.ts:61-65` | `path.join`, `os.homedir()` | **Works** — cross-platform APIs |

### TypeScript — Process/Environment

| Location | Code | Windows Impact |
|----------|------|----------------|
| `src/environment/auth.ts:13` | `process.env.ANTHROPIC_API_KEY` | **Works** — cross-platform |
| `src/cli.ts:109` | `process.cwd()` | **Works** — cross-platform |
| `src/execution/daemon.ts:30` | `process.cwd()` | **Works** — cross-platform |
| `src/environment/check.ts:19` | `execa("claude", ["--version"])` | **Needs testing** — `claude` must be on PATH |
| `src/environment/check.ts:36` | `execa("git", [...])` | **Works** — git is required on Windows |
| `src/environment/check.ts:64` | `execa("gh", [...])` | **Needs testing** — gh available via `winget` |
| `src/core/phase-executor.ts` | Claude Agent SDK `query()` | **Needs testing** — SDK should work cross-platform |

### TypeScript — File Operations

| Location | Code | Windows Impact |
|----------|------|----------------|
| `src/core/frontmatter.ts` | `readFile`, `writeFile`, `rename` | **Works** — Node.js handles path normalization |
| `src/hooks/phase-hooks.ts` | `appendFile`, `mkdir` | **Works** — cross-platform |
| `src/execution/item-resolver.ts` | `readdir` | **Works** — cross-platform |

### package.json

- **`bin` field:** `"genies-core": "dist/index.js"` — uses `#!/usr/bin/env node` shebang (line 1 of index.ts). `npm link` / `npx` handles this on Windows by creating `.cmd` wrappers.
- **Scripts:** `tsc`, `tsx`, `vitest` — all cross-platform Node.js tools.
- **Dependencies:** `execa`, `js-yaml`, `commander`, `p-limit`, `@anthropic-ai/claude-agent-sdk` — all pure JS or cross-platform.

### Hook Configuration

The `install.sh` configures Claude Code hooks with commands like:
```json
"command": "bash ${cmd_prefix}/track-command.sh"
```

On Windows, Claude Code uses Git Bash internally. If the hook invocation goes through Claude Code's shell (Git Bash), these will work. If invoked by the system shell directly, they will fail in PowerShell/CMD.

## 3. Pain Points / Friction Areas

### P1: No Windows installer
The entire installation path (`install.sh`) is a bash script. A Windows user cannot install genie-team without Git Bash or WSL. There is no PowerShell equivalent, no `.bat`/`.cmd` installer, and no `winget` package.

### P2: Headless runner is bash-only
`scripts/genies` (the main orchestration script) is ~800+ lines of bash. This is the primary entry point for headless/CI usage. It cannot run in native Windows environments.

### P3: Hardcoded forward-slash path construction
`worktree.ts` uses string concatenation with `/` instead of `path.join()` in two places. Git on Windows sometimes returns paths with backslashes, causing path mismatches.

### P4: Workaround exists but is undocumented
Claude Code runs natively on Windows (with Git Bash required). The TypeScript SDK layer (`genies-core`) is mostly cross-platform. But neither the README nor install docs mention Windows at all.

### P5: Validation scripts assume Unix toolchain
Pre-commit hooks use `awk`, `sed`, `head`, `grep`, `diff`, `jq` — available in Git Bash but not native PowerShell. Users who run pre-commit from PowerShell would see failures.

## 4. JTBD / User Moments

**Primary Job:** "When setting up a development workflow on a Windows machine, a developer wants to install and run genie-team so they can use structured AI-assisted product development without switching to macOS or Linux."

**Secondary Job:** "When running CI/CD on Windows GitHub Actions runners, a team wants to execute headless genie phases so they can automate their PDLC pipeline on existing infrastructure."

## 5. Assumptions & Evidence

| Assumption | Type | Confidence | Evidence For | Evidence Against |
|------------|------|------------|--------------|------------------|
| Windows users exist or will exist for this project | value | low | Claude Code officially supports Windows; OSS projects attract diverse platforms; GitHub Actions has windows-latest runners | No issues filed requesting Windows support; current user base appears macOS-only. **Justification:** No direct signal of demand; this is speculative future-proofing |
| Claude Code on Windows can run bash hooks via Git Bash | feasibility | medium | Official docs state "Claude Code uses Git Bash internally to run commands"; hooks use `"type": "command"` with `bash` prefix | Not tested in this codebase; edge cases with path translation between Git Bash and Windows native paths. **Justification:** Documented behavior but unverified in practice for this specific hook configuration |
| The TypeScript `genies-core` layer works on Windows | feasibility | medium | Uses `path.join`, `os.homedir()`, Node.js fs APIs, and `execa` (which handles `.cmd` wrappers). Two worktree path bugs are the main risk | Two string-concatenation path bugs in `worktree.ts`. `execa` calling `git` should work since git is required. **Justification:** 90% of TS code is cross-platform; the two path bugs are isolated and fixable |
| The bash `scripts/genies` is the primary blocker | feasibility | high | 800+ line bash script with `set -euo pipefail`, `BASH_SOURCE`, `mktemp`, `date -u`, process substitution, arrays — deep bash dependency | The TypeScript `genies-core` is designed to replace it (SDK delegation at lines 19-36 of genies). **Justification:** The TS core already handles `run`, `daemon`, `session` subcommands; bash handles `quality`, `help`, and legacy paths |
| WSL is an acceptable workaround | usability | medium | Claude Code docs list WSL as Option 2; WSL 2 is widely available on Windows 10/11; performance is near-native | WSL adds setup friction; corporate environments may restrict WSL; WSL 1 does not support Claude Code sandboxing. **Justification:** Works but adds a dependency and complexity |
| `npm link` works on Windows | feasibility | high | Node.js creates `.cmd` shim files on Windows for `bin` entries; widely used pattern | Some edge cases with symlinks on Windows (may need Developer Mode). **Justification:** Standard npm behavior, documented and widely tested |
| LLM API SDKs work on Windows | feasibility | high | `@anthropic-ai/sdk`, `openai`, `@google/genai` are pure JavaScript/TypeScript packages with no native bindings | No evidence against. **Justification:** These are HTTP client libraries with no platform-specific code |

## 6. Technical Signals

- **Feasibility:** moderate — TypeScript layer is ~90% cross-platform already; two path bugs are easy fixes. The real challenge is the bash scripts.
- **Constraints:**
  - `install.sh` would need a parallel PowerShell installer or a cross-platform Node.js installer
  - `scripts/genies` bash runner is being superseded by TypeScript `genies-core` — completing that migration would naturally solve Windows compatibility for the headless runner
  - Hooks must work through Claude Code's Git Bash shell — needs real-device testing
  - Validation scripts could be rewritten in Node.js for cross-platform support
- **Needs Architect spike:** no — the path forward is clear: fix TS path bugs, complete TS migration, test on Windows

## 7. Opportunity Areas (Unshaped)

1. **Path construction correctness in worktree.ts** — Two instances of hardcoded `/` separator break on Windows. This is a latent bug regardless of Windows priority. (`worktreeDir` on line 48, `repoName` on line 14)

2. **SDK-first migration completion** — The TypeScript `genies-core` already handles core subcommands. Completing the migration to TS eliminates the bash dependency for the primary execution path. This aligns with the existing architecture direction (bash falls back to TS via SDK delegation).

3. **Installer platform gap** — No way to install genie-team on Windows without bash. A Node.js-based installer (`npx genie-team install`) would be cross-platform by default.

4. **Hook compatibility uncertainty** — Claude Code hooks invoke `bash` scripts with `jq`. On Windows, this flows through Git Bash, but it is untested. This is a black box for the project.

5. **Documentation gap** — No mention of Windows anywhere in project docs. Even if WSL is the recommended path, documenting it would prevent confusion.

## 8. Evidence Gaps

- **No real Windows testing data** — Zero evidence of anyone running genie-team on Windows. All test fixtures use Unix paths (`/Users/me/project`).
- **Claude Agent SDK on Windows** — The `@anthropic-ai/claude-agent-sdk` `query()` function has not been verified on Windows. It likely works (HTTP + stdio), but no confirmation.
- **Git Bash path translation in hooks** — When Claude Code on Windows invokes `bash hooks/track-artifacts.sh`, does the `cwd` value use backslashes or forward slashes? Path handling between Git Bash and Windows is notoriously inconsistent.
- **User demand signal** — No issues, requests, or telemetry indicating Windows users want this. The investment case rests on future reach, not current pain.
- **Corporate Windows constraints** — Unknown whether target users' corporate environments restrict WSL, Git Bash, or both.

## 9. Routing Recommendation

- [x] **Ready for Shaper** — Problem understood
- [ ] **Needs Navigator Decision** — Strategic question

**Rationale:** The technical landscape is clear. The two `worktree.ts` path bugs should be fixed regardless of Windows priority (they are correctness issues). Beyond that, a Navigator decision is needed: is Windows compatibility worth investing in now, or is WSL-as-workaround acceptable? The answer depends on user demand signals that do not currently exist.

If the Navigator decides to proceed, the natural path is:
1. Fix the two path bugs in `worktree.ts` (small, safe)
2. Complete the TS migration of `scripts/genies` to `genies-core` (already in progress architecturally)
3. Add a cross-platform Node.js installer as an alternative to `install.sh`
4. Test hooks on Windows with Git Bash
5. Document Windows support status

## Appendix: Full Finding Inventory

### Breaks on Windows (native PowerShell/CMD)

| Item | File | Line(s) | Why |
|------|------|---------|-----|
| Bash installer | `install.sh` | All | `#!/bin/bash`, shell profile detection, `chmod`, ANSI colors |
| Headless runner | `scripts/genies` | All | 800+ lines of bash with arrays, process substitution, `BASH_SOURCE` |
| Session library | `scripts/genie-session` | All | Sourced bash library |
| Execution wrapper | `commands/execute.sh` | All | Bash script |
| All hooks | `hooks/*.sh` | All | Bash + `jq` dependency |
| All validators | `scripts/validate/*.sh` | All | Bash + `awk`, `sed`, `head`, `grep`, `diff` |
| `worktreeDir()` | `src/git/worktree.ts` | 48 | Hardcoded `/` instead of `path.join` |
| `repoName()` | `src/git/worktree.ts` | 14 | `root.split("/")` — fails on backslash paths |
| Makefile | `Makefile` | 4 | `SHELL := /bin/bash` |

### Works on Windows (via Git Bash or Node.js)

| Item | File | Why |
|------|------|-----|
| All `path.join` / `path.dirname` usage | Various TS files | Node.js handles platform paths |
| `os.homedir()` | `src/config/genie-config.ts` | Returns `C:\Users\...` on Windows |
| `process.env` access | `src/environment/auth.ts` | Cross-platform |
| `fs.readFile/writeFile/existsSync` | `src/core/frontmatter.ts` | Node.js normalizes paths |
| `execa("git", [...])` | Various TS files | Git for Windows is a prerequisite |
| npm `bin` field | `package.json` | npm creates `.cmd` wrappers on Windows |
| All npm dependencies | `package.json` | Pure JS, no native bindings |

### Needs Testing

| Item | File | Why |
|------|------|-----|
| `execa("claude", ["--version"])` | `src/environment/check.ts` | Depends on `claude` being on PATH |
| `execa("gh", [...])` | `src/environment/check.ts` | `gh` available via `winget` but untested |
| Claude Agent SDK `query()` | `src/core/phase-executor.ts` | HTTP/stdio should work, unverified |
| Hooks via Claude Code's Git Bash | `hooks/*.sh` | Claude Code uses Git Bash internally but path translation is uncertain |
| `npm link` with symlinks | `package.json` | May need Developer Mode on Windows |
