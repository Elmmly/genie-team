---
adr_version: "1.0"
type: adr
id: ADR-006
title: "Use SDK Hooks Over Stream Message Parsing"
status: accepted
created: 2026-04-01
deciders: [crafter, navigator]
tags: [architecture, sdk, hooks, artifact-tracking]
---

# ADR-006: Use SDK Hooks Over Stream Message Parsing

## Context

The TypeScript orchestrator (ADR-005) needs to observe tool use events during phase execution — specifically to track which files are written (artifact tracking) and potentially for future governance (cost enforcement, audit logging).

Two approaches were considered for observing tool use:

### Option A: Parse SDK stream messages

The `query()` async generator yields `SDKMessage` objects. Tool use information is embedded inside `SDKAssistantMessage.message.content[]` as Anthropic API content blocks (`{ type: "tool_use", name, input }`). We could parse these messages in our `onMessage` stream callback.

### Option B: Use SDK PostToolUse hooks

The `query()` options accept a `hooks` parameter with typed callback matchers. `PostToolUse` hooks fire after each tool execution with `tool_name`, `tool_input`, and `tool_response` provided directly by the SDK as a stable, documented interface.

## Decision

**Accepted.** Use SDK `PostToolUse` hooks for tool use observation. Do not parse stream message internals.

### Rationale

1. **Stable contract.** The `PostToolUseHookInput` type (`tool_name`, `tool_input`, `tool_response`) is part of the SDK's public API. Stream message structure (`SDKAssistantMessage.message.content[]`) is an implementation detail that mirrors the Anthropic API wire format — it could change with API versions without being considered a breaking SDK change.

2. **No structural coupling.** Stream parsing requires knowledge of the Anthropic message content block schema (tool_use blocks nested in content arrays). SDK hooks abstract this away — the hook receives flat fields.

3. **Consistent with SDK design intent.** ADR-005 chose the SDK specifically for its hook system (PostToolUse, Stop, maxBudgetUsd). Using hooks for artifact tracking is consistent with that decision. Parsing stream messages would bypass the mechanism we adopted the SDK to get.

## Implementation

`PhaseHooks` defines an `onToolUse` callback with our own `ToolUseEvent` type (`toolName`, `toolInput`). In `runPhase()`, this is translated to an SDK `PostToolUse` hook matcher on the `query()` options. Callers never see SDK hook types — they work with our abstraction.

```
PhaseHooks.onToolUse → runPhase() → query({ hooks: { PostToolUse: [...] } })
```

`PhaseHooks.onMessage` remains available for general stream observation (session init, result capture) but is not used for tool use events.

## Consequences

**Positive:**
- Artifact tracking is decoupled from Anthropic API message format
- Future tool observation (cost per tool, governance) uses the same hook path
- `PhaseHooks` interface is stable regardless of SDK stream changes

**Negative:**
- SDK hooks are async (`Promise<HookJSONOutput>`) even for read-only observation, adding minor overhead
- If the SDK changes hook semantics (e.g., hook return values gaining side effects), we'd need to audit our passthrough callbacks
