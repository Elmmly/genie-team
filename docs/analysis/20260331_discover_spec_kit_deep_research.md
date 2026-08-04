---
type: discover
topic: "GitHub spec-kit deep research"
reasoning_mode: deep
status: active
created: "2026-03-31"
---

# Opportunity Snapshot: GitHub spec-kit Deep Research

## 1. Discovery Question

**Original:** Research the GitHub spec-kit repository in depth -- purpose, architecture, spec format, workflow, CLI/tooling, AI integration, document types, quality gates.

**Reframed:** What design decisions and patterns does spec-kit use for specification-driven development, and how do they compare to the genie-team approach?

## 2. What spec-kit Is

### Purpose and Philosophy

spec-kit is an open-source toolkit (MIT license) from GitHub enabling **Spec-Driven Development (SDD)** -- a methodology that inverts traditional development by making specifications executable rather than aspirational. The core thesis: specifications should generate working implementations, not merely guide them.

The key philosophical claim: "Specifications don't serve code -- code serves specifications." This is a power inversion where the PRD/spec becomes the generative source, and the gap between specification and implementation is eliminated rather than narrowed.

**Repository:** `github/spec-kit` -- 84.1k stars, 7.2k forks (as of March 2026).

**Target Audience:** Development teams using AI coding assistants who want structured specification workflows. Supports 23+ AI agents including Claude Code, GitHub Copilot, Cursor, Gemini CLI, Windsurf, and others.

### Key Claim: 12 Hours to 15 Minutes

The methodology document claims that traditional specification work requiring ~12 hours can be accomplished in ~15 minutes through template-based automation and structural consistency.

## 3. Architecture

### Technology Stack

- **Language:** Python 3.11+
- **Package Manager:** uv (Astral)
- **CLI Framework:** Typer + Click + Rich
- **Build System:** Hatchling
- **Package Name:** `specify-cli` (published as `specify` command)
- **Dependencies:** httpx, platformdirs, pyyaml, packaging, pathspec, json5, truststore

### Repository Structure

```
spec-kit/
  .devcontainer/           # Dev container config
  .github/                 # CI workflows
  docs/                    # Documentation site
  extensions/              # Extension catalog system
  media/                   # Logo/branding
  newsletters/             # Community newsletters
  presets/                 # Preset catalog system
  scripts/                 # Shell utilities (branch creation, context updates)
  src/specify_cli/         # Main CLI application
    __init__.py
    agents.py              # 23-agent configuration registry
    extensions.py          # Extension lifecycle manager
    presets.py             # Preset/template resolution
    integrations/          # External system integrations
  templates/               # Core templates
    commands/              # AI agent command templates (9 commands)
    spec-template.md
    plan-template.md
    tasks-template.md
    constitution-template.md
    checklist-template.md
    agent-file-template.md
    vscode-settings.json
  tests/                   # pytest suite
  AGENTS.md                # Agent integration docs
  spec-driven.md           # SDD methodology guide
  pyproject.toml
```

### Generated Project Structure

When `specify init <project-name>` runs, it creates:

```
.specify/
  memory/
    constitution.md        # Project principles (immutable)
  specs/
    {branch-name}/         # One directory per feature
      spec.md              # Feature specification
      plan.md              # Implementation plan
      tasks.md             # Ordered task list
      research.md          # Phase 0 research
      data-model.md        # Entity definitions
      quickstart.md        # Quick reference
      contracts/           # Interface definitions
      checklists/          # Quality validation checklists
  templates/
    overrides/             # User template overrides
  extensions/              # Installed extensions
  extensions.yml           # Hook configuration
  init-options.json        # Init configuration
```

### Key Architectural Patterns

1. **Template-driven generation:** All documents are generated from markdown templates with placeholder syntax. Templates instruct LLM behavior (e.g., "focus on what and why, not how").

2. **Script-based orchestration:** Shell scripts (Bash + PowerShell) handle branch creation, context updates, and file discovery. Commands call these scripts and parse JSON output.

