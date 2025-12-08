# Discovery: Enforcing TDD Test-First Practice in Crafter Agent

**Date:** 2025-12-08
**Scout:** Navigator + Scout Agent
**Topic:** TDD enforcement for Crafter genie

---

## 1. Context Summary

### What We Know
- The `/deliver` command invokes "Crafter" genie with documented TDD discipline
- Current documentation mentions "Tests FIRST, then implementation" but Claude still tends to write implementation code first
- Anthropic explicitly identifies TDD as their "favorite workflow" for Claude Code with agentic coding
- Without explicit constraints, Claude defaults to implementation-first behavior

### Current State
The `/deliver` command (commands/deliver.md:73-79) specifies:
```
Crafter follows strict TDD:
1. Red - Write failing test
2. Green - Minimal code to pass
3. Refactor - Clean up while green
```

However, this is **descriptive** rather than **prescriptive** - it describes what should happen but doesn't enforce it through explicit constraints in the prompt.

---

## 2. Opportunity Frame

### Jobs to Be Done
**Primary Job:** "When I invoke `/deliver`, I want Claude to write comprehensive failing tests BEFORE any implementation code so I can have a clear specification and safety net, knowing the tests weren't written to match existing buggy code."

**Related Jobs:**
- Validate that tests actually fail before implementation
- Ensure tests follow consistent structure (AAA pattern)
- Prevent "test overfitting" where tests assert current behavior rather than desired behavior

### Desired Outcomes
1. Tests are committed BEFORE any implementation code is written
2. Tests demonstrably fail (red phase validated)
3. Implementation follows without modifying tests
4. Clear separation between test-writing and implementation phases

---

## 3. Evidence Analysis

### Research Findings

#### A. Why Claude Skips Tests
From multiple sources:
- Claude defaults to "helpful" behavior = solving the problem directly
- Without explicit constraints, it generates implementation immediately
- Natural language TDD instructions are interpreted as "nice to have" not "mandatory"

#### B. Proven Techniques for TDD Enforcement

**1. Explicit Phase Separation**
```
"Do NOT write any implementation code. Write ONLY failing tests for [functionality]."
```
Then separately:
```
"Do NOT modify the tests. Write minimal code to make them pass."
```

**2. CLAUDE.md/System Prompt Embedding**
Persistent instructions in project configuration outperform one-time prompts. Key pattern:
```markdown
## TDD Requirements
YOU MUST follow TDD discipline:
1. Write failing tests FIRST
2. Run tests to CONFIRM they fail
3. Commit tests BEFORE writing implementation
4. Implementation phase: Do NOT modify tests
```

**3. Arrange-Act-Assert (AAA) Pattern**
Structure that improves test quality:
- **Arrange**: Set up test data and prerequisites
- **Act**: Execute single method/function being tested
- **Assert**: Verify expected outcome

Best practices:
- Separate phases with blank lines
- One action per test
- No if/else logic in tests
- Specific assertions (not just "not null")

**4. Workflow Automation (TDD Guard)**
Tools like `tdd-guard` intercept write operations and validate test coverage before allowing implementation.

---

## 4. Assumption Map

| Assumption | Type | Risk | Evidence |
|------------|------|------|----------|
| Explicit "Do NOT write implementation" constraint will change behavior | Usability | Low | Multiple sources confirm this works |
| Two-phase prompts (tests, then implementation) enforce discipline | Usability | Low | Anthropic best practices, testimonials |
| CLAUDE.md embedding creates consistent behavior | Usability | Low | Documented effectiveness |
| AAA pattern improves test quality | Value | Low | Industry consensus |
| Validation step (run tests, confirm fail) is essential | Usability | Medium | Without it, Claude may skip to green |
| Current `/deliver` prompt is too permissive | Root Cause | Low | Direct observation of behavior |

### Riskiest Assumption
**The two-phase approach will work without explicit hooks/automation** - Claude may still combine phases unless we structurally enforce separation.

---

## 5. Recommended Solutions

### Option A: Enhanced Prompt Language (Low Effort)

Update `/deliver` command to include explicit constraints:

