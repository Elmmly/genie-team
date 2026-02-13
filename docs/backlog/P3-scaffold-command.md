---
spec_version: "1.0"
type: shaped-work
id: scaffold-command
title: "Scaffold Command — Infrastructure Generation from Architecture Decisions"
status: shaped
created: 2026-02-12
appetite: big
priority: P3
target_project: genie-team
author: shaper
depends_on: []
builds_on:
  - docs/archive/workflow/2026-02-12_autonomous-lifecycle-runner/P2-autonomous-lifecycle-runner.md
spec_ref: ""
adr_refs:
  - docs/decisions/ADR-001-thin-orchestrator.md
tags: [scaffold, infrastructure, docker, ci-cd, deployment, devops]
acceptance_criteria:
  - id: AC-1
    description: "/scaffold reads ADRs and C4 diagrams from docs/decisions/ and docs/architecture/ to understand infrastructure decisions, then generates config files"
    status: pending
  - id: AC-2
    description: "Generates Dockerfile and docker-compose.yml when ADRs indicate containerized deployment"
    status: pending
  - id: AC-3
    description: "Generates CI pipeline config (GitHub Actions .github/workflows/*.yml) when ADRs indicate CI/CD provider"
    status: pending
  - id: AC-4
    description: "Generates deployment configs appropriate to the ADR-specified target (e.g., Vercel vercel.json, AWS task definitions, K8s manifests)"
    status: pending
  - id: AC-5
    description: "Supports --dry-run to preview what would be generated without writing files"
    status: pending
  - id: AC-6
    description: "Generates a GitHub Actions workflow template for run-pdlc.sh integration (nightly discover+define, manual-trigger design+deliver)"
    status: pending
  - id: AC-7
    description: "Does not overwrite existing config files — warns and offers diff-based merge when conflicts detected"
    status: pending
---

# Scaffold Command — Infrastructure Generation from Architecture Decisions

## Problem/Opportunity Statement

Genie Team's architecture workshops (`/design --workshop`) and bootstrap commands (`/arch:init`) produce ADRs and C4 diagrams that document infrastructure decisions — which container runtime, which CI provider, which deployment target. But there's no command to *generate* the actual config files that implement those decisions. Users make the decisions in the workshop, then have to manually create Dockerfiles, CI pipelines, and deployment configs. This is the gap between architecture documentation and a running system.

## Evidence

- README review (2026-02-12) identified this as the largest capability gap in the user journey
- Section 5 (Local Dev, CI/CD & Deployment) currently says "What's Planned" with no implementation
- The headless runner (`run-pdlc.sh`) is cron-compatible but has no GitHub Actions template to invoke it
- ADRs already capture the decisions — the generation is mechanically straightforward given those inputs

## Appetite

**Big batch (1-2 weeks).** Multiple infrastructure targets, each with its own template and validation. The ADR-reading foundation exists, but the template library is new work.

## Solution Sketch

New `/scaffold` command that reads the project's ADRs and C4 diagrams, then generates appropriate infrastructure configs.

**Input:** ADRs from `docs/decisions/`, C4 diagrams from `docs/architecture/`, project structure scan.

**Output targets (incremental — ship what's useful first):**

1. **Docker** — `Dockerfile`, `docker-compose.yml`, `.dockerignore` based on detected language/framework + ADR container decisions
2. **GitHub Actions** — `.github/workflows/ci.yml` (test + lint), `.github/workflows/deploy.yml` (build + deploy), `.github/workflows/discover.yml` (nightly run-pdlc.sh)
3. **Deployment** — Provider-specific configs based on ADR deployment target (Vercel, AWS ECS, Fly.io, K8s)

**Phase approach:**
- Phase 1: Docker + GitHub Actions CI (most common, highest value)
- Phase 2: Deployment configs (provider-specific)
- Phase 3: Monitoring/observability setup

## Rabbit Holes

- Don't try to support every cloud provider — start with the 3-4 most common
- Don't generate application code (routes, models) — just infrastructure configs
- Don't auto-detect infrastructure decisions — read them from ADRs. If no ADRs exist, prompt the user to run `/design --workshop` first

## No-Gos

- No Terraform/Pulumi/CloudFormation generation (IaC is a separate, much larger concern)
- No secrets management (point to best practices, don't implement)
- No multi-environment orchestration (dev/staging/prod promotion pipelines) in Phase 1

# End of Shaped Work Contract
