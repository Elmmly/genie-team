---
type: shaped-work
concept: Multi-CLI Provider Framework
enhancement: Host Abstraction
status: designed
created: 2025-12-15
revised: 2025-12-15
---

# Shaped Work Contract: Multi-CLI Provider Framework

## 1. Problem / Opportunity Statement

**Original input:** "As an AI-enabled engineer, I want to be able to run either CLI from Claude or Gemini and have the agent context complete with the project state, backlog, next task, and follow the same principles."

**Reframed problem:** The `genie-team` framework depends on Claude Code host conventions: `CLAUDE.md` for auto-loaded context, `.claude/commands/` for slash command resolution, and the Task tool's `subagent_type` parameter for agent invocation. These conventions don't exist in other CLI hosts like Gemini. Users should be able to choose their preferred CLI host and have the full genie-team workflow available.

**Key insight:** The genie prompts themselves (Scout, Architect, Crafter, etc.) are already model-agnostic. The coupling is at the **host convention level**, not the prompt content level.

---

## 2. Evidence & Insights

- **From Code Analysis:** `CLAUDE.md` is referenced in 50+ locations across prompts, commands, and documentation. The `.claude/` directory structure is assumed throughout. These are host conventions, not model-specific logic.
- **Behavioral Signals:** User explicitly requested running either Claude Code or Gemini CLI with identical workflow support.
- **JTBD:** When working on a software project, a developer wants to use their preferred AI CLI tool so they can leverage familiar tooling while maintaining consistent project workflows, without reconfiguring the entire system.

### Current Coupling Points

| Convention | Claude Code | Gemini CLI | Impact |
|------------|-------------|------------|--------|
| Context file | `CLAUDE.md` (auto-loaded) | **Programmatic `InvocationContext`** | ❌ File-based context incompatible |
| Commands dir | `.claude/commands/*.md` | **Python `TaskHandler` classes** | ❌ Markdown commands not supported |
| Agent invocation | `Task(subagent_type=...)` | **`BaseAgent` hierarchy + `transfer_to_agent()`** | ⚠️ Different model, requires Python wrapper |
| Settings | `.claude/settings.local.json` | **Implicit in Python code** | ❌ No declarative permissions |

> **Research Complete:** See `docs/analysis/20251215_discover_gemini_cli_conventions.md` for full findings.

---

## 3. Strategic Alignment

- **North-star Alignment:** Supports the project's vision of being a "playground for discovering new ways of working." CLI-agnostic workflows enable broader experimentation.
- **Product Pillars:** Enhances **Tinkering as practice** (users can experiment with different hosts) and **Flexibility** (no vendor lock-in at the tooling layer).
- **Opportunity Cost:** Without this, users who prefer Gemini CLI (or future CLI tools) cannot adopt genie-team workflows.

---

## 4. Appetite (Scope Box)

- **Appetite:** **Small-Medium (3-5 days)** — reduced from original estimate after clarifying scope

### Boundaries (In Scope)

- Research Gemini CLI conventions (commands, context files, agents)
- Create `providers/` directory with host-specific path configurations
- Add `--provider` flag to `install.sh` for install-time host selection
- Update prompt references from hardcoded `CLAUDE.md` to provider-neutral variable
- Create provider-specific symlinks or copies as needed
- Document agent invocation patterns for each supported host

### No-Gos (Out of Scope)

- **No runtime provider switching** — host is selected at CLI invocation, not per-command
- **No JSON config file** — environment variables or install flags are simpler
- **No prompt content changes for model tuning** — prompts are already model-agnostic
- **No GUI or interactive configuration**

### Fixed Elements

- Existing command structure (`/discover`, `/design`, etc.) preserved
- Document-trail philosophy unchanged
- Genie personas and workflow unchanged

---

## 5. Goals

### Outcome Hypothesis

"We believe that **abstracting host conventions into a provider layer** will result in **CLI-agnostic workflow support** for **developers who want to use genie-team with their preferred AI CLI tool**."

### Success Signals

1. `./install.sh project --provider=gemini` installs commands to Gemini's expected location
2. Running `/discover` on Gemini CLI produces the same Opportunity Snapshot format as Claude Code
3. Project context (state, backlog, conventions) loads automatically on both hosts
4. Documentation exists for agent invocation on each supported host
5. Existing Claude Code installations continue to work unchanged (backwards compatible)

---

## 6. Opportunities & Constraints

### Opportunities

- **User Choice:** Developers use the CLI they're most productive with
- **Resilience:** Not dependent on a single CLI tool's availability or pricing
- **Future-Proofing:** Architecture ready for additional CLI hosts (Cursor, Copilot, etc.)

### Constraints

- **Research Required:** Must discover Gemini CLI conventions before implementation
- **Host Limitations:** Some features may not have equivalents across hosts (graceful degradation needed)
- **Backwards Compatibility:** Existing Claude Code users must not be broken

### Risks

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Gemini CLI has incompatible command format | Medium | High | Research spike first; design for graceful fallback |
| No equivalent to Task subagents in Gemini | Medium | Medium | Document manual invocation; agent features optional |
| Symlinks don't work on all platforms | Low | Low | Fall back to file copies |

