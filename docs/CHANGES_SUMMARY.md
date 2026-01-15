# Genie Team Simplification Summary

## Changes Made

### 1. Consolidated Genie Specifications

Created unified `GENIE.md` files that merge SPEC + SYSTEM_PROMPT + TEMPLATE for each genie:

| Genie | New File | Lines | Previous Files |
|-------|----------|-------|----------------|
| Scout | `genies/scout/GENIE.md` | ~180 | SPEC (338) + SYSTEM_PROMPT (167) + TEMPLATE (161) = 666 |
| Shaper | `genies/shaper/GENIE.md` | ~150 | SPEC (383) + SYSTEM_PROMPT + TEMPLATE |
| Architect | `genies/architect/GENIE.md` | ~180 | SPEC (397) + SYSTEM_PROMPT + TEMPLATE |
| Crafter | `genies/crafter/GENIE.md` | ~160 | SPEC (364) + SYSTEM_PROMPT + TEMPLATE |
| Critic | `genies/critic/GENIE.md` | ~160 | SPEC (398) + SYSTEM_PROMPT + TEMPLATE |
| Tidier | `genies/tidier/GENIE.md` | ~170 | SPEC (412) + SYSTEM_PROMPT + TEMPLATE |

**Reduction:** ~73% fewer lines per genie while preserving essential guidance.

### 2. Rules Directory Structure

Created `.claude/rules/` with modular rule files:

```
.claude/rules/
├── tdd-discipline.md       # TDD constraints (Red-Green-Refactor, AAA pattern)
├── agent-conventions.md    # Agent output standards and boundaries
├── workflow.md             # 7 D's lifecycle quick reference
├── code-quality.md         # Error handling, patterns, security
├── agent-selection.md      # When to use genie vs built-in agents
└── mcp-integration.md      # MCP server recommendations
```

### 3. Context Isolation for Agents

Added `context: fork` to all agent files for isolated execution:
- `agents/scout.md`
- `agents/architect.md`
- `agents/critic.md`
- `agents/tidier.md`

### 4. Simplified Permissions Template

Created `templates/settings.json` with wildcard patterns:

```json
{
  "permissions": {
    "allow": [
      "WebSearch",
      "WebFetch(domain:github.com)",
      "Bash(git *)",
      "Bash(npm test*)",
      "Bash(npm run *)"
    ]
  }
}
```

---

## Cleanup Recommendations

### Files That Can Be Removed

After validating the consolidated GENIE.md files work correctly:

```bash
# Scout
rm genies/scout/SCOUT_SPEC.md
rm genies/scout/SCOUT_SYSTEM_PROMPT.md
rm genies/scout/OPPORTUNITY_SNAPSHOT_TEMPLATE.md

# Shaper
rm genies/shaper/SHAPER_SPEC.md
rm genies/shaper/SHAPER_SYSTEM_PROMPT.md
rm genies/shaper/SHAPED_WORK_CONTRACT_TEMPLATE.md

# Architect
rm genies/architect/ARCHITECT_SPEC.md
rm genies/architect/ARCHITECT_SYSTEM_PROMPT.md
rm genies/architect/DESIGN_DOCUMENT_TEMPLATE.md

# Crafter
rm genies/crafter/CRAFTER_SPEC.md
rm genies/crafter/CRAFTER_SYSTEM_PROMPT.md
rm genies/crafter/IMPLEMENTATION_REPORT_TEMPLATE.md

# Critic
rm genies/critic/CRITIC_SPEC.md
rm genies/critic/CRITIC_SYSTEM_PROMPT.md
rm genies/critic/REVIEW_DOCUMENT_TEMPLATE.md

# Tidier
rm genies/tidier/TIDIER_SPEC.md
rm genies/tidier/TIDIER_SYSTEM_PROMPT.md
rm genies/tidier/CLEANUP_REPORT_TEMPLATE.md
```

### Install Script Updates Needed

The `install.sh` should be updated to:
1. Copy `.claude/rules/` to target projects
2. Reference new consolidated `GENIE.md` files
3. Include `templates/settings.json` as optional configuration

---

## Key Benefits

1. **Reduced Maintenance**: One file per genie instead of three
2. **Better Organization**: Rules in modular files, easy to customize per project
3. **Context Isolation**: Agents run in forked context for cleaner separation
4. **Simpler Permissions**: Wildcard patterns reduce permission entries
5. **MCP Ready**: Documentation for integrating GitHub, Slack, Linear

---

## Next Steps

1. Test the consolidated GENIE.md files with actual workflow usage
2. Update install.sh to include rules directory
3. Remove old redundant files after validation
4. Consider adding hooks for workflow enforcement (PreToolUse/PostToolUse)
