import { describe, it, expect, vi, beforeEach } from "vitest";
import { LLMApiExecutor } from "./llm-api-executor.js";
import type { LLMClient, CompletionResponse, CompletionOptions, Message, ToolExecutor, Tool } from "./llm-types.js";

function mockClient(responses: CompletionResponse[]): LLMClient {
  let callIdx = 0;
  return {
    name: "mock",
    complete: vi.fn(async () => responses[callIdx++] ?? responses[responses.length - 1]),
  };
}

function mockToolExecutor(): ToolExecutor {
  return {
    execute: vi.fn(async () => "tool result"),
    availableTools: () => [
      { name: "Read", description: "Read a file", inputSchema: {} },
      { name: "Write", description: "Write a file", inputSchema: {} },
    ],
  };
}

describe("LLMApiExecutor", () => {
  it("has name and tier 2", () => {
    // Arrange
    const executor = new LLMApiExecutor(mockClient([]), mockToolExecutor());

    // Assert
    expect(executor.name).toBe("llm-api");
    expect(executor.tier).toBe(2);
  });

  it("returns result when LLM responds without tool calls", async () => {
    // Arrange
    const client = mockClient([{
      content: "Discovery complete.",
      toolCalls: [],
      usage: { inputTokens: 100, outputTokens: 50 },
      finishReason: "end_turn",
    }]);
    const executor = new LLMApiExecutor(client, mockToolExecutor());

    // Act
    const result = await executor.runPhase("discover", "test topic");

    // Assert
    expect(result.output).toBe("Discovery complete.");
    expect(result.numTurns).toBe(1);
  });

  it("executes tool calls and continues the loop", async () => {
    // Arrange
    const client = mockClient([
      {
        content: "",
        toolCalls: [{ id: "tc1", name: "Read", input: { file_path: "/tmp/test.txt" } }],
        usage: { inputTokens: 100, outputTokens: 50 },
        finishReason: "tool_use",
      },
      {
        content: "Read the file, here's what I found.",
        toolCalls: [],
        usage: { inputTokens: 200, outputTokens: 100 },
        finishReason: "end_turn",
      },
    ]);
    const tools = mockToolExecutor();
    const executor = new LLMApiExecutor(client, tools);

    // Act
    const result = await executor.runPhase("deliver", "docs/backlog/item.md");

    // Assert
    expect(tools.execute).toHaveBeenCalledWith("Read", { file_path: "/tmp/test.txt" });
    expect(result.output).toBe("Read the file, here's what I found.");
    expect(result.numTurns).toBe(2);
  });

  it("accumulates token usage across turns", async () => {
    // Arrange
    const client = mockClient([
      {
        content: "",
        toolCalls: [{ id: "tc1", name: "Read", input: {} }],
        usage: { inputTokens: 100, outputTokens: 50 },
        finishReason: "tool_use",
      },
      {
        content: "Done.",
        toolCalls: [],
        usage: { inputTokens: 200, outputTokens: 100 },
        finishReason: "end_turn",
      },
    ]);
    const executor = new LLMApiExecutor(client, mockToolExecutor());

    // Act
    const result = await executor.runPhase("deliver", "item.md");

    // Assert
    expect(result.inputTokens).toBe(300);
    expect(result.outputTokens).toBe(150);
  });

  it("stops at maxTurns and marks exhausted", async () => {
    // Arrange — always returns tool calls, never finishes
    const client = mockClient([{
      content: "",
      toolCalls: [{ id: "tc1", name: "Read", input: {} }],
      usage: { inputTokens: 100, outputTokens: 50 },
      finishReason: "tool_use",
    }]);
    const executor = new LLMApiExecutor(client, mockToolExecutor());

    // Act
    const result = await executor.runPhase("deliver", "item.md", {
      turnOverrides: { global: 3 },
    });

    // Assert
    expect(result.numTurns).toBe(3);
    expect(result.exhausted).toBe(true);
  });

  it("calls onToolUse hook for each tool call", async () => {
    // Arrange
    const onToolUse = vi.fn();
    const client = mockClient([
      {
        content: "",
        toolCalls: [{ id: "tc1", name: "Write", input: { file_path: "src/new.ts" } }],
        usage: { inputTokens: 100, outputTokens: 50 },
        finishReason: "tool_use",
      },
      {
        content: "Done.",
        toolCalls: [],
        usage: { inputTokens: 100, outputTokens: 50 },
        finishReason: "end_turn",
      },
    ]);
    const executor = new LLMApiExecutor(client, mockToolExecutor());

    // Act
    await executor.runPhase("deliver", "item.md", {
      hooks: { onToolUse },
    });

    // Assert
    expect(onToolUse).toHaveBeenCalledWith({
      toolName: "Write",
      toolInput: { file_path: "src/new.ts" },
    });
  });

  it("calls onResult hook with final result", async () => {
    // Arrange
    const onResult = vi.fn();
    const client = mockClient([{
      content: "Done.",
      toolCalls: [],
      usage: { inputTokens: 100, outputTokens: 50 },
      finishReason: "end_turn",
    }]);
    const executor = new LLMApiExecutor(client, mockToolExecutor());

    // Act
    await executor.runPhase("discover", "topic", {
      hooks: { onResult },
    });

    // Assert
    expect(onResult).toHaveBeenCalledTimes(1);
    expect(onResult).toHaveBeenCalledWith(expect.objectContaining({
      output: "Done.",
    }));
  });

  it("passes system prompt with phase context", async () => {
    // Arrange
    const client = mockClient([{
      content: "Done.",
      toolCalls: [],
      usage: { inputTokens: 100, outputTokens: 50 },
      finishReason: "end_turn",
    }]);
    const executor = new LLMApiExecutor(client, mockToolExecutor());

    // Act
    await executor.runPhase("discover", "auth improvements");

    // Assert
    const callArgs = (client.complete as ReturnType<typeof vi.fn>).mock.calls[0];
    const options = callArgs[1] as CompletionOptions;
    expect(options.system).toContain("discover");
  });

  it("loads CLAUDE.md into system prompt when present", async () => {
    // Arrange
    const client = mockClient([{
      content: "Done.",
      toolCalls: [],
      usage: { inputTokens: 100, outputTokens: 50 },
      finishReason: "end_turn",
    }]);
    const executor = new LLMApiExecutor(client, mockToolExecutor());

    // Act — run from the actual project root which has CLAUDE.md
    await executor.runPhase("discover", "test", { cwd: process.cwd() });

    // Assert
    const callArgs = (client.complete as ReturnType<typeof vi.fn>).mock.calls[0];
    const options = callArgs[1] as CompletionOptions;
    expect(options.system).toContain("Genie Team");
  });
});
