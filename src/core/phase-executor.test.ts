import { describe, it, expect, vi, beforeEach } from "vitest";
import { runPhase, type PhaseResult, type PhaseOptions } from "./phase-executor.js";

// Mock the SDK
vi.mock("@anthropic-ai/claude-agent-sdk", () => ({
  query: vi.fn(),
}));

import { query } from "@anthropic-ai/claude-agent-sdk";

function mockQueryMessages(messages: Array<Record<string, unknown>>) {
  vi.mocked(query).mockImplementation(async function* () {
    for (const msg of messages) {
      yield msg;
    }
  } as never);
}

describe("runPhase", () => {
  beforeEach(() => {
    vi.resetAllMocks();
  });

  it("returns result text from a successful phase", async () => {
    // Arrange
    mockQueryMessages([
      { type: "system", subtype: "init", session_id: "sess-123" },
      {
        type: "result", subtype: "success",
        result: "Discovery complete. Found 3 opportunities.",
        stop_reason: null,
        usage: { input_tokens: 500, output_tokens: 200 },
        total_cost_usd: 0.01,
        num_turns: 5,
      },
    ]);

    // Act
    const result = await runPhase("discover", "user authentication");

    // Assert
    expect(result.output).toBe("Discovery complete. Found 3 opportunities.");
    expect(result.sessionId).toBe("sess-123");
  });

  it("captures token usage and cost", async () => {
    // Arrange
    mockQueryMessages([
      { type: "system", subtype: "init", session_id: "sess-456" },
      {
        type: "result", subtype: "success",
        result: "Done",
        stop_reason: null,
        usage: { input_tokens: 1000, output_tokens: 500 },
        total_cost_usd: 0.05,
        num_turns: 10,
      },
    ]);

    // Act
    const result = await runPhase("deliver", "docs/backlog/P0-item.md");

    // Assert
    expect(result.inputTokens).toBe(1000);
    expect(result.outputTokens).toBe(500);
    expect(result.costUsd).toBe(0.05);
    expect(result.numTurns).toBe(10);
  });

  it("passes correct options to SDK query", async () => {
    // Arrange
    mockQueryMessages([
      { type: "system", subtype: "init", session_id: "sess-789" },
      { type: "result", subtype: "success", result: "Ok", stop_reason: null,usage: { input_tokens: 0, output_tokens: 0 }, total_cost_usd: 0, num_turns: 1 },
    ]);

    // Act
    await runPhase("deliver", "docs/backlog/P0-item.md", {
      model: "claude-sonnet-4-6",
      skipPermissions: true,
    });

    // Assert
    const callArgs = vi.mocked(query).mock.calls[0][0] as Record<string, unknown>;
    expect(callArgs.prompt).toContain("/deliver");
    expect(callArgs.prompt).toContain("docs/backlog/P0-item.md");
    const opts = callArgs.options as Record<string, unknown>;
    expect(opts.maxTurns).toBe(100); // deliver default
    expect(opts.allowedTools).toContain("Bash");
    expect(opts.allowedTools).toContain("Write");
    expect(opts.model).toBe("claude-sonnet-4-6");
    expect(opts.permissionMode).toBe("bypassPermissions");
    expect(opts.allowDangerouslySkipPermissions).toBe(true);
  });

  it("loads project settings for CLAUDE.md context", async () => {
    // Arrange
    mockQueryMessages([
      { type: "system", subtype: "init", session_id: "sess-ctx" },
      { type: "result", subtype: "success", result: "Ok", stop_reason: null,usage: { input_tokens: 0, output_tokens: 0 }, total_cost_usd: 0, num_turns: 1 },
    ]);

    // Act
    await runPhase("design", "docs/backlog/P0-item.md");

    // Assert
    const callArgs = vi.mocked(query).mock.calls[0][0] as Record<string, unknown>;
    const opts = callArgs.options as Record<string, unknown>;
    expect(opts.settingSources).toContain("user");
    expect(opts.settingSources).toContain("project");
  });

  it("supports session resume", async () => {
    // Arrange
    mockQueryMessages([
      { type: "system", subtype: "init", session_id: "sess-resume" },
      { type: "result", subtype: "success", result: "Resumed", stop_reason: null,usage: { input_tokens: 0, output_tokens: 0 }, total_cost_usd: 0, num_turns: 1 },
    ]);

    // Act
    await runPhase("deliver", "docs/backlog/P0-item.md", {
      resumeSessionId: "sess-previous",
    });

    // Assert
    const callArgs = vi.mocked(query).mock.calls[0][0] as Record<string, unknown>;
    const opts = callArgs.options as Record<string, unknown>;
    expect(opts.resume).toBe("sess-previous");
  });

  it("reports error_max_turns as turn exhaustion", async () => {
    // Arrange
    mockQueryMessages([
      { type: "system", subtype: "init", session_id: "sess-exhaust" },
      {
        type: "result", subtype: "error_max_turns",
        result: "Partial work done",
        stop_reason: null,
        usage: { input_tokens: 500, output_tokens: 200 },
        total_cost_usd: 0.02,
        num_turns: 50,
      },
    ]);

    // Act
    const result = await runPhase("deliver", "docs/backlog/P0-item.md");

    // Assert
    expect(result.exhausted).toBe(true);
    expect(result.output).toBe("Partial work done");
  });

  it("respects turn overrides", async () => {
    // Arrange
    mockQueryMessages([
      { type: "system", subtype: "init", session_id: "sess-turns" },
      { type: "result", subtype: "success", result: "Ok", stop_reason: null,usage: { input_tokens: 0, output_tokens: 0 }, total_cost_usd: 0, num_turns: 1 },
    ]);

    // Act
    await runPhase("deliver", "docs/backlog/P0-item.md", {
      turnOverrides: { deliver: 200 },
    });

    // Assert
    const callArgs = vi.mocked(query).mock.calls[0][0] as Record<string, unknown>;
    const opts = callArgs.options as Record<string, unknown>;
    expect(opts.maxTurns).toBe(200);
  });

  it("applies trunk mode to prompt", async () => {
    // Arrange
    mockQueryMessages([
      { type: "system", subtype: "init", session_id: "sess-trunk" },
      { type: "result", subtype: "success", result: "Ok", stop_reason: null,usage: { input_tokens: 0, output_tokens: 0 }, total_cost_usd: 0, num_turns: 1 },
    ]);

    // Act
    await runPhase("deliver", "docs/backlog/P0-item.md", {
      trunkMode: true,
    });

    // Assert
    const callArgs = vi.mocked(query).mock.calls[0][0] as Record<string, unknown>;
    expect(callArgs.prompt).toContain("git-mode: trunk");
  });
});

