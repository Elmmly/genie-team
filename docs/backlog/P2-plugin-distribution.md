---
spec_version: "1.0"
type: shaped-work
id: P2-plugin-distribution
title: "Claude Code Plugin Distribution"
status: shaped
created: 2026-03-12
appetite: medium
priority: P2
author: shaper
discovery_ref: null
acceptance_criteria:
  - id: AC-1
    description: >-
      Genie-team artifacts (commands, agents, skills, rules, hooks) packaged
      as a Claude Code plugin with proper manifest, versioning (semver), and
      changelog. Plugin installable via Claude Code's plugin discovery system.
    status: pending
  - id: AC-2
    description: >-
      npm package `genie-team` published with `genies` CLI entry point.
      Users install via `npm install -g genie-team` or `npx genie-team`.
      Package includes compiled TypeScript orchestrator, shell hooks, and
      all markdown artifacts.
    status: pending
  - id: AC-3
    description: >-
      install.sh preserved as alternative installation path for users who
      prefer direct file copying or need offline installation. Documents
      that npm/plugin is the recommended path.
    status: pending
  - id: AC-4
    description: >-
      Version management: `genies version` shows installed version,
      `genies update` checks for and applies updates. Plugin marketplace
      and npm both support version checking.
    status: pending
---

# Shaped Work Contract: Claude Code Plugin Distribution

## Problem

Genie-team distributes via a 1,200-line `install.sh` that copies files to `.claude/` directories — a custom distribution mechanism when every other tool uses npm, pip, cargo, or Homebrew. There's no versioning (users get whatever's on their branch), no update mechanism, no changelogs, and no discoverability. Claude Code's plugin marketplace exists and accepts exactly the artifact types genie-team produces, but genie-team doesn't publish to it.

**Evidence:**
- Claude Code plugin system accepts commands, agents, skills, hooks, MCP servers (strong)
- npm is the natural distribution for TypeScript packages; users already have Node.js (strong)
- No current versioning or update mechanism exists (strong — direct observation)
- install.sh is 1,200 lines of bash with platform-specific workarounds (moderate)

## Appetite & Boundaries

- **Appetite:** Medium batch (3-5 days)
- **No-gos:**
  - No community genie marketplace — first-party distribution only (ClawHavoc lesson)
  - No removal of install.sh — preserve for offline/direct-copy use cases
  - No auto-update without user consent
- **Fixed elements:**
  - Semver versioning
  - Changelog in standard format
  - Both npm and plugin marketplace as distribution channels

## Goals & Outcomes

1. **Discoverability:** Users find genie-team through Claude Code's plugin system
2. **Standard install:** `npm install -g genie-team` — familiar, reliable, cross-platform
3. **Version management:** Users know what version they have and can update deliberately
4. **Reduced maintenance:** npm handles distribution; install.sh becomes the fallback path

## Risks & Assumptions

| Assumption | Type | Test |
|------------|------|------|
| Claude Code plugin system is mature enough for genie-team's full artifact set | Feasibility | Publish a minimal plugin (one command) and validate marketplace behavior |
| npm distribution works for markdown artifacts alongside compiled TS | Feasibility | Standard npm packaging; markdown files included via `files` in package.json |
| Users will adopt npm install over install.sh | Value | Provide both paths; track which one documentation references |

## Routing

**Next:** `/design` after P0-SDK-migration Phase 0 proves TypeScript toolchain. Plugin packaging builds on the npm project structure.