---

## 7. Riskiest Assumptions — RESOLVED

> **Status:** Research spike completed 2025-12-15. All three assumptions have been tested.

### Assumption 1: Gemini CLI can be adapted to use markdown-based commands
- **Type:** Feasibility
- **Result:** ❌ **INVALIDATED**
- **Finding:** Commands are Python classes registered via `TaskHandler.get_handler(task_name)`. There is no mechanism for markdown-based command registration.
- **Implication:** A Python adapter layer is required to integrate genie-team commands.

### Assumption 2: A simple context file is sufficient for the Gemini CLI
- **Type:** Feasibility
- **Result:** ❌ **INVALIDATED**
- **Finding:** Context is managed programmatically via `InvocationContext` objects. The system creates isolated context branches for sub-agents via `_create_branch_ctx_for_sub_agent()`.
- **Implication:** `GEMINI.md` file-based context won't work. Context must be injected programmatically when tasks begin.

### Assumption 3: The `Task(subagent_type=...)` pattern can be mapped to Gemini
- **Type:** Feasibility
- **Result:** ⚠️ **PARTIALLY VALID** — different model
- **Finding:** Gemini has first-class sub-agent support via `BaseAgent` with `sub_agents` and `parent_agent` attributes. Delegation uses `transfer_to_agent()` function, not a generic Task tool.
- **Implication:** Genies can be implemented as `BaseAgent` subclasses, but require Python implementation rather than tool-based invocation.

---

## 8. Dependencies

- **Prerequisite:** Research spike on Gemini CLI conventions (blocking)
- **Optional:** Access to a running Gemini CLI environment for testing.

---

## 9. Open Questions — ANSWERED

### For Scout (Research) — ✅ COMPLETE

| Question | Answer |
|----------|--------|
| **Command Registration** | Python classes via `TaskHandler.get_handler()`. No file-based support. |
| **Execution Model** | Distributed async architecture: `TaskController` schedules, `TaskWorker` executes via FastAPI. |
| **Agent/Task Invocation** | `BaseAgent` hierarchy with `transfer_to_agent()` for delegation. More advanced than Claude's Task tool. |
| **Context Management** | Programmatic `InvocationContext` with branch isolation per sub-agent. |
| **Security Model** | Implicit in Python code. No declarative permissions file. |

### For Navigator (Decision) — PENDING

1.  ~~If the Gemini CLI requires a full Python-native implementation~~ **CONFIRMED**: Gemini requires Python. Decision needed:
    - **Option A:** Create Python adapter package (`genie-team-gemini`) that wraps prompts as `BaseAgent` classes
    - **Option B:** Accept documentation-only support for Gemini; full integration only for file-based hosts

2.  ~~If there is a fundamental mismatch~~ **CONFIRMED**: Mismatch exists. Decision needed:
    - Should we invest in Python adapter (new backlog item) or deprioritize Gemini support?

---

## 10. Recommendation (Options + Ranked) — REVISED POST-RESEARCH

> **Context:** Research spike completed. Gemini CLI is Python-native with fundamentally different architecture. Options 1-2 assumed file-based compatibility that doesn't exist.

### Option 1: Host Abstraction Layer (Claude + Future File-Based Hosts)

**Description:** Create `providers/` directory for file-based hosts. Gemini excluded from file-based approach.

```
providers/
├── claude/
│   ├── config.sh         # CONTEXT_FILE="CLAUDE.md", COMMANDS_DIR=".claude/commands"
│   └── agent-patterns.md # How to invoke agents on Claude Code
├── cursor/               # Future: if Cursor uses similar conventions
│   └── config.sh
└── common/
    └── context-template.md
```

- **Pros:** Still valuable for Claude Code and future file-based hosts (Cursor, Copilot, etc.)
- **Cons:** Does not solve Gemini integration
- **Appetite fit:** Yes (3-5 days)
- **Status:** ✅ **RECOMMENDED for Claude Code abstraction**

### Option 2: Neutral Naming with Symlinks

**Description:** Rename `CLAUDE.md` → `GENIE.md` everywhere.

- **Pros:** Single source of truth
- **Cons:** Breaking change; **does not help Gemini** (file-based context not supported)
- **Appetite fit:** Yes (2-3 days)
- **Status:** ⚠️ Deprioritized — doesn't address research findings

### Option 3: Documentation-Only for Gemini (Recommended for Gemini)

**Description:** Keep Claude Code as primary with full integration. For Gemini, provide:
- Documentation on how to manually use genie prompts
- Example of wrapping a genie prompt in a Python agent
- Guidance on context injection patterns

- **Pros:** No Python development required; immediate; honest about limitations
- **Cons:** Poor UX for Gemini users; manual workflow
- **Appetite fit:** Yes (1-2 days)
- **Status:** ✅ **RECOMMENDED as interim Gemini solution**

### Option 4: Python Adapter Package (Future Work) — NEW

**Description:** Create a Python package `genie-team-gemini` that wraps genie prompts as native Gemini `BaseAgent` classes.

