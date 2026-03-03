---
name: debugging
description: "Structured root cause investigation when tests fail unexpectedly or fixes don't resolve the issue. Use when a test fails that you expected to pass, when a previous fix attempt didn't work, or when an error occurs during implementation."
allowed-tools: Read, Grep, Glob, Bash(npm test*), Bash(npm run test*), Bash(npx vitest*), Bash(pytest*), Bash(jest*), Bash(cargo test*), Bash(cargo check*), Bash(cargo clippy*), Bash(go test*), Bash(go vet*), Bash(go build*), Bash(dotnet test*), Bash(dotnet build*), Bash(mvn test*), Bash(mvn compile*), Bash(gradle test*), Bash(gradle build*), Bash(make test*), Bash(make check*), Bash(git diff*), Bash(git log*)
---

# Systematic Debugging

When a test fails unexpectedly or a fix attempt doesn't work, follow this protocol.
Do NOT improvise. Do NOT try random changes.

## Attempt Counter

Track your fix attempts. Each time you modify code to fix the issue, increment the counter.

- **Attempt 1-3:** Follow the 4-phase protocol below
- **Attempt 3+ (ESCALATION):** STOP. See Escalation Protocol.

## Phase 1: Reproduce and Read

1. Run the failing test in isolation. Capture the EXACT error message.
2. Read the error message completely — every line, every stack frame.
3. Identify: What was expected? What actually happened? Where did execution diverge?
4. Do NOT attempt a fix yet.

**Output:** A 1-2 sentence root cause hypothesis based on reading the error.

## Phase 2: Pattern Analysis

1. Compare working code vs broken code. What changed?
   - `git diff` to see recent changes
   - Compare with a similar test that passes
2. Look for the SIMPLEST explanation first:
   - Typo? Wrong variable name?
   - Missing import? Wrong path?
   - Stale state? Missing setup?
3. Check if the error matches a known pattern:
   - "Cannot find module" — import path or missing dependency
   - "undefined is not a function" — wrong method name or missing mock
   - "expected X received Y" — logic error or wrong test data

**Output:** Refined hypothesis with specific location (file:line).

## Phase 3: Hypothesis Testing

1. Form ONE hypothesis about the root cause
2. Make ONE change to test that hypothesis
3. Run the test
4. If it passes: Go to Phase 4
5. If it fails: Return to Phase 1 with the NEW error message
   (Increment attempt counter)

**Rules:**
- ONE change at a time. Never change multiple things.
- If the hypothesis was wrong, REVERT the change before trying the next one.
- Each failed hypothesis is data — write down what you learned.

## Phase 4: Implement the Fix

Once root cause is confirmed:

1. REVERT the hypothesis test change (if it was a hack)
2. Write a failing test that captures the root cause (TDD RED phase)
3. Implement the proper fix (TDD GREEN phase)
4. Verify all tests pass (including the original failing test)

This phase hands off to the tdd-discipline skill.

## Escalation Protocol

**TRIGGERED AT: 3 failed fix attempts.**

STOP. Do not attempt another fix. Instead:

1. Re-read the ORIGINAL error message (not the latest one — you may have drifted)
2. Question your assumptions:
   - "Am I looking at the right file?"
   - "Am I understanding the error correctly?"
   - "Is my mental model of how this code works actually correct?"
   - "Could the problem be in test setup rather than implementation?"
   - "Could this be an environmental issue (dependency version, config)?"
3. Read the code path from entry point to failure — don't skim, READ
4. If still stuck: Ask for help (interactive) or document the block and stop (headless)

**In headless mode:** After escalation, set execution report status to `blocked`
with a clear description of what was tried and what failed.

## RED FLAGS — Stop Immediately

| Anti-Pattern | Signal | Response |
|--------------|--------|----------|
| Shotgun debugging | You're changing multiple things at once | STOP. Revert all. Pick ONE hypothesis. |
| Symptom fixing | Your fix suppresses the error without understanding why it occurs | STOP. Return to Phase 1. Find root cause. |
| "It works now" | Tests pass but you can't explain why your change fixed it | STOP. Revert and reproduce. Understand the mechanism. |
| Escalating complexity | Each fix attempt is more complex than the last | STOP. Trigger escalation — your mental model is wrong. |
| Test modification | You're tempted to change the test to match your code | STOP. The test defines expected behavior. Fix implementation. |
