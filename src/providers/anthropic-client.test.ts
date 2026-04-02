import { describe, it, expect, vi, beforeEach } from "vitest";
import { AnthropicLLMClient } from "./anthropic-client.js";
import type { Message } from "../core/llm-types.js";

// Mock the @anthropic-ai/sdk package
vi.mock("@anthropic-ai/sdk", () => {
  const mockCreate = vi.fn();
  return {
    default: class {
      messages = { create: mockCreate };
    },
    __mockCreate: mockCreate,
  };
});

// eslint-disable-next-line @typescript-eslint/no-explicit-any
const { __mockCreate } = await import("@anthropic-ai/sdk") as any;
const mockCreate = __mockCreate as ReturnType<typeof vi.fn>;

describe("AnthropicLLMClient", () => {
  let client: AnthropicLLMClient;

  beforeEach(() => {
    vi.resetAllMocks();
    client = new AnthropicLLMClient("test-key");
  });

  it("has name 'anthropic'", () => {
    expect(client.name).toBe("anthropic");
  });

  it("returns completion response from text content", async () => {
    // Arrange
    mockCreate.mockResolvedValue({
      content: [{ type: "text", text: "Hello from Claude" }],
      stop_reason: "end_turn",
      usage: { input_tokens: 100, output_tokens: 50 },
    });

    // Act
    const result = await client.complete(
      [{ role: "user", content: "Hello" }],
      { model: "claude-sonnet-4-6" },
    );

    // Assert
    expect(result.content).toBe("Hello from Claude");
    expect(result.toolCalls).toEqual([]);
    expect(result.usage.inputTokens).toBe(100);
    expect(result.usage.outputTokens).toBe(50);
    expect(result.finishReason).toBe("end_turn");
  });

  it("maps tool definitions to Anthropic format", async () => {
    // Arrange
    mockCreate.mockResolvedValue({
      content: [{ type: "text", text: "ok" }],
      stop_reason: "end_turn",
      usage: { input_tokens: 0, output_tokens: 0 },
    });

    // Act
    await client.complete(
      [{ role: "user", content: "test" }],
      {
        model: "claude-sonnet-4-6",
        tools: [{
          name: "Read",
          description: "Read a file",
          inputSchema: { type: "object", properties: { file_path: { type: "string" } } },
        }],
      },
    );

    // Assert
    const callArgs = mockCreate.mock.calls[0][0];
    expect(callArgs.tools).toEqual([{
      name: "Read",
      description: "Read a file",
      input_schema: { type: "object", properties: { file_path: { type: "string" } } },
    }]);
  });

  it("maps Anthropic tool_use blocks to our ToolCall format", async () => {
    // Arrange
    mockCreate.mockResolvedValue({
      content: [
        { type: "text", text: "Let me read that file." },
        { type: "tool_use", id: "toolu_123", name: "Read", input: { file_path: "/tmp/test.txt" } },
      ],
      stop_reason: "tool_use",
      usage: { input_tokens: 100, output_tokens: 50 },
    });

    // Act
    const result = await client.complete(
      [{ role: "user", content: "read the file" }],
      { model: "claude-sonnet-4-6" },
    );

    // Assert
    expect(result.toolCalls).toEqual([{
      id: "toolu_123",
      name: "Read",
      input: { file_path: "/tmp/test.txt" },
    }]);
    expect(result.content).toBe("Let me read that file.");
    expect(result.finishReason).toBe("tool_use");
  });

  it("maps tool result messages as user messages with tool_result blocks", async () => {
    // Arrange
    mockCreate.mockResolvedValue({
      content: [{ type: "text", text: "ok" }],
      stop_reason: "end_turn",
      usage: { input_tokens: 0, output_tokens: 0 },
    });

    const messages: Message[] = [
      { role: "user", content: "do something" },
      {
        role: "assistant",
        content: "Let me read.",
        toolCalls: [{ id: "toolu_1", name: "Read", input: { file_path: "/tmp/x" } }],
      },
      {
        role: "tool",
        content: "file contents",
        toolResult: { toolCallId: "toolu_1", content: "file contents" },
      },
    ];

    // Act
    await client.complete(messages, { model: "claude-sonnet-4-6" });

    // Assert
    const callArgs = mockCreate.mock.calls[0][0];

    // Assistant message should have tool_use content blocks
    const assistantMsg = callArgs.messages[1];
    expect(assistantMsg.role).toBe("assistant");
    expect(assistantMsg.content).toEqual([
      { type: "text", text: "Let me read." },
      { type: "tool_use", id: "toolu_1", name: "Read", input: { file_path: "/tmp/x" } },
    ]);

    // Tool result should be a user message with tool_result block
    const toolMsg = callArgs.messages[2];
    expect(toolMsg.role).toBe("user");
    expect(toolMsg.content).toEqual([{
      type: "tool_result",
      tool_use_id: "toolu_1",
      content: "file contents",
    }]);
  });

  it("passes system prompt via system parameter", async () => {
    // Arrange
    mockCreate.mockResolvedValue({
      content: [{ type: "text", text: "ok" }],
      stop_reason: "end_turn",
      usage: { input_tokens: 0, output_tokens: 0 },
    });

    // Act
    await client.complete(
      [{ role: "user", content: "test" }],
      { model: "claude-sonnet-4-6", system: "You are a coding assistant." },
    );

    // Assert
    const callArgs = mockCreate.mock.calls[0][0];
    expect(callArgs.system).toBe("You are a coding assistant.");
  });
});