```
providers/
└── gemini/
    └── python/
        ├── genie_team/
        │   ├── __init__.py
        │   ├── agents/
        │   │   ├── scout.py      # class ScoutAgent(BaseAgent)
        │   │   ├── architect.py  # class ArchitectAgent(BaseAgent)
        │   │   ├── crafter.py
        │   │   └── ...
        │   ├── handlers.py       # TaskHandler registrations
        │   └── context.py        # InvocationContext injection
        └── setup.py
```

- **Pros:** True native integration; full feature parity; reuses existing prompts
- **Cons:** Significant development effort; requires Python expertise; new maintenance burden
- **Appetite fit:** No — **Big (2+ weeks)**, should be separate backlog item
- **Status:** 📋 **DEFER to new backlog item: P1-gemini-python-adapter**

### Ranked Recommendation — UPDATED

| Rank | Option | For Claude Code | For Gemini | Action |
|------|--------|-----------------|------------|--------|
| 1 | Option 1: Host Abstraction | ✅ Full integration | ❌ N/A | **Implement now** |
| 2 | Option 3: Documentation-Only | N/A | ⚠️ Manual workflow | **Implement now** |
| 3 | Option 4: Python Adapter | N/A | ✅ Full integration | **Defer to P1** |
| 4 | Option 2: Neutral Naming | Marginal benefit | ❌ Doesn't help | **Deprioritize** |

**Summary:** Proceed with Option 1 for Claude Code. Accept Option 3 (documentation) as interim Gemini solution. Create new backlog item for Option 4 if full Gemini integration is desired.

---

## 11. Routing Target

**Recommended route:**
- [X] **Scout** - ✅ Research spike complete (2025-12-15)
- [X] **Architect** - ✅ Technical design complete (2025-12-15)
- [ ] **Navigator** - Decision needed on Gemini approach (Option 3 vs Option 4)
- [ ] **Crafter** - Ready for implementation after Navigator decision

**Rationale:** Research spike revealed fundamental architecture mismatch. Design updated to reflect two-track approach: (1) file-based abstraction for Claude Code, (2) documentation-only or Python adapter for Gemini. Navigator decision needed on Gemini investment level.

---

## 12. Implementation Phases — REVISED

### Phase 1: Research Spike ✅ COMPLETE
- [x] **Command System:** Python `TaskHandler` classes. No markdown support.
- [x] **Execution Model:** Distributed async with `TaskController`/`TaskWorker`.
- [x] **Context Loading:** Programmatic `InvocationContext` with branch isolation.
- [x] **Agent Model:** `BaseAgent` hierarchy with `transfer_to_agent()`.
- [x] **Security:** Implicit in Python code. No declarative permissions.
- [ ] ~~Quality Check~~ — Deferred (requires Gemini environment)

**Output:** `docs/analysis/20251215_discover_gemini_cli_conventions.md`

### Phase 2: Claude Code Abstraction Layer
- [ ] Create `providers/claude/config.sh`
- [ ] Create `providers/_template/config.sh`
- [ ] Create `templates/CONTEXT.md.template`
- [ ] Update `install.sh` with `--provider` flag (Claude only for now)
- [ ] Update prompt references from `CLAUDE.md` to `{CONTEXT_FILE}` placeholder
- [ ] Update `cmd_build()` for placeholder substitution

### Phase 3: Gemini Documentation (Interim)
- [ ] Create `providers/gemini/README.md` documenting architecture differences
- [ ] Create `providers/gemini/examples/scout_agent.py` — example BaseAgent wrapper
- [ ] Document context injection pattern for Gemini users

### Phase 4: Validation
- [ ] End-to-end test: full workflow on Claude Code (regression)
- [ ] Verify `./install.sh project` produces identical output to before
- [ ] Document provider-specific limitations

### Phase 5: (Future) Python Adapter — SEPARATE BACKLOG ITEM
- [ ] Create `P1-gemini-python-adapter.md` backlog item
- [ ] Design `genie-team-gemini` Python package
- [ ] Implement `BaseAgent` wrappers for each genie

---

## 13. Artifacts

- **Contract saved to:** `docs/backlog/P0-multi-agent-provider-framework.md`
- **Research spike output:** `docs/analysis/20251215_discover_gemini_cli_conventions.md` ✅ Complete
- **Future backlog item:** `docs/backlog/P1-gemini-python-adapter.md` (to be created if Option 4 approved)

---

# Design

## 14. Design Summary

This design introduces a **Provider Abstraction Layer** that decouples genie-team from host-specific conventions. The core insight: genie prompts are already model-agnostic—only the *installation targets* and *context file references* need abstraction.

### Architecture Principle

