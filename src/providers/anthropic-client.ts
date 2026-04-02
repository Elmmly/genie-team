import Anthropic from "@anthropic-ai/sdk";
import type {
  MessageParam,
  ContentBlockParam,
  TextBlockParam,
  ToolUseBlockParam,
  ToolResultBlockParam,
  ContentBlock,
  TextBlock,
  ToolUseBlock,
  Tool as AnthropicTool,
  MessageCreateParamsNonStreaming,
} from "@anthropic-ai/sdk/resources/messages/messages.js";
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
 * Tier 2 path for Claude — uses the Messages API directly instead of
 * the Claude Agent SDK. Useful when Claude Code is not installed.
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
    const params: MessageCreateParamsNonStreaming = {
      model: options.model,
      messages: this.toMessageParams(messages),
      max_tokens: options.maxTokens ?? 4096,
    };

    if (options.system) {
      params.system = options.system;
    }

    if (options.tools && options.tools.length > 0) {
      params.tools = options.tools.map((tool): AnthropicTool => ({
        name: tool.name,
        description: tool.description,
        input_schema: tool.inputSchema as AnthropicTool["input_schema"],
      }));
    }

    if (options.temperature !== undefined) {
      params.temperature = options.temperature;
    }

    const response = await this.client.messages.create(params);

    const { text, toolCalls } = this.parseContentBlocks(response.content);

    return {
      content: text,
      toolCalls,
      usage: {
        inputTokens: response.usage.input_tokens,
        outputTokens: response.usage.output_tokens,
      },
      finishReason: response.stop_reason ?? "end_turn",
    };
  }

  private toMessageParams(messages: Message[]): MessageParam[] {
    const result: MessageParam[] = [];

    for (const msg of messages) {
      if (msg.role === "system") continue;

      if (msg.role === "assistant" && msg.toolCalls && msg.toolCalls.length > 0) {
        const content: ContentBlockParam[] = [];
        if (msg.content) {
          content.push({ type: "text", text: msg.content } satisfies TextBlockParam);
        }
        for (const tc of msg.toolCalls) {
          content.push({
            type: "tool_use",
            id: tc.id,
            name: tc.name,
            input: tc.input,
          } satisfies ToolUseBlockParam);
        }
        result.push({ role: "assistant", content });
      } else if (msg.role === "tool" && msg.toolResult) {
        result.push({
          role: "user",
          content: [{
            type: "tool_result",
            tool_use_id: msg.toolResult.toolCallId,
            content: msg.toolResult.content,
          } satisfies ToolResultBlockParam],
        });
      } else {
        const role = msg.role === "tool" ? "user" : msg.role;
        result.push({ role: role as "user" | "assistant", content: msg.content });
      }
    }

    return result;
  }

  private parseContentBlocks(blocks: ContentBlock[]): { text: string; toolCalls: ToolCall[] } {
    let text = "";
    const toolCalls: ToolCall[] = [];

    for (const block of blocks) {
      if (block.type === "text") {
        text += (block as TextBlock).text;
      } else if (block.type === "tool_use") {
        const toolBlock = block as ToolUseBlock;
        toolCalls.push({
          id: toolBlock.id,
          name: toolBlock.name,
          input: (toolBlock.input ?? {}) as Record<string, unknown>,
        });
      }
    }

    return { text, toolCalls };
  }
}
