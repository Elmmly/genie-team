import Anthropic from "@anthropic-ai/sdk";
import type {
  LLMClient,
  Message,
  CompletionOptions,
  CompletionResponse,
  ToolCall,
} from "../core/llm-types.js";

/**
 * LLMClient implementation for Anthropic (Claude models via raw API).
 *
 * This is the Tier 2 path for Claude — uses the Messages API directly
 * instead of the Claude Agent SDK. Useful when Claude Code is not
 * installed or for API-key-only environments.
 *
 * Key Anthropic differences:
 * - Tool results are sent as user messages with tool_result content blocks
 * - Assistant messages with tool calls have mixed text + tool_use content
 * - System prompt is a top-level parameter, not a message
 */
export class AnthropicLLMClient implements LLMClient {
  readonly name = "anthropic";
  private readonly client: Anthropic;

  constructor(apiKey: string) {
    this.client = new Anthropic({ apiKey });
  }

  async complete(
    messages: Message[],
    options: CompletionOptions,
  ): Promise<CompletionResponse> {
    const anthropicMessages = this.toAnthropicMessages(messages);

    const request: Record<string, unknown> = {
      model: options.model,
      messages: anthropicMessages,
      max_tokens: options.maxTokens ?? 4096,
    };

    if (options.system) {
      request.system = options.system;
    }

    if (options.tools && options.tools.length > 0) {
      request.tools = options.tools.map((tool) => ({
        name: tool.name,
        description: tool.description,
        input_schema: tool.inputSchema,
      }));
    }

    if (options.temperature !== undefined) {
      request.temperature = options.temperature;
    }

    const response = await this.client.messages.create(
      request as unknown as Anthropic.MessageCreateParamsNonStreaming,
    );

    const { text, toolCalls } = this.parseContent(response.content as unknown as Array<Record<string, unknown>>);

    return {
      content: text,
      toolCalls,
      usage: {
        inputTokens: response.usage?.input_tokens ?? 0,
        outputTokens: response.usage?.output_tokens ?? 0,
      },
      finishReason: response.stop_reason ?? "end_turn",
    };
  }

  private toAnthropicMessages(messages: Message[]): Array<Record<string, unknown>> {
    const result: Array<Record<string, unknown>> = [];

    for (const msg of messages) {
      if (msg.role === "system") continue; // Handled via system parameter

      if (msg.role === "assistant" && msg.toolCalls && msg.toolCalls.length > 0) {
        const content: Array<Record<string, unknown>> = [];
        if (msg.content) {
          content.push({ type: "text", text: msg.content });
        }
        for (const tc of msg.toolCalls) {
          content.push({
            type: "tool_use",
            id: tc.id,
            name: tc.name,
            input: tc.input,
          });
        }
        result.push({ role: "assistant", content });
      } else if (msg.role === "tool" && msg.toolResult) {
        // Anthropic: tool results are user messages with tool_result blocks
        result.push({
          role: "user",
          content: [{
            type: "tool_result",
            tool_use_id: msg.toolResult.toolCallId,
            content: msg.toolResult.content,
          }],
        });
      } else {
        result.push({
          role: msg.role === "tool" ? "user" : msg.role,
          content: msg.content,
        });
      }
    }

    return result;
  }

  private parseContent(
    content: Array<Record<string, unknown>>,
  ): { text: string; toolCalls: ToolCall[] } {
    let text = "";
    const toolCalls: ToolCall[] = [];

    for (const block of content) {
      if (block.type === "text") {
        text += block.text as string;
      } else if (block.type === "tool_use") {
        toolCalls.push({
          id: block.id as string,
          name: block.name as string,
          input: (block.input ?? {}) as Record<string, unknown>,
        });
      }
    }

    return { text, toolCalls };
  }
}