3. **Agent-agnostic command system:** A central `AGENT_CONFIG` dictionary maps 23 agents to their directory paths, file formats (markdown/TOML), argument syntax (`$ARGUMENTS` vs `{{args}}`), and file extensions. One template renders into agent-specific formats.

4. **Four-tier template resolution:** Presets use a priority stack: project overrides > installed presets > extension templates > core templates.

5. **Extension hook system:** `.specify/extensions.yml` defines before/after hooks for each command, with condition evaluation (`config.key == 'value'`, `env.VAR is set`).

## 4. Spec Format

### Feature Specification (spec-template.md)

The spec is a flat markdown document (no YAML frontmatter) with:

```markdown
# Feature Specification: [FEATURE NAME]

**Feature Branch**: `[###-feature-name]`
**Created**: [DATE]
**Status**: Draft
**Input**: User description: "$ARGUMENTS"
```

**Required Sections:**

| Section | Content |
|---------|---------|
| User Scenarios & Testing | Prioritized user stories (P1/P2/P3) with Given-When-Then acceptance scenarios |
| Functional Requirements | FR-001 through FR-NNN with "System MUST [capability]" statements |
| Key Entities | Data model descriptions and relationships |
| Success Criteria | SC-001 through SC-NNN with measurable outcomes (technology-agnostic) |
| Assumptions | Scope boundaries, user context, dependencies |

**Key Design Choices:**

- **No YAML frontmatter** -- purely markdown with inline metadata fields
- **Numbered requirements** -- FR-001, SC-001 with stable keys for cross-referencing
- **Ambiguity markers** -- `[NEEDS CLARIFICATION: specific question]` tags (max 3)
- **Priority labels** -- P1/P2/P3 on user stories
- **Technology-agnostic** -- specs describe WHAT, never HOW
- **Acceptance scenarios** -- Given-When-Then format within user stories

### Implementation Plan (plan-template.md)

Follows the spec with technical decisions:

- **Technical Context** block: language, dependencies, storage, testing framework, platform, performance goals
- **Constitution Check** gate: validates against project principles before proceeding
- **Three source code layout options** (single project, web app, mobile+API)
- **Phase 0: Research** -- extracts unknowns into research.md
- **Phase 1: Design** -- generates data-model.md, contracts/, quickstart.md
- **Complexity Tracking** -- justification table for constitution violations

### Task List (tasks-template.md)

Structured task breakdown with:

```
- [ ] [TaskID] [P?] [Story?] Description with file path
```

- **Five phases:** Setup > Foundational > User Stories (by priority) > Polish
- **Parallel markers:** `[P]` for concurrent execution
- **Story labels:** `[US1]`, `[US2]` for story grouping
- **File paths required** on every task
- **Tests precede implementation** (TDD ordering)

### Constitution (constitution-template.md)

Project-level governance document with:

- 5+ named principles (e.g., Library-First, CLI Interface, Test-First)
- Governance rules for compliance verification
- Versioned with ratification date
- Functions as "architectural compile-time checks" -- referenced in plan templates as "Phase -1 Gates"

### Checklist (checklist-template.md)

Quality validation with:
- Categorized checkbox items (CHK001, CHK002...)
- Linked to spec, plan, and implementation context
- Generated per-feature, not global

## 5. Workflow: How Specs Move Through Stages

### Linear 5-Command Pipeline

```
/speckit.constitution  (once per project)
      |
/speckit.specify  --> spec.md
      |
/speckit.clarify  --> updates spec.md (optional, reduces ambiguity)
      |
/speckit.plan     --> plan.md + research.md + data-model.md + contracts/
      |
/speckit.tasks    --> tasks.md
      |
/speckit.implement --> code (phase-by-phase execution)
      |
/speckit.analyze  --> consistency report (optional, read-only)
/speckit.checklist --> quality checklist (optional)
```

### Stage Details

1. **Constitution** (project-level, one-time): Establishes immutable architectural principles. Nine articles in the reference implementation covering Library-First, CLI Interface, Test-First, Simplicity, Anti-Abstraction, Integration-First Testing.

2. **Specify** (per-feature): Transforms natural language description into structured spec. Creates feature branch and directory. Generates requirements checklist. Max 3 ambiguity markers. Validates against 12 quality items (up to 3 iterations).

3. **Clarify** (optional per-feature): Audits spec against 10 taxonomy categories. Asks up to 5 targeted questions (one at a time). Multiple-choice or short-phrase answers. Integrates answers into spec with `## Clarifications` section.

4. **Plan** (per-feature): Reads spec + constitution. Fills technical context. Runs constitution compliance check. Executes Phase 0 (research) and Phase 1 (design). Generates data-model.md, contracts/, quickstart.md.

5. **Tasks** (per-feature): Reads plan + spec. Extracts tech stack, user stories, entities. Generates phased task list with dependency ordering and parallelization.

6. **Implement** (per-feature): Executes tasks phase-by-phase. Validates prerequisites (checklists, ignore files). Respects TDD ordering (tests before implementation). Tracks completion by marking `[X]` in tasks.md.

7. **Analyze** (optional, read-only): Cross-artifact consistency checker. Validates spec/plan/tasks for duplications, ambiguities, coverage gaps, constitution violations. Severity levels: CRITICAL/HIGH/MEDIUM/LOW. Max 50 findings.

### Feature Branch Model

- Branch naming: `{number}-{feature-name}` (sequential or timestamp-based)
- One directory per feature under `.specify/specs/{branch-name}/`
- All artifacts co-located in feature directory

### Hook System

Extensions can attach before/after hooks to any command:
- `hooks.before_specify`, `hooks.after_specify`, etc.
- Hooks have: extension, command, enabled, optional, prompt, description, condition
- Conditions: `config.key is set`, `config.key == 'value'`, `env.VAR is set`
- Optional hooks prompt user; mandatory hooks auto-execute

## 6. CLI Tooling

### Installation

```bash
# Persistent (recommended)
uv tool install specify-cli --from git+https://github.com/github/spec-kit.git@vX.Y.Z

# One-time
uvx --from git+https://github.com/github/spec-kit.git@vX.Y.Z specify init <PROJECT_NAME>

# Air-gapped (enterprise)
pip download specify-cli --from ... && pip install specify-cli-*.whl
```

### CLI Commands

| Command | Purpose |
|---------|---------|
| `specify init <name> --ai <agent>` | Bootstrap project with agent-specific commands |
| `specify init <name> --ai <agent> --ai-skills` | Also generate SKILL.md files |
| `specify init <name> --ai generic --ai-commands-dir <dir>` | Generic agent support |

The CLI itself is a bootstrapper -- it generates the `.specify/` directory structure and installs command templates. The actual workflow commands (`/speckit.specify`, etc.) run inside the AI agent, not as CLI subcommands.

### Extension CLI

| Command | Purpose |
|---------|---------|
| `specify ext install <path-or-zip>` | Install extension |
| `specify ext remove <id>` | Remove extension |
| `specify ext list` | List installed extensions |
| `specify ext search <query>` | Search catalogs |

### Preset CLI

| Command | Purpose |
|---------|---------|
| `specify preset install <path-or-zip>` | Install preset |
| `specify preset remove <id>` | Remove preset |
| `specify preset list` | List installed presets |

## 7. AI/LLM Integration

### Agent Configuration Registry

The `AGENT_CONFIG` dictionary in `agents.py` is the single source of truth for 23 agents:

```python
AGENT_CONFIG = {
    "claude": {
        "dir": ".claude/commands",
        "format": "markdown",
        "args": "$ARGUMENTS",
        "extension": ".md"
    },
    "gemini": {
        "dir": ".gemini/commands",
        "format": "toml",
        "args": "{{args}}",
        "extension": ".toml"
    },
    "copilot": {
        "dir": ".github/agents",
        "format": "markdown",
        "args": "$ARGUMENTS",
        "extension": ".agent.md"
    },
    # ... 20 more agents
}
```

### How It Works with Claude Code

1. `specify init myproject --ai claude` copies command templates to `.claude/commands/`:
   - `speckit.specify.md`
   - `speckit.plan.md`
   - `speckit.tasks.md`
   - `speckit.implement.md`
   - `speckit.clarify.md`
   - `speckit.analyze.md`
   - `speckit.checklist.md`
   - `speckit.constitution.md`
   - `speckit.taskstoissues.md`

2. User invokes via Claude Code slash commands: `/speckit.specify Build a todo app`

3. The command template is a detailed prompt that instructs the LLM how to:
   - Parse user input
   - Run prerequisite scripts
   - Load templates
   - Generate structured output
   - Validate quality
   - Report results

4. Templates reference script paths (`.specify/scripts/`) for branch creation, context updates, file discovery.

### Agent-File Template

An auto-generated documentation file (like AGENTS.md or CLAUDE.md) that consolidates:
- Active technologies from all plan.md files
- Project structure from plan specifications
- CLI commands for active tech stacks
- Code style guidelines per language
- Recent feature changes

This creates a self-updating project context file for the AI agent.

## 8. Document Types

| Document | Location | Purpose | Lifecycle |
|----------|----------|---------|-----------|
| Constitution | `.specify/memory/constitution.md` | Immutable project principles | Created once, rarely amended |
| Feature Spec | `.specify/specs/{branch}/spec.md` | What to build (requirements) | Created by /specify, refined by /clarify |
| Implementation Plan | `.specify/specs/{branch}/plan.md` | How to build it (technical) | Created by /plan |
| Research | `.specify/specs/{branch}/research.md` | Phase 0 unknowns resolved | Created by /plan |
| Data Model | `.specify/specs/{branch}/data-model.md` | Entity definitions | Created by /plan |
| Contracts | `.specify/specs/{branch}/contracts/*.md` | Interface definitions | Created by /plan |
| Quick Start | `.specify/specs/{branch}/quickstart.md` | Developer reference | Created by /plan |
| Task List | `.specify/specs/{branch}/tasks.md` | Ordered implementation tasks | Created by /tasks |
| Checklists | `.specify/specs/{branch}/checklists/*.md` | Quality validation | Created by /specify, /checklist |
| Analysis Report | (stdout) | Consistency findings | Created by /analyze (read-only) |
| Agent File | `.claude/CLAUDE.md` (or equivalent) | AI context document | Auto-regenerated |
| Extension Config | `.specify/extensions.yml` | Hook configuration | Modified by extension install |

## 9. Quality Gates

### Spec Quality Validation (/specify)

- 12-item quality checklist generated automatically
- Validates content, requirements, and readiness
- Up to 3 validation iterations
- Maximum 3 `[NEEDS CLARIFICATION]` markers
- Success criteria must be measurable, technology-agnostic, user-focused

### Constitution Compliance (/plan)

- "Phase -1 Gates" -- checked before Phase 0 research and after Phase 1 design
- Any MUST principle violation is automatically CRITICAL
- Complexity justification table required for exceptions

### Cross-Artifact Consistency (/analyze)

- Read-only checker across spec/plan/tasks
- Six detection passes: duplication, ambiguity, underspecification, constitution alignment, coverage gaps, inconsistency
- Four severity levels: CRITICAL, HIGH, MEDIUM, LOW
- Maximum 50 findings per run
- Coverage metrics: requirements with zero tasks, orphan tasks
- Semantic model built from FR/SC numbering

### Checklist Prerequisites (/implement)

- Validates checklist completion before implementation begins
- Incomplete checklists prompt user confirmation

### Extension Manifest Validation

- Schema version enforcement
- Semantic versioning required
- Command naming pattern: `speckit.{extension}.{command}`
- Namespace conflict detection (cannot shadow core commands)
- Path traversal prevention in ZIP extraction
- HTTPS enforcement for catalog URLs

## 10. Extension and Preset System

### Extensions

Add new capabilities (commands, hooks) without modifying core:

- **Manifest:** `extension.yml` with schema version, metadata, provides (commands, hooks)
- **Registry:** `.registry` JSON file tracks installed extensions with priority
- **Catalogs:** Multi-catalog support with official + community catalogs
- **Hooks:** Before/after hooks on any core command
- **40+ community extensions** including: MAQA (QA with CI gates), Jira/Linear/Azure DevOps integrations, code review, test traceability, health diagnostics, DocGuard

### Presets

Customize templates without adding features:

- **Purpose:** Terminology changes, compliance requirements, domain-specific formats
- **Resolution:** Four-tier stack (project overrides > presets > extensions > core)
- **No new commands** -- presets only swap templates
- **Use cases:** Compliance (SOC2, HIPAA), domain language, team conventions

## 11. Key Differences from Genie-Team

### Shared Foundation: Specs as Connective Tissue to Code

Both systems use specs as **direct connective tissue to code generation**, not as passive documentation. The spec-to-code chain is structurally similar:

| Step | spec-kit | genie-team |
|------|----------|------------|
| **Spec → requirement** | FR-001: "System MUST..." | AC-1: description in frontmatter |
| **Requirement → test target** | Task references FR-001 | Test describes AC-1: `describe("AC-1: ...")` |
| **Test → implementation** | /implement executes tasks | /deliver TDD red-green-refactor |
| **Implementation → verification** | /checklist validates CHK items | /discern evaluates each AC → met/unmet |

The philosophical difference is NOT "generates code vs describes behavior" — both generate code from specs. The difference is **connection lifetime and knowledge accumulation**.

### The Real Axis: Disposable Blueprints vs Persistent Connective Tissue

**spec-kit** treats specs as **disposable blueprints**. A spec lives in `.specify/specs/{branch}/`, drives one feature's code generation, and is effectively done when the branch merges. The next feature touching the same capability starts with a blank spec — no memory of prior design decisions, implementation evidence, or review verdicts.

**genie-team** treats specs as **persistent connective tissue**. A spec at `docs/specs/{domain}/{capability}.md` survives every feature that touches it, accumulating knowledge across the lifecycle:

```
After /define:  acceptance_criteria (all pending)
After /design:  + Design Constraints section
After /deliver: + Implementation Evidence (test paths, source paths)
After /discern: + Review Verdict, AC statuses → met
After next feature: + new ACs appended, behavioral delta documented, cycle repeats
```

### Comparison Table

| Dimension | spec-kit | genie-team |
|-----------|----------|------------|
| **Spec-to-code relationship** | 1:1 (one spec, one feature) | 1:many (one spec, many features over time) |
| **Spec lifecycle** | Born with feature branch, dies on merge | Permanent, accumulates across features |
| **Cross-feature learning** | None — each feature starts fresh | Spec retains constraints, evidence, verdicts |
| **Behavioral delta** | No concept (specs don't persist) | Explicit: current behavior vs proposed changes |
| **AC traceability** | FR-001 → task → code (then gone) | AC-1 → test → code → verdict (permanent) |
| **Spec format** | Flat markdown, no YAML frontmatter, FR/SC numbering | YAML frontmatter with structured AC list, body sections |
| **Organization** | By feature branch (temporal) | By domain > capability (product architecture) |
| **Workflow** | Linear pipeline (specify > plan > tasks > implement) | Cyclic (discover > define > design > deliver > discern) |
| **Discovery phase** | None — starts with /specify | Scout explores problem space before defining |
| **Review phase** | /analyze (read-only consistency check) | /discern (Critic with accept/reject verdict + AC status updates) |
| **Integration verification** | None | Mandatory wiring check: "is this reachable from running system, not just mock-passing?" |
| **Constitution** | Project-wide immutable principles with enforcement gates | No equivalent (CLAUDE.md + rules files serve partial role) |
| **AI integration** | 23 agents via command templates | Claude Code only, via agents + commands + skills |
| **Extension system** | Full plugin architecture (manifests, catalogs, hooks) | No plugin system (skills are static) |
| **CLI** | Python CLI (`specify`) for bootstrapping | Shell script (`install.sh`) for copying files |
| **Ambiguity handling** | /clarify command with structured Q&A | Scout discovery surfaces assumptions |
| **Task generation** | Automated from plan (/tasks) | Implicit in /deliver (TDD drives task order) |
| **Research phase** | Phase 0 embedded in /plan (unknowns → research.md) | Separate /discover step before /define |
| **Project principles** | Constitution with numbered articles and violation justification | Rules files, CLAUDE.md |
| **Maturity** | 84k stars, 40+ extensions, multi-agent | Internal project, Claude Code only |

### Where spec-kit Is Stronger

1. **Constitution guardrails** — Immutable principles enforced as "Phase -1 gates" during planning, with structured violation justification (why needed + simpler alternative rejected). NON-NEGOTIABLE markers create hard gates with no escape hatch.
2. **Extension/preset architecture** — Four-tier template resolution, manifest validation, hook system, multi-catalog support. 40+ community extensions.
3. **Multi-agent support** — 23 agents via clean `AGENT_CONFIG` registry. One template renders into agent-specific formats.
4. **Automated task decomposition** — /tasks generates ordered, parallelizable implementation tasks with file paths and dependency markers from plans.
5. **Structured ambiguity reduction** — /clarify uses 10 taxonomy categories with targeted Q&A (max 5 questions).
6. **Cross-artifact consistency** — /analyze validates spec/plan/tasks for duplications, coverage gaps, and constitution violations with severity levels.
7. **Explicit research phase** — Phase 0 in /plan extracts unknowns into research.md before design begins.

### Where genie-team Is Stronger

1. **Persistent spec knowledge** — Specs accumulate design constraints, implementation evidence, and review verdicts across features. Domain READMEs auto-generated with AC status counts.
2. **Discovery phase** — Scout explores problem space, surfaces assumptions, uses JTBD/Teresa Torres frameworks before anyone writes a spec.
3. **Review with teeth** — Critic produces accept/reject verdicts with AC-level status tracking that updates the persistent spec. Not just consistency checking.
4. **Behavioral delta tracking** — When modifying existing capability, backlog documents current vs proposed behavior against the persistent spec.
5. **Integration wiring verification** — Mandatory check that implementation is reachable from the running system, not just passing mock tests.
6. **Cyclic workflow** — 7 D's allow iteration (discern → deliver rework, diagnose → tidy maintenance). spec-kit is strictly linear.
7. **Maintenance cycle** — /diagnose + /tidy for ongoing codebase health. spec-kit has no post-implementation workflow.
8. **Problem-first framing** — Shaper reframes solution-loaded requests as problems with appetite boundaries.

## 12. Assumptions & Evidence

| Assumption | Type | Confidence | Evidence For | Evidence Against |
|------------|------|------------|--------------|------------------|
| spec-kit's linear pipeline suits greenfield projects well | Value | High | Workflow is explicitly specify-first; 84k stars indicate adoption | No discovery phase limits applicability to well-understood problems |
| Constitution model prevents architectural drift | Feasibility | Moderate | Phase -1 gates in plan template; constitution checks are mandatory | Constitution is per-project, one-time -- may not evolve with project |
| 23-agent support is a significant adoption driver | Value | High | Broadest agent coverage in this space; generic fallback available | Quality may vary across agents -- each just gets template rendering |
| Extension system adds meaningful ecosystem value | Value | Moderate | 40+ community extensions; full manifest/catalog/hook architecture | Extension quality is unverified; community catalog is "discovery only" |
| Template-driven LLM guidance produces consistent specs | Usability | Moderate | Templates encode anti-patterns, clarification limits, quality checklists | LLM compliance with complex templates varies; no automated validation of output |
| Feature-branch-scoped specs are sufficient for knowledge retention | Value | Low | Clean per-feature isolation | No persistent capability knowledge -- specs die with features; no cross-feature learning |

### Evidence Grade Justifications

- **84k stars / 7.2k forks:** Strong signal for adoption but does not prove production usage depth. Star counts can inflate from trending/HN effects. Still, this is very high for a dev-tools repo.
- **23-agent support:** Verified by reading `AGENT_CONFIG` dictionary in `agents.py`. Each agent has directory, format, args, and extension mapped. Coverage is real but depth (how well each agent handles the prompts) is unverified.
- **40+ extensions:** Claimed in README and referenced in catalog system. `catalog.community.json` exists but individual extension quality is not assessed.
- **No YAML frontmatter in specs:** Confirmed by reading `spec-template.md`. Metadata is inline markdown fields (`**Status**: Draft`), not structured data.

## 13. Technical Signals

- **Feasibility:** N/A (research-only task)
- **Constraints:** spec-kit requires Python 3.11+ and uv; genie-team is shell+markdown
- **Needs Architect spike:** No

## 14. Opportunity Areas (Unshaped)

### Genie-team Differentiators to Articulate

1. **Persistent spec connective tissue** -- spec-kit's specs are disposable blueprints that die with the feature branch. Genie-team's specs accumulate design constraints, implementation evidence, and review verdicts across every feature that touches a capability. This is a fundamental architectural advantage for long-lived products — worth making explicit in positioning.

2. **Discovery-first workflow** -- spec-kit assumes the problem is understood and starts at "specify." Genie-team's Scout explores the problem space before anyone writes a spec. For ambiguous or novel work, this prevents building the wrong thing.

3. **Review-as-verification** -- spec-kit's /analyze is read-only consistency checking. Genie-team's /discern evaluates whether code actually satisfies each AC, updates spec statuses, and gates on integration wiring. The feedback loop has teeth.

### Patterns Worth Adopting from spec-kit

4. **Constitution guardrails** -- The immutable-principles-as-gates model with structured violation justification (why needed + simpler alternative rejected) and NON-NEGOTIABLE markers. Could be implemented as a constitution document checked during `/design` and `/deliver`, complementing existing rules files. Low effort, high guardrail value.

5. **Structured clarify step** -- /clarify uses 10 taxonomy categories to systematically reduce ambiguity with targeted Q&A (max 5 questions). Could slot between `/define` and `/design` to catch underspecified shaped contracts before design begins. Low effort, reduces rework.

6. **Cross-artifact consistency check** -- /analyze validates spec/plan/tasks for duplications, coverage gaps, and constitution violations with severity levels. An equivalent for genie-team could validate backlog items, specs, and designs for drift. Medium effort, catches silent divergence.

7. **Explicit research phase in design** -- spec-kit's Phase 0 in /plan extracts unknowns into research.md before design begins. Currently genie-team handles this via separate /discover or /spike, but embedding a research extraction step directly in /design could ensure unknowns are surfaced even when discovery is skipped.

### Patterns to Study for Future

8. **Extension/preset architecture** -- Four-tier template resolution, manifest validation, hook system, multi-catalog support. Reference architecture if genie-team ever needs community extensibility. High effort, premature until core workflow stabilizes.

9. **Multi-agent command registry** -- `AGENT_CONFIG` registry + template rendering per agent. Reference pattern if genie-team ever targets agents beyond Claude Code. High effort, high adoption impact, but premature.

10. **Automated task decomposition** -- /tasks generates ordered, parallelizable tasks from plans. Tension with genie-team's appetite-bounded philosophy, but worth considering as an optional step for well-understood features where manual shaping adds no value.

## 15. Evidence Gaps

- **Production usage data:** No case studies, usage metrics, or testimonials found beyond star count.
- **Extension quality:** 40+ extensions claimed but individual quality, maintenance status, and adoption unknown.
- **Agent parity:** Whether all 23 agents produce equivalent quality output from the same templates is unverified.
- **Brownfield effectiveness:** Methodology guide mentions brownfield but no evidence of how well it works for existing codebases.
- **Team adoption friction:** No data on how teams adopt SDD -- onboarding cost, learning curve, resistance patterns.
- **Spec evolution:** No mechanism found for spec evolution across features -- each feature starts fresh with no cross-pollination.

## 16. Routing Recommendation

- [x] **Ready for Navigator** -- Research complete. Findings are comprehensive enough for comparison or strategic decisions.
- [ ] Continue Discovery
- [ ] Ready for Shaper
- [ ] Needs Architect Spike

**Rationale:** This was a pure research task. The Opportunity Snapshot provides comprehensive coverage of spec-kit's architecture, format, workflow, and integration patterns. All eight requested dimensions are addressed. The comparison table and opportunity areas provide the material needed for whatever comparison the Navigator intends.