```
┌─────────────────────────────────────────────────────────────────┐
│                     genie-team (provider-agnostic)              │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐  │
│  │   genies/   │  │  commands/  │  │  templates/             │  │
│  │  (prompts)  │  │  (workflows)│  │  (CONTEXT.md.template)  │  │
│  └─────────────┘  └─────────────┘  └─────────────────────────┘  │
└─────────────────────────────┬───────────────────────────────────┘
                              │
                    install.sh --provider=X
                              │
          ┌───────────────────┼───────────────────┐
          ▼                   ▼                   ▼
┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐
│  Claude Code    │ │   Gemini CLI    │ │   Future Host   │
│  .claude/       │ │   .gemini/      │ │   .host/        │
│  CLAUDE.md      │ │   GEMINI.md     │ │   HOST.md       │
└─────────────────┘ └─────────────────┘ └─────────────────┘
```

---

## 15. Component Design

### 15.1 Provider Configuration Interface

Each provider is defined by a configuration file that specifies host-specific paths and patterns.

**File:** `providers/{provider}/config.sh`

```bash
# providers/claude/config.sh
PROVIDER_NAME="claude"
PROVIDER_DISPLAY_NAME="Claude Code"

# Directory conventions
HOST_DIR=".claude"                    # Where host looks for config
COMMANDS_DIR=".claude/commands"       # Slash command location
AGENTS_DIR=".claude/agents"           # Agent definitions
SETTINGS_FILE=".claude/settings.local.json"

# Context file
CONTEXT_FILE="CLAUDE.md"              # Auto-loaded context file
CONTEXT_TEMPLATE="templates/CONTEXT.md.template"

# Global installation paths
GLOBAL_HOST_DIR="$HOME/.claude"
GLOBAL_COMMANDS_DIR="$HOME/.claude/commands"
GLOBAL_AGENTS_DIR="$HOME/.claude/agents"
GLOBAL_SETTINGS_FILE="$HOME/.claude/settings.json"

# Agent invocation pattern (for documentation/prompts)
AGENT_INVOCATION_PATTERN="Task(subagent_type='{agent}', prompt='{prompt}')"

# Feature flags
SUPPORTS_SUBAGENTS="true"
SUPPORTS_SLASH_COMMANDS="true"
SUPPORTS_SETTINGS_JSON="true"
```

```bash
# providers/gemini/config.sh
# NOTE: Gemini CLI uses Python-native architecture, not file-based.
# This config exists for documentation purposes only.
# See providers/gemini/README.md for integration guidance.

PROVIDER_NAME="gemini"
PROVIDER_DISPLAY_NAME="Gemini CLI"

# Architecture type (research finding 2025-12-15)
ARCHITECTURE_TYPE="python-native"     # Not file-based like Claude Code

# These conventions DO NOT APPLY to Gemini
# Gemini uses: TaskHandler classes, BaseAgent hierarchy, InvocationContext
HOST_DIR="N/A"                        # No file-based host directory
COMMANDS_DIR="N/A"                    # Commands are Python TaskHandler classes
AGENTS_DIR="N/A"                      # Agents are Python BaseAgent subclasses
SETTINGS_FILE="N/A"                   # Security is implicit in Python code

# Context file - NOT SUPPORTED
# Gemini uses programmatic InvocationContext, not auto-loaded files
CONTEXT_FILE="N/A"
CONTEXT_TEMPLATE="N/A"

# Global installation - NOT APPLICABLE
GLOBAL_HOST_DIR="N/A"
GLOBAL_COMMANDS_DIR="N/A"
GLOBAL_AGENTS_DIR="N/A"
GLOBAL_SETTINGS_FILE="N/A"

# Agent invocation pattern (different from Claude Code)
# Gemini uses BaseAgent hierarchy with transfer_to_agent() for delegation
AGENT_INVOCATION_PATTERN="transfer_to_agent(agent_name='{agent}')"

# Feature flags (CONFIRMED by research spike)
SUPPORTS_SUBAGENTS="python-native"    # Yes, but via BaseAgent, not Task tool
SUPPORTS_SLASH_COMMANDS="false"       # No markdown commands
SUPPORTS_SETTINGS_JSON="false"        # No declarative permissions
SUPPORTS_FILE_CONTEXT="false"         # No auto-loaded context file

# Integration approach
INTEGRATION_TYPE="documentation-only" # Or "python-adapter" if Option 4 approved
```

### 15.2 Provider Directory Structure — REVISED

```
providers/
├── claude/
│   ├── config.sh              # Path and feature configuration
│   ├── agent-patterns.md      # How to invoke agents on Claude Code
│   └── post-install.sh        # Optional: provider-specific post-install
├── gemini/
│   ├── config.sh              # Documents architecture (N/A values)
│   ├── README.md              # Architecture differences, manual usage guide
│   └── examples/
│       ├── scout_agent.py     # Example: Scout as BaseAgent
│       └── context_injection.py # Example: InvocationContext setup
├── _template/
│   └── config.sh              # Template for adding new FILE-BASED providers
└── common/
    └── context-template.md    # Neutral context template (file-based hosts only)
```

> **Note:** Gemini provider contains documentation and examples, not installable files.

### 15.3 Neutral Context Template

**File:** `templates/CONTEXT.md.template`

This is the provider-neutral version of the current `CLAUDE.md` template. The install script copies this to the provider-specific filename.