describe("runPhase hooks", () => {
  beforeEach(() => {
    vi.resetAllMocks();
  });

  it("calls onResult with final PhaseResult", async () => {
    // Arrange
    mockQueryMessages([
      { type: "system", subtype: "init", session_id: "sess-result-hook" },
      { type: "result", subtype: "success", result: "Phase done", stop_reason: null,usage: { input_tokens: 500, output_tokens: 200 }, total_cost_usd: 0.03, num_turns: 5 },
    ]);
    const onResult = vi.fn();

    // Act
    await runPhase("deliver", "docs/backlog/P0-item.md", { hooks: { onResult } });

    // Assert
    expect(onResult).toHaveBeenCalledTimes(1);
    expect(onResult).toHaveBeenCalledWith(expect.objectContaining({
      output: "Phase done",
      sessionId: "sess-result-hook",
      costUsd: 0.03,
      numTurns: 5,
    }));
  });

  it("works with no hooks provided (backward compatible)", async () => {
    // Arrange
    mockQueryMessages([
      { type: "system", subtype: "init", session_id: "sess-no-hooks" },
      { type: "result", subtype: "success", result: "Ok", stop_reason: null,usage: { input_tokens: 0, output_tokens: 0 }, total_cost_usd: 0, num_turns: 1 },
    ]);

    // Act
    const result = await runPhase("discover", "topic");

    // Assert
    expect(result.output).toBe("Ok");
  });

});

