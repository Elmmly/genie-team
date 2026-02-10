---
diagram_version: "2.2"
type: architecture-diagram
level: 1
title: "System Context - Genie Team"
updated: 2026-02-10
updated_by: "ADR-001 revision — portfolio-flexible orchestration"
tags: [overview, context, orchestration, portfolio]
---

# System Context: Genie Team

## Diagram

```mermaid
%%{init: {"theme": "base", "themeVariables": {
  "fontFamily": "system-ui, sans-serif",
  "lineColor": "#ff2e97",
  "primaryColor": "#0d2a2a",
  "primaryTextColor": "#ffffff",
  "primaryBorderColor": "#00fff5",
  "secondaryColor": "#120a18",
  "secondaryTextColor": "#ff2e97",
  "secondaryBorderColor": "#ff2e97",
  "tertiaryColor": "#0a1215",
  "tertiaryTextColor": "#9d4edd",
  "tertiaryBorderColor": "#9d4edd"
}}}%%
flowchart TB
    classDef actor fill:#2a0f1e,stroke:#ff2e97,stroke-width:2px,color:#ff2e97
    classDef core fill:#0d2a2a,stroke:#00fff5,stroke-width:3px,color:#00fff5
    classDef external fill:#1a0d24,stroke:#9d4edd,stroke-width:2px,color:#9d4edd

    subgraph users ["USERS"]
        developer["<b>Developer</b><br/> <br/><span>Software engineer using Claude Code</span><br/><span>macOS/Linux Terminal or VS Code</span>"]:::actor
    end

    subgraph orchestrators ["ORCHESTRATORS"]
        orchestrator["<b>Portfolio Orchestrator</b><br/> <br/><span>Product investment system, CI/CD, or dashboard</span><br/><span>Spawns CLI processes per ADR-001</span>"]:::external
    end

    subgraph system ["GENIE TEAM"]
        genie_team["<b>Genie Team</b><br/> <br/><span>Workflow extensions for structured AI collaboration</span><br/><span>Markdown prompts + Bash installer</span>"]:::core
    end

    subgraph external_boundary ["EXTERNAL"]
        claude_code["<b>Claude Code CLI</b><br/> <br/><span>AI coding assistant runtime</span><br/><span>Node.js CLI (Anthropic)</span>"]:::external
        anthropic_api["<b>Anthropic API</b><br/> <br/><span>LLM inference for Claude models</span><br/><span>HTTPS REST (api.anthropic.com)</span>"]:::external
        target_project["<b>Target Project</b><br/> <br/><span>Codebase receiving genie artifacts</span><br/><span>Local Git repository (macOS/Linux)</span>"]:::external
    end

    developer -->|"invokes slash commands"| genie_team
    orchestrator -->|"spawns headless CLI processes"| genie_team
    genie_team -->|"extends via .claude/ directories"| claude_code
    claude_code -->|"sends prompts, receives completions"| anthropic_api
    genie_team -->|"writes specs, backlog, ADRs, diagrams"| target_project
    claude_code -->|"reads/writes code"| target_project
    orchestrator -->|"creates PRs, tracks progress"| target_project
```

## Coupling Notes

### Runtime Dependencies
- Genie Team requires Claude Code CLI as the execution environment
- Claude Code CLI requires Anthropic API for LLM inference
- All genie commands execute within Claude Code's conversation context
- External orchestrators (optional) spawn CLI processes for autonomous execution

### Build-time Dependencies
- `install.sh` copies commands, skills, rules, and agents to `.claude/` directories
- No compilation — all artifacts are markdown prompt templates

### Data Dependencies
- Document trail (specs, backlog, ADRs, diagrams) persists in target project's `docs/` directory
- Claude Code manages ephemeral conversation context and tool state
- Target project's git repository provides version control for all artifacts

### External Orchestration

Per ADR-001 (Thin Orchestrator architecture):
- Orchestrators treat genie-team CLI as a black box
- Spawn CLI processes via `claude -p` with `--output-format json` or `stream-json`
- Parse structured output for progress monitoring and artifact detection
- No shared runtime state between orchestrator and genies
- See `docs/architecture/cli-contract.md` for the full integration contract

```
Orchestrator → spawns → claude -p "/deliver ..." → operates on → Repository
     ↑                        ↓
     └── JSON/stream output ←─┘
```