```markdown
# Project Name

> Brief description of this project

<!-- This file is automatically loaded by {{PROVIDER_DISPLAY_NAME}} at session start -->

## Genie Team Quick Reference

This project uses **Genie Team** - specialized AI genies for product discovery and delivery.

### Start Here
- `/genie:help` - Show all commands
- `/genie:status` - Show current work status
- `/context:load` - Initialize full session context

...rest of template...

## Agent Invocation

{{AGENT_INVOCATION_SECTION}}

---

Last updated: {{DATE}}
```

---

## 16. Install Script Modifications

### 16.1 New Command-Line Interface

```bash
# Updated usage
./install.sh <command> [options]

Commands:
  global              Install globally for specified provider
  project [path]      Install to project for specified provider
  status              Show installation status (all providers)
  uninstall           Remove installation
  build               Build distribution files

Options:
  --provider=NAME     Target provider: claude (default), gemini, all
  --no-commands       Skip installing commands
  --no-agents         Skip installing agents
  --no-genies         Skip installing genie specs (project only)
  --permissions       Also update permissions in settings
  --force             Overwrite existing files
  --dry-run           Show what would be done

Examples:
  ./install.sh global                        # Claude Code (default)
  ./install.sh global --provider=gemini      # Gemini CLI
  ./install.sh project --provider=all        # Both providers
  ./install.sh project ~/myapp --provider=claude
```

### 16.2 Core Logic Changes

**New function:** `load_provider_config()`

```bash
load_provider_config() {
    local provider="${1:-claude}"
    local config_file="$SCRIPT_DIR/providers/$provider/config.sh"

    if [[ ! -f "$config_file" ]]; then
        log_error "Unknown provider: $provider"
        log_info "Available providers: $(ls -1 $SCRIPT_DIR/providers/ | grep -v _template | tr '\n' ' ')"
        exit 1
    fi

    # Source the provider config (sets all variables)
    source "$config_file"

    log_info "Using provider: $PROVIDER_DISPLAY_NAME"
}
```

**Modified function:** `install_commands()` — now uses `$COMMANDS_DIR` variable

**Modified function:** `create_context_file()` — replaces `create_claude_md_template()`

```bash
create_context_file() {
    local target_file="$1"
    local force="$2"

    if [[ -f "$target_file" && "$force" != "true" ]]; then
        log_warn "Skipping $CONTEXT_FILE (exists, use --force to overwrite)"
        return
    fi

    # Read template and substitute variables
    local template="$SCRIPT_DIR/$CONTEXT_TEMPLATE"
    if [[ ! -f "$template" ]]; then
        log_error "Context template not found: $template"
        exit 1
    fi

    # Generate agent invocation section based on provider
    local agent_section=""
    if [[ "$SUPPORTS_SUBAGENTS" == "true" ]]; then
        agent_section="Invoke via: \`$AGENT_INVOCATION_PATTERN\`"
    else
        agent_section="See \`providers/$PROVIDER_NAME/agent-patterns.md\` for agent invocation."
    fi

    # Substitute template variables
    sed -e "s|{{PROVIDER_DISPLAY_NAME}}|$PROVIDER_DISPLAY_NAME|g" \
        -e "s|{{AGENT_INVOCATION_SECTION}}|$agent_section|g" \
        -e "s|{{DATE}}|$(date +%Y-%m-%d)|g" \
        "$template" > "$target_file"

    log_success "Created $CONTEXT_FILE at $target_file"
}
```

**New function:** `install_for_provider()`

```bash
install_for_provider() {
    local provider="$1"
    local install_type="$2"  # "global" or "project"
    local project_path="$3"
    # ... rest of options

    load_provider_config "$provider"

    if [[ "$install_type" == "global" ]]; then
        install_commands "$GLOBAL_COMMANDS_DIR" "$force"
        install_agents "$GLOBAL_AGENTS_DIR" "$force"
    else
        local host_dir="$project_path/$HOST_DIR"
        install_commands "$host_dir/commands" "$force"
        install_agents "$host_dir/agents" "$force"
        install_genies "$host_dir/genies" "$force"
        create_context_file "$project_path/$CONTEXT_FILE" "$force"
    fi
}
```

### 16.3 Multi-Provider Installation (`--provider=all`)

When `--provider=all` is specified:

1. Install to each provider's directories independently
2. Create symlinks for shared content where possible
3. Use the neutral `GENIE.md` as primary, symlink to provider-specific names

```bash
install_all_providers() {
    local project_path="$1"
    # ... options

    # Create neutral context file first
    create_neutral_context_file "$project_path/GENIE.md" "$force"

    # For each provider, create symlinks
    for provider_dir in "$SCRIPT_DIR/providers"/*/; do
        local provider=$(basename "$provider_dir")
        [[ "$provider" == "_template" ]] && continue

        load_provider_config "$provider"

        # Create provider-specific symlink to neutral file
        if [[ "$CONTEXT_FILE" != "GENIE.md" ]]; then
            ln -sf "GENIE.md" "$project_path/$CONTEXT_FILE"
            log_success "Created symlink: $CONTEXT_FILE → GENIE.md"
        fi

        # Install to provider-specific directories
        local host_dir="$project_path/$HOST_DIR"
        install_commands "$host_dir/commands" "$force"
        install_agents "$host_dir/agents" "$force"
    done
}
```

