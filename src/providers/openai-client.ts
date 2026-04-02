import OpenAI from "openai";
import type {
  LLMClient,
  Message,
  CompletionOptions,
  CompletionResponse,
  ToolCall,
} from "../core/llm-types.js";

/**
 * LLMClient implementation for OpenAI (GPT-4o, o3, etc.).
 *
 * Maps between our unified types and OpenAI's chat completion API.
 * Used by LLMApiExecutor for Tier 2 multi-provider execution.
 */
export class OpenAILLMClient implements LLMClient {
  readonly name = "openai";
  private readonly openai: OpenAI;

  constructor(apiKey: string) {
    this.openai = new OpenAI({ apiKey });
  }

  async complete(
    messages: Message[],
    options: CompletionOptions,
  ): Promise<CompletionResponse> {
    const openaiMessages = this.toOpenAIMessages(messages, options.system);

    const request: Record<string, unknown> = {
      model: options.model,
      messages: openaiMessages,
    };

    if (options.tools && options.tools.length > 0) {
      request.tools = options.tools.map((tool) => ({
        type: "function" as const,
        function: {
          name: tool.name,
          description: tool.description,
          parameters: tool.inputSchema,
        },
      }));
    }

    if (options.maxTokens) {
      request.max_tokens = options.maxTokens;
    }

    if (options.temperature !== undefined) {
      request.temperature = options.temperature;
    }

    const response = await this.openai.chat.completions.create(request as unknown as OpenAI.ChatCompletionCreateParamsNonStreaming);

    const choice = response.choices[0];
    const toolCalls = this.parseToolCalls(choice?.message?.tool_calls as unknown as Array<{ id: string; type: string; function: { name: string; arguments: string } }> | undefined);

    return {
      content: choice?.message?.content ?? "",
      toolCalls,
      usage: {
        inputTokens: response.usage?.prompt_tokens ?? 0,
        outputTokens: response.usage?.completion_tokens ?? 0,
      },
      finishReason: choice?.finish_reason ?? "stop",
    };
  }

  private toOpenAIMessages(
    messages: Message[],
    system?: string,
  ): Array<Record<string, unknown>> {
    const result: Array<Record<string, unknown>> = [];

    if (system) {
      result.push({ role: "system", content: system });
    }

    for (const msg of messages) {
      if (msg.role === "assistant" && msg.toolCalls && msg.toolCalls.length > 0) {
        result.push({
          role: "assistant",
          content: msg.content || null,
          tool_calls: msg.toolCalls.map((tc) => ({
            id: tc.id,
            type: "function" as const,
            function: {
              name: tc.name,
              arguments: JSON.stringify(tc.input),
            },
          })),
        });
      } else if (msg.role === "tool" && msg.toolResult) {
        result.push({
          role: "tool",
          tool_call_id: msg.toolResult.toolCallId,
          content: msg.toolResult.content,
        });
      } else {
        result.push({
          role: msg.role,
          content: msg.content,
        });
      }
    }

    return result;
  }

  private parseToolCalls(
    toolCalls?: Array<{ id: string; type: string; function: { name: string; arguments: string } }>,
  ): ToolCall[] {
    if (!toolCalls) return [];

    return toolCalls.map((tc) => ({
      id: tc.id,
      name: tc.function.name,
      input: JSON.parse(tc.function.arguments),
    }));
  }
}