describe("runPhase auth mode", () => {
  beforeEach(() => {
    vi.resetAllMocks();
  });

  it("passes env without ANTHROPIC_API_KEY when authMode is oauth", async () => {
    // Arrange
    mockQueryMessages([
      { type: "system", subtype: "init", session_id: "sess-oauth" },
      { type: "result", subtype: "success", result: "Ok", stop_reason: null,usage: { input_tokens: 0, output_tokens: 0 }, total_cost_usd: 0, num_turns: 1 },
    ]);

    // Act
    await runPhase("deliver", "item.md", { authMode: "oauth" });

    // Assert
    const callArgs = vi.mocked(query).mock.calls[0][0] as Record<string, unknown>;
    const opts = callArgs.options as Record<string, unknown>;
    const env = opts.env as Record<string, string | undefined>;
    expect(env).toBeDefined();
    expect(env.ANTHROPIC_API_KEY).toBeUndefined();
  });

  it("does not set env override when authMode is apikey", async () => {
    // Arrange
    mockQueryMessages([
      { type: "system", subtype: "init", session_id: "sess-apikey" },
      { type: "result", subtype: "success", result: "Ok", stop_reason: null,usage: { input_tokens: 0, output_tokens: 0 }, total_cost_usd: 0, num_turns: 1 },
    ]);

    // Act
    await runPhase("deliver", "item.md", { authMode: "apikey" });

    // Assert
    const callArgs = vi.mocked(query).mock.calls[0][0] as Record<string, unknown>;
    const opts = callArgs.options as Record<string, unknown>;
    expect(opts.env).toBeUndefined();
  });

  it("does not set env override when no authMode", async () => {
    // Arrange
    mockQueryMessages([
      { type: "system", subtype: "init", session_id: "sess-default" },
      { type: "result", subtype: "success", result: "Ok", stop_reason: null,usage: { input_tokens: 0, output_tokens: 0 }, total_cost_usd: 0, num_turns: 1 },
    ]);

    // Act
    await runPhase("deliver", "item.md");

    // Assert
    const callArgs = vi.mocked(query).mock.calls[0][0] as Record<string, unknown>;
    const opts = callArgs.options as Record<string, unknown>;
    expect(opts.env).toBeUndefined();
  });
});

describe("runPhase SDK hooks wiring", () => {
  beforeEach(() => {
    vi.resetAllMocks();
  });

  it("wires onToolUse to SDK PostToolUse hook", async () => {
    // Arrange
    mockQueryMessages([
      { type: "system", subtype: "init", session_id: "sess-hooks" },
      { type: "result", subtype: "success", result: "Ok", stop_reason: null,usage: { input_tokens: 0, output_tokens: 0 }, total_cost_usd: 0, num_turns: 1 },
    ]);
    const onToolUse = vi.fn();

    // Act
    await runPhase("deliver", "item.md", { hooks: { onToolUse } });

    // Assert
    const callArgs = vi.mocked(query).mock.calls[0][0] as Record<string, unknown>;
    const opts = callArgs.options as Record<string, unknown>;
    const hooks = opts.hooks as Record<string, unknown[]>;
    expect(hooks).toBeDefined();
    expect(hooks.PostToolUse).toHaveLength(1);
  });

  it("does not set SDK hooks when no onToolUse provided", async () => {
    // Arrange
    mockQueryMessages([
      { type: "system", subtype: "init", session_id: "sess-no-hooks" },
      { type: "result", subtype: "success", result: "Ok", stop_reason: null,usage: { input_tokens: 0, output_tokens: 0 }, total_cost_usd: 0, num_turns: 1 },
    ]);

    // Act
    await runPhase("deliver", "item.md", { hooks: { onResult: vi.fn() } });

    // Assert
    const callArgs = vi.mocked(query).mock.calls[0][0] as Record<string, unknown>;
    const opts = callArgs.options as Record<string, unknown>;
    expect(opts.hooks).toBeUndefined();
  });
});