---

## 17. Prompt Reference Abstraction

### 17.1 Files Requiring Updates

| File | Current Reference | Change Strategy |
|------|-------------------|-----------------|
| `genies/scout/SCOUT_SYSTEM_PROMPT.md:156` | `CLAUDE.md` | Replace with `{CONTEXT_FILE}` placeholder |
| `genies/scout/SCOUT_SPEC.md:56` | `CLAUDE.md` | Replace with `{CONTEXT_FILE}` placeholder |
| `genies/architect/ARCHITECT_SYSTEM_PROMPT.md:156` | `CLAUDE.md` | Replace with `{CONTEXT_FILE}` placeholder |
| `genies/architect/ARCHITECT_SPEC.md:57` | `CLAUDE.md` | Replace with `{CONTEXT_FILE}` placeholder |
| `genies/crafter/CRAFTER_SYSTEM_PROMPT.md:165` | `CLAUDE.md` | Replace with `{CONTEXT_FILE}` placeholder |
| `genies/crafter/CRAFTER_SPEC.md:56` | `CLAUDE.md` | Replace with `{CONTEXT_FILE}` placeholder |
| `genies/shaper/SHAPER_SYSTEM_PROMPT.md:170` | `CLAUDE.md` | Replace with `{CONTEXT_FILE}` placeholder |
| `genies/shaper/SHAPER_SPEC.md:57` | `CLAUDE.md` | Replace with `{CONTEXT_FILE}` placeholder |
| `genies/tidier/TIDIER_SYSTEM_PROMPT.md:132` | `CLAUDE.md` | Replace with `{CONTEXT_FILE}` placeholder |
| `genies/tidier/TIDIER_SPEC.md:57` | `CLAUDE.md` | Replace with `{CONTEXT_FILE}` placeholder |
| `genies/critic/CRITIC_SPEC.md` | `CLAUDE.md` | Replace with `{CONTEXT_FILE}` placeholder |
| `commands/discover.md:29` | `CLAUDE.md` | Replace with `{CONTEXT_FILE}` placeholder |
| `commands/context-load.md:10,26,37` | `CLAUDE.md` | Replace with `{CONTEXT_FILE}` placeholder |

### 17.2 Build-Time Substitution

Modify `cmd_build()` to substitute placeholders based on target provider:

```bash
cmd_build() {
    local provider="${1:-claude}"
    load_provider_config "$provider"

    log_info "Building distribution files for $PROVIDER_DISPLAY_NAME..."

    local dist_dir="$SCRIPT_DIR/dist/$PROVIDER_NAME"
    mkdir -p "$dist_dir/commands"

    for cmd_file in "$SCRIPT_DIR/commands"/*.md; do
        local filename=$(basename "$cmd_file")
        local target_file="$dist_dir/commands/$filename"

        # Substitute placeholders
        sed -e "s|{CONTEXT_FILE}|$CONTEXT_FILE|g" \
            -e "s|{HOST_DIR}|$HOST_DIR|g" \
            -e "s|{AGENT_INVOCATION}|$AGENT_INVOCATION_PATTERN|g" \
            "$cmd_file" > "$target_file.tmp"

        # Then embed genie prompt (existing logic)
        # ...

        mv "$target_file.tmp" "$target_file"
        log_success "Built $filename for $PROVIDER_NAME"
    done
}
```

### 17.3 Placeholder Syntax

Use `{VARIABLE}` syntax in source files (not `$VARIABLE` to avoid shell conflicts):

```markdown
## Context Loading

**READ (automatic):**
- {CONTEXT_FILE} (project root)
- docs/context/system_architecture.md
```

---

## 18. Data Design

### 18.1 Provider Registry

No database needed. Providers are discovered by scanning `providers/*/config.sh`:

```bash
list_providers() {
    for config in "$SCRIPT_DIR/providers"/*/config.sh; do
        source "$config"
        echo "$PROVIDER_NAME: $PROVIDER_DISPLAY_NAME"
    done
}
```

### 18.2 Installation State

Installation state is implicit in the filesystem:
- `~/.claude/commands/` exists → Claude Code global install present
- `~/.gemini/commands/` exists → Gemini CLI global install present
- `.claude/commands/` exists → Claude Code project install present

The `status` command scans all known provider directories:

```bash
cmd_status() {
    echo "Genie Team Installation Status"
    echo "==============================="

    for provider_dir in "$SCRIPT_DIR/providers"/*/; do
        local provider=$(basename "$provider_dir")
        [[ "$provider" == "_template" ]] && continue

        source "$provider_dir/config.sh"

        echo ""
        echo "$PROVIDER_DISPLAY_NAME:"

        # Check global
        if [[ -d "$GLOBAL_COMMANDS_DIR" ]]; then
            local count=$(ls -1 "$GLOBAL_COMMANDS_DIR"/*.md 2>/dev/null | wc -l)
            echo "  Global: $count commands"
        else
            echo "  Global: Not installed"
        fi

        # Check project
        if [[ -d "./$HOST_DIR/commands" ]]; then
            local count=$(ls -1 "./$HOST_DIR/commands"/*.md 2>/dev/null | wc -l)
            echo "  Project: $count commands"
        else
            echo "  Project: Not installed"
        fi
    done
}
```

