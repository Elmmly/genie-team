# /diagnose [scope]

Activate Architect genie to perform codebase health scan and identify cleanup needs.

---

## Arguments

- `scope` - Area to diagnose: module, directory, or "full" (optional, defaults to full)

---

## Genie Invoked

**Architect** - In diagnostic mode, focusing on:
- Code health metrics
- Technical debt identification
- Pattern violations
- Dead code detection

---

## Context Loading

**READ (automatic):**
- docs/context/system_architecture.md
- docs/context/codebase_structure.md
- Target code files
- Test files

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
| Test coverage | 25% | Lines and branches covered |
| Pattern adherence | 20% | Following project conventions |
| Dependency health | 15% | Outdated, unused, vulnerable |
| Complexity | 15% | Cyclomatic complexity, nesting |
| Documentation | 10% | Public API documentation |

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