```markdown
## TDD Discipline (REQUIRED)

### Phase 1: Red (Tests First)
YOU MUST write all tests BEFORE any implementation code.
- Write tests that define expected behavior
- Tests MUST use Arrange-Act-Assert pattern
- Run tests and CONFIRM they fail
- Do NOT proceed until tests are committed

### Phase 2: Green (Minimal Implementation)
ONLY after tests are committed:
- Write minimal code to make tests pass
- Do NOT modify the tests themselves
- If a test is wrong, stop and escalate

### Test Structure (AAA Pattern)
```
// Arrange - Set up test data
const user = createTestUser({ role: 'admin' });
const request = mockRequest({ userId: user.id });

// Act - Single action being tested
const result = await authService.validateAccess(request);

// Assert - Verify outcome
expect(result.allowed).toBe(true);
expect(result.role).toBe('admin');
```
```

### Option B: Structural Separation (Medium Effort)

Split `/deliver` into enforced sub-commands:

1. `/deliver:tests` - ONLY writes tests, blocks if implementation attempted
2. `/deliver:validate` - Runs tests, confirms they fail
3. `/deliver:implement` - ONLY writes implementation, blocks test modification

Workflow becomes:
```
/deliver:tests → /deliver:validate → /deliver:implement
```

### Option C: Hook Enforcement (Higher Effort)

Implement TDD Guard-style hooks:
- PreToolUse hook on Write/Edit operations
- Validates that tests exist and fail before allowing implementation files
- Blocks writes to src/ if no failing tests in tests/

### Option D: CLAUDE.md Template Update

Add TDD section to templates/CLAUDE.md:

```markdown
## TDD Requirements (All Code Changes)

This project enforces Test-Driven Development:

### Red-Green-Refactor
1. **RED**: Write failing tests that define behavior
2. **GREEN**: Minimal implementation to pass tests
3. **REFACTOR**: Improve code quality while green

### Constraints
- NEVER write implementation without failing tests first
- NEVER modify tests to make them pass
- Tests use Arrange-Act-Assert pattern
- One assertion focus per test

### Crafter Agent
The `/deliver` command enforces TDD:
- Phase 1: Write and commit failing tests
- Phase 2: Implement without modifying tests
- Report violations if tests weren't written first
```

---

## 6. Recommended Path

### Immediate (Option A + D)
1. Update `/deliver` command with explicit constraint language
2. Add TDD section to templates/CLAUDE.md
3. Include AAA pattern examples

### Next Sprint (Option B)
1. Implement structural separation with sub-command enforcement
2. Add validation step between phases

### Future (Option C)
1. Investigate hook-based enforcement
2. Consider tdd-guard integration

---

## Sources

**Anthropic Official:**
- [Claude Code: Best practices for agentic coding](https://www.anthropic.com/engineering/claude-code-best-practices)

**TDD with Claude:**
- [Test-Driven Development with Claude Code - Steve Kinney](https://stevekinney.com/courses/ai-development/test-driven-development-with-claude)
- [Taming GenAI Agents: How TDD Transforms Claude Code - Nathan Fox](https://www.nathanfox.net/p/taming-genai-agents-like-claude-code)
- [CLAUDE MD TDD - claude-flow wiki](https://github.com/ruvnet/claude-flow/wiki/CLAUDE-MD-TDD)
- [TDD Guard](https://github.com/nizos/tdd-guard)

**AAA Pattern:**
- [Arrange-Act-Assert: A Pattern for Writing Good Tests - Automation Panda](https://automationpanda.com/2020/07/07/arrange-act-assert-a-pattern-for-writing-good-tests/)
- [The AAA Pattern in Unit Test Automation - Semaphore](https://semaphore.io/blog/aaa-pattern-test-automation)

**Prompt Engineering:**
- [An example of LLM prompting for programming - Martin Fowler](https://martinfowler.com/articles/2023-chatgpt-xu-hao.html)
- [A developer's guide to prompt engineering - GitHub Blog](https://github.blog/ai-and-ml/generative-ai/prompt-engineering-guide-generative-ai-llms/)