---

## 19. Integration Points

### 19.1 External Dependencies

| Dependency | Required | Purpose |
|------------|----------|---------|
| Bash 4.0+ | Yes | Array support, `source` command |
| sed | Yes | Template substitution |
| ln | Yes | Symlink creation |
| jq | Optional | JSON settings merge |

### 19.2 Host CLI Integration — REVISED

**File-based hosts** (Claude Code, future Cursor/Copilot): Framework installs files to expected locations.

| Host | Expected Location | genie-team Provides |
|------|-------------------|---------------------|
| Claude Code | `.claude/commands/*.md` | Slash command prompts |
| Claude Code | `CLAUDE.md` | Auto-loaded context |
| Claude Code | `.claude/agents/*.md` | Subagent definitions |

**Python-native hosts** (Gemini CLI): Framework provides documentation and examples only.

| Host | Integration Model | genie-team Provides |
|------|-------------------|---------------------|
| Gemini CLI | Python `TaskHandler` + `BaseAgent` | Documentation + example code |
| Gemini CLI | `InvocationContext` | Context injection examples |
| Gemini CLI | `transfer_to_agent()` | Agent delegation patterns |

> **Key Insight:** Gemini CLI cannot consume markdown files directly. Full integration requires a Python adapter package (Option 4, deferred).

---

## 20. Migration Strategy

### 20.1 Backwards Compatibility

**Existing installations continue to work unchanged.**

- Default provider remains `claude`
- Running `./install.sh project` without `--provider` behaves identically to current
- `CLAUDE.md` filename preserved for Claude Code users
- No breaking changes to existing prompts until build-time substitution is run

### 20.2 Migration Path for Existing Users

1. **No action required** for Claude Code users
2. Users wanting multi-provider: `./install.sh project --provider=all --force`
3. This creates:
   - `GENIE.md` (primary)
   - `CLAUDE.md` → symlink to `GENIE.md`
   - `GEMINI.md` → symlink to `GENIE.md`

### 20.3 Phased Rollout

| Phase | Changes | Risk |
|-------|---------|------|
| 1 | Add `providers/claude/config.sh`, refactor install.sh to use it | Low - no behavior change |
| 2 | Add `--provider` flag, default to `claude` | Low - opt-in only |
| 3 | Add placeholder syntax to prompts | Low - placeholders resolve to current values |
| 4 | Add Gemini provider (after research) | Medium - new functionality |
| 5 | Add `--provider=all` support | Medium - new functionality |

---

## 21. Risks & Mitigations — UPDATED

| Risk | Likelihood | Impact | Mitigation | Status |
|------|------------|--------|------------|--------|
| Gemini CLI has fundamentally different architecture | ~~Medium~~ | High | Documentation-only fallback; Python adapter as future option | ✅ **CONFIRMED** — design updated |
| Symlinks don't work on Windows | Medium | Low | Detect OS; fall back to file copies | Unchanged |
| Placeholder substitution breaks existing content | Low | Medium | Comprehensive test suite; dry-run mode | Unchanged |
| Provider config files become out of sync | Low | Low | Single source of truth per provider | Unchanged |
| Users confused by multiple context files | Low | Low | Clear documentation; `status` command shows state | Unchanged |
| Gemini users disappointed by limited support | Medium | Medium | Clear documentation of limitations; roadmap for Python adapter | **NEW** |

---

## 22. Implementation Guidance

### 22.1 File Changes Summary

| File | Action | Priority |
|------|--------|----------|
| `providers/claude/config.sh` | Create | P0 |
| `providers/gemini/config.sh` | Create (placeholders) | P0 |
| `providers/_template/config.sh` | Create | P1 |
| `templates/CONTEXT.md.template` | Create (from current CLAUDE.md) | P0 |
| `install.sh` | Modify (add provider support) | P0 |
| `genies/*/SCOUT_SYSTEM_PROMPT.md` | Modify (add placeholders) | P1 |
| `genies/*/*.md` | Modify (add placeholders) | P1 |
| `commands/*.md` | Modify (add placeholders) | P1 |

### 22.2 Implementation Order

```
1. Create providers/ directory structure
   └── providers/claude/config.sh
   └── providers/gemini/config.sh (with TBD values)
   └── providers/_template/config.sh

2. Create templates/CONTEXT.md.template
   └── Copy from current templates/CLAUDE.md
   └── Add {{PLACEHOLDER}} syntax

3. Refactor install.sh
   └── Add load_provider_config()
   └── Add --provider flag parsing
   └── Replace hardcoded paths with variables
   └── Update create_claude_md_template → create_context_file

4. Update prompts with placeholders
   └── Replace "CLAUDE.md" with "{CONTEXT_FILE}"
   └── Update cmd_build() to substitute

5. Test Claude Code path (regression)
   └── ./install.sh project (should work identically)

6. Add --provider=all support
   └── Symlink creation logic
   └── Multi-provider status display

7. (Post research spike) Complete Gemini provider
   └── Fill in TBD values in config.sh
   └── Create agent-patterns.md
```

