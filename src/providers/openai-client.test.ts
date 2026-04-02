import { describe, it, expect, vi, beforeEach } from "vitest";
import { OpenAILLMClient } from "./openai-client.js";
import type { CompletionOptions, Message } from "../core/llm-types.js";

// Mock the openai package
vi.mock("openai", () => {
  return {
    default: class {
      chat = {
        completions: {
          create: vi.fn(),
        },
      };
    },
  };
});

describe("OpenAILLMClient", () => {
  let client: OpenAILLMClient;

  beforeEach(() => {
    vi.resetAllMocks();
    client = new OpenAILLMClient("test-key");
  });

  it("has name 'openai'", () => {
    expect(client.name).toBe("openai");
  });

  it("maps messages and returns completion response", async () => {
    // Arrange
    const mockCreate = vi.fn().mockResolvedValue({
      choices: [{
        message: {
          content: "Hello from GPT",
          tool_calls: undefined,
        },
        finish_reason: "stop",
      }],
      usage: {
        prompt_tokens: 100,
        completion_tokens: 50,
      },
    });
    (client as any).openai.chat.completions.create = mockCreate;

    const messages: Message[] = [
      { role: "user", content: "Hello" },
    ];

    // Act
    const result = await client.complete(messages, {
      model: "gpt-4o",
    });

    // Assert
    expect(result.content).toBe("Hello from GPT");
    expect(result.toolCalls).toEqual([]);
    expect(result.usage.inputTokens).toBe(100);
    expect(result.usage.outputTokens).toBe(50);
    expect(result.finishReason).toBe("stop");
  });

  it("maps tool definitions to OpenAI function format", async () => {
    // Arrange
    const mockCreate = vi.fn().mockResolvedValue({
      choices: [{ message: { content: "ok", tool_calls: undefined }, finish_reason: "stop" }],
      usage: { prompt_tokens: 0, completion_tokens: 0 },
    });
    (client as any).openai.chat.completions.create = mockCreate;

    // Act
    await client.complete(
      [{ role: "user", content: "test" }],
      {
        model: "gpt-4o",
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
      type: "function",
      function: {
        name: "Read",
        description: "Read a file",
        parameters: { type: "object", properties: { file_path: { type: "string" } } },
      },
    }]);
  });

  it("maps OpenAI tool_calls to our ToolCall format", async () => {
    // Arrange
    const mockCreate = vi.fn().mockResolvedValue({
      choices: [{
        message: {
          content: null,
          tool_calls: [{
            id: "call_abc123",
            type: "function",
            function: {
              name: "Read",
              arguments: '{"file_path":"/tmp/test.txt"}',
            },
          }],
        },
        finish_reason: "tool_calls",
      }],
      usage: { prompt_tokens: 100, completion_tokens: 50 },
    });
    (client as any).openai.chat.completions.create = mockCreate;

    // Act
    const result = await client.complete(
      [{ role: "user", content: "read the file" }],
      { model: "gpt-4o" },
    );

    // Assert
    expect(result.toolCalls).toEqual([{
      id: "call_abc123",
      name: "Read",
      input: { file_path: "/tmp/test.txt" },
    }]);
    expect(result.finishReason).toBe("tool_calls");
  });

  it("maps assistant messages with tool calls correctly", async () => {
    // Arrange
    const mockCreate = vi.fn().mockResolvedValue({
      choices: [{ message: { content: "ok" }, finish_reason: "stop" }],
      usage: { prompt_tokens: 0, completion_tokens: 0 },
    });
    (client as any).openai.chat.completions.create = mockCreate;

    const messages: Message[] = [
      { role: "user", content: "do something" },
      {
        role: "assistant",
        content: "",
        toolCalls: [{ id: "tc1", name: "Read", input: { file_path: "/tmp/x" } }],
      },
      {
        role: "tool",
        content: "file contents here",
        toolResult: { toolCallId: "tc1", content: "file contents here" },
      },
    ];

    // Act
    await client.complete(messages, { model: "gpt-4o" });

    // Assert
    const callArgs = mockCreate.mock.calls[0][0];
    const assistantMsg = callArgs.messages[1];
    expect(assistantMsg.role).toBe("assistant");
    expect(assistantMsg.tool_calls).toEqual([{
      id: "tc1",
      type: "function",
      function: { name: "Read", arguments: '{"file_path":"/tmp/x"}' },
    }]);

    const toolMsg = callArgs.messages[2];
    expect(toolMsg.role).toBe("tool");
    expect(toolMsg.tool_call_id).toBe("tc1");
    expect(toolMsg.content).toBe("file contents here");
  });

  it("passes system prompt when provided", async () => {
    // Arrange
    const mockCreate = vi.fn().mockResolvedValue({
      choices: [{ message: { content: "ok" }, finish_reason: "stop" }],
      usage: { prompt_tokens: 0, completion_tokens: 0 },
    });
    (client as any).openai.chat.completions.create = mockCreate;

    // Act
    await client.complete(
      [{ role: "user", content: "test" }],
      { model: "gpt-4o", system: "You are a coding assistant." },
    );

    // Assert
    const callArgs = mockCreate.mock.calls[0][0];
    expect(callArgs.messages[0]).toEqual({
      role: "system",
      content: "You are a coding assistant.",
    });
  });
});
