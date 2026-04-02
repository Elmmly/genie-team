import { describe, it, expect, vi, beforeEach } from "vitest";
import { GoogleLLMClient } from "./google-client.js";
import type { Message } from "../core/llm-types.js";

// Mock the @google/genai package
vi.mock("@google/genai", () => {
  const mockGenerateContent = vi.fn();
  return {
    GoogleGenAI: class {
      models = { generateContent: mockGenerateContent };
    },
    __mockGenerateContent: mockGenerateContent,
  };
});

// eslint-disable-next-line @typescript-eslint/no-explicit-any
const { __mockGenerateContent } = await import("@google/genai") as any;
const mockGenerate = __mockGenerateContent as ReturnType<typeof vi.fn>;

describe("GoogleLLMClient", () => {
  let client: GoogleLLMClient;

  beforeEach(() => {
    vi.resetAllMocks();
    client = new GoogleLLMClient("test-key");
  });

  it("has name 'google'", () => {
    expect(client.name).toBe("google");
  });

  it("returns completion response from text content", async () => {
    // Arrange
    mockGenerate.mockResolvedValue({
      text: "Hello from Gemini",
      candidates: [{ content: { parts: [{ text: "Hello from Gemini" }] }, finishReason: "STOP" }],
      usageMetadata: { promptTokenCount: 100, candidatesTokenCount: 50 },
    });

    // Act
    const result = await client.complete(
      [{ role: "user", content: "Hello" }],
      { model: "gemini-2.0-flash" },
    );

    // Assert
    expect(result.content).toBe("Hello from Gemini");
    expect(result.toolCalls).toEqual([]);
    expect(result.usage.inputTokens).toBe(100);
    expect(result.usage.outputTokens).toBe(50);
  });

  it("maps tool definitions to Google function declarations", async () => {
    // Arrange
    mockGenerate.mockResolvedValue({
      text: "ok",
      candidates: [{ content: { parts: [{ text: "ok" }] }, finishReason: "STOP" }],
      usageMetadata: { promptTokenCount: 0, candidatesTokenCount: 0 },
    });

    // Act
    await client.complete(
      [{ role: "user", content: "test" }],
      {
        model: "gemini-2.0-flash",
        tools: [{
          name: "Read",
          description: "Read a file",
          inputSchema: { type: "object", properties: { file_path: { type: "string" } } },
        }],
      },
    );

    // Assert
    const callArgs = mockGenerate.mock.calls[0][0];
    expect(callArgs.config.tools).toEqual([{
      functionDeclarations: [{
        name: "Read",
        description: "Read a file",
        parameters: { type: "object", properties: { file_path: { type: "string" } } },
      }],
    }]);
  });

  it("maps Google function_call parts to our ToolCall format", async () => {
    // Arrange
    mockGenerate.mockResolvedValue({
      text: undefined,
      candidates: [{
        content: {
          parts: [{
            functionCall: {
              id: "fc_123",
              name: "Read",
              args: { file_path: "/tmp/test.txt" },
            },
          }],
        },
        finishReason: "STOP",
      }],
      usageMetadata: { promptTokenCount: 100, candidatesTokenCount: 50 },
    });

    // Act
    const result = await client.complete(
      [{ role: "user", content: "read the file" }],
      { model: "gemini-2.0-flash" },
    );

    // Assert
    expect(result.toolCalls).toEqual([{
      id: "fc_123",
      name: "Read",
      input: { file_path: "/tmp/test.txt" },
    }]);
  });

  it("generates IDs for function calls without them", async () => {
    // Arrange
    mockGenerate.mockResolvedValue({
      text: undefined,
      candidates: [{
        content: {
          parts: [{
            functionCall: {
              name: "Write",
              args: { file_path: "/tmp/out.txt" },
            },
          }],
        },
        finishReason: "STOP",
      }],
      usageMetadata: { promptTokenCount: 0, candidatesTokenCount: 0 },
    });

    // Act
    const result = await client.complete(
      [{ role: "user", content: "write" }],
      { model: "gemini-2.0-flash" },
    );

    // Assert
    expect(result.toolCalls[0].id).toBeTruthy();
    expect(result.toolCalls[0].name).toBe("Write");
  });

  it("maps tool result messages correctly", async () => {
    // Arrange
    mockGenerate.mockResolvedValue({
      text: "ok",
      candidates: [{ content: { parts: [{ text: "ok" }] }, finishReason: "STOP" }],
      usageMetadata: { promptTokenCount: 0, candidatesTokenCount: 0 },
    });

    const messages: Message[] = [
      { role: "user", content: "do something" },
      {
        role: "assistant",
        content: "",
        toolCalls: [{ id: "tc1", name: "Read", input: { file_path: "/tmp/x" } }],
      },
      {
        role: "tool",
        content: "file contents",
        toolResult: { toolCallId: "tc1", content: "file contents" },
      },
    ];

    // Act
    await client.complete(messages, { model: "gemini-2.0-flash" });

    // Assert
    const callArgs = mockGenerate.mock.calls[0][0];
    const contents = callArgs.contents;

    // Tool result should use functionResponse format
    const toolMsg = contents.find((c: Record<string, unknown>) =>
      Array.isArray(c.parts) && c.parts.some((p: Record<string, unknown>) => p.functionResponse),
    );
    expect(toolMsg).toBeDefined();
  });
});