### 22.3 Test Checklist

- [ ] `./install.sh project` produces identical output to before
- [ ] `./install.sh project --provider=claude` works
- [ ] `./install.sh status` shows Claude Code installation
- [ ] `./install.sh project --provider=gemini --dry-run` shows expected paths
- [ ] `./install.sh project --provider=all` creates symlinks
- [ ] Prompts reference correct context file after build
- [ ] Existing CLAUDE.md files are not overwritten without --force

---

## 23. Open Design Decisions — UPDATED

### 23.1 Resolved

| Decision | Resolution | Rationale |
|----------|------------|-----------|
| Runtime vs install-time provider selection | Install-time | Simpler; host is chosen when user runs CLI |
| JSON config vs shell config | Shell (config.sh) | Easier to source; no jq dependency |
| Placeholder syntax | `{VARIABLE}` | Avoids shell expansion conflicts |

### 23.2 Resolved by Research Spike

| Decision | Resolution | Finding |
|----------|------------|---------|
| Gemini command directory | **N/A** — not file-based | Commands are Python `TaskHandler` classes |
| Gemini context file name | **N/A** — not file-based | Context is `InvocationContext` object |
| Gemini agent invocation | **Python `BaseAgent`** | Uses `transfer_to_agent()` for delegation |
| Gemini integration approach | **Documentation-only** (interim) | Full integration requires Python adapter (Option 4) |

### 23.3 Pending Navigator Decision

| Decision | Options | Recommendation |
|----------|---------|----------------|
| Investment level for Gemini | Option 3 (docs) vs Option 4 (Python adapter) | Start with Option 3; create P1 backlog item for Option 4 |

---

## 24. Acceptance Criteria — REVISED

### Claude Code (Full Integration)

1. **Backwards Compatible:** `./install.sh project` without flags produces identical results to current behavior
2. **Provider Flag Works:** `./install.sh project --provider=claude` installs to Claude Code locations
3. **Status Works:** `./install.sh status` shows Claude Code installation state
4. **Placeholders Resolve:** Built commands reference `CLAUDE.md` after substitution
5. **Documentation Complete:** `providers/claude/agent-patterns.md` explains Task tool usage

### Gemini CLI (Documentation-Only)

6. **Architecture Documented:** `providers/gemini/README.md` explains why file-based install doesn't apply
7. **Examples Provided:** `providers/gemini/examples/` contains working Python examples
8. **Context Pattern Documented:** Example shows how to inject genie-team context into `InvocationContext`
9. ~~Dry Run Accurate~~ — **REMOVED**: `--provider=gemini` now shows documentation message, not file paths
10. ~~Symlinks Work~~ — **REMOVED**: Gemini doesn't use file-based context

### Future (If Option 4 Approved)

11. **Backlog Item Created:** `P1-gemini-python-adapter.md` documents full Python adapter scope

---

## 25. Research Spike Results Summary

> **Completed:** 2025-12-15 | **Output:** `docs/analysis/20251215_discover_gemini_cli_conventions.md`

### Key Finding: Fundamental Architecture Mismatch

The Gemini CLI is a **Python-native, distributed async framework** — fundamentally different from Claude Code's file-based conventions.

| Aspect | Claude Code | Gemini CLI |
|--------|-------------|------------|
| **Commands** | Markdown files in `.claude/commands/` | Python `TaskHandler` classes |
| **Context** | Auto-loaded `CLAUDE.md` file | Programmatic `InvocationContext` |
| **Agents** | Tool call: `Task(subagent_type=...)` | Python `BaseAgent` with `transfer_to_agent()` |
| **Settings** | Declarative JSON permissions | Implicit in Python code |
| **Execution** | Single host process | Distributed `TaskController`/`TaskWorker` |

### Impact on Design

1. **Option 1 (Host Abstraction)** — Still valid for Claude Code and future file-based hosts
2. **Option 2 (Neutral Naming)** — Deprioritized; doesn't address Gemini
3. **Option 3 (Documentation-Only)** — Now recommended as interim Gemini solution
4. **Option 4 (Python Adapter)** — New option; requires separate backlog item

### Recommendations

| Host | Approach | Effort |
|------|----------|--------|
| Claude Code | Full file-based integration (Option 1) | 3-5 days |
| Gemini CLI | Documentation + examples (Option 3) | 1-2 days |
| Gemini CLI | Python adapter (Option 4) — future | 2+ weeks (separate backlog) |

### Navigator Decision Required

Should we invest in a Python adapter for full Gemini integration (Option 4), or accept documentation-only support (Option 3) for now?

**Recommendation:** Start with Option 3. Create `P1-gemini-python-adapter.md` as a future backlog item if demand exists.
