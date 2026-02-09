# /diagnose [scope]

Activate Architect genie to perform codebase health scan and identify cleanup needs.

---

## Arguments

- `scope` - Area to diagnose: module, directory, or "full" (optional, defaults to full)

---

## Agent Identity

Read and internalize `.claude/agents/architect.md` for your identity, charter, and judgment rules. Operate in **diagnostic mode**.

---

## Context Loading

**READ (automatic):**
- docs/context/system_architecture.md
- docs/context/codebase_structure.md
- Target code files
- Test files
- docs/decisions/ADR-*.md (all ADRs for health analysis)
- docs/architecture/**/*.md (all C4 diagrams for coupling/cohesion analysis)

---

## Context Writing

**WRITE:**
- docs/cleanup/YYYYMMDD_diagnose_{scope}.md

**UPDATE:**
- docs/cleanup/defrag-progress.md (if exists)

---

## Output

Produces a **Diagnose Report** containing:
1. Health Summary - Overall assessment
2. Dead Code - Unreachable/unused code
3. Pattern Violations - Inconsistencies
4. Dependency Issues - Unused/outdated deps
5. Test Coverage Gaps - Untested areas
6. Prioritized Cleanup List - For Tidier
7. Architecture Health - Coupling violations, cohesion drift, ADR health, diagram staleness

---

## Usage Examples

```
/diagnose
> [Architect scans full codebase]
> Saved to docs/cleanup/20251203_diagnose_full.md
>
> Health: Moderate (score: 72/100)
>
> Issues found:
> - 5 dead functions (priority: low)
> - 3 unused imports (priority: low)
> - 1 pattern violation (priority: medium)
> - 2 outdated dependencies (priority: medium)
>
> Next: /tidy docs/cleanup/20251203_diagnose_full.md

/diagnose src/services
> [Architect scans services directory]
> Saved to docs/cleanup/20251203_diagnose_services.md
>
> Health: Good (score: 85/100)
> Minor issues only
```

---

## Health Metrics

| Metric | Weight | Description |
|--------|--------|-------------|
| Dead code | 15% | Unreachable functions, unused exports |
| Test coverage | 20% | Lines and branches covered |
| Pattern adherence | 20% | Following project conventions |
| Dependency health | 15% | Outdated, unused, vulnerable |
| Complexity | 10% | Cyclomatic complexity, nesting |
| Documentation | 10% | Public API documentation |
| Architecture | 10% | Coupling violations, cohesion drift, ADR health, diagram staleness |

---

## Architecture Analysis

When `docs/architecture/` and/or `docs/decisions/` directories exist, `/diagnose` performs architecture health checks. If neither directory exists, skip architecture analysis entirely and **warn**:
> No architecture artifacts found. Architecture health analysis skipped.

### Coupling Analysis
1. Load container diagram (`docs/architecture/containers.md`) and component diagrams (`docs/architecture/components/*.md`)
2. Parse `Rel()` arrows from Mermaid diagrams to build the declared dependency graph
3. Scan source code for actual import/dependency patterns (heuristic: directory structure + import scanning)
4. Flag:
   - **Undocumented dependencies:** Code imports crossing boundaries not declared in diagrams
   - **Stale dependencies:** Diagram arrows with no corresponding code evidence

### Cohesion Analysis
1. Load component diagrams for each domain
2. Check whether components import mostly within their domain (high cohesion) or heavily across domains
3. Compare against `## Cohesion Assessment` ratings — flag mismatches
4. Report: "Domain {X} rated HIGH cohesion but has {N} cross-domain imports"

### ADR Health
1. Scan all ADRs in `docs/decisions/`
2. Flag:
   - **Stale proposed ADRs:** `proposed` status with no recent `/design` activity
   - **Contradictory ADRs:** Multiple `accepted` ADRs with conflicting decisions
   - **Orphaned references:** `superseded` ADRs still referenced by active code

### Diagram Staleness
1. Check `updated` field in each diagram's frontmatter
2. Flag diagrams not updated within **90 days** as potentially stale
3. Report which diagrams need review

### Architecture Output Format

```markdown
## Architecture Health

### Coupling
- {N} documented dependencies, {M} undocumented found
- {finding description} — reference ADR-{NNN} for boundary rationale

### Cohesion
- {domain}: rated {RATING}, actual {assessment}

### ADR Status
- {N} accepted, {M} proposed (oldest: {date}), {K} superseded

### Diagram Staleness
- {diagram}: last updated {date} ({N} days ago) — STALE
```

---

## Routing

After diagnosis:
- If cleanup needed: `/tidy` with diagnose report
- If architectural issues: Address in next feature work
- If critical issues: Escalate to Navigator

---

## Notes

- Diagnostic only (no changes made)
- Creates prioritized cleanup backlog
- Pairs with /tidy for cleanup execution
- Run periodically for codebase health
