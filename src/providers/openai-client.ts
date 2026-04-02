import OpenAI from "openai";
import type {
  ChatCompletionMessageParam,
  ChatCompletionCreateParamsNonStreaming,
  ChatCompletionTool,
  ChatCompletionMessageFunctionToolCall,
} from "openai/resources/chat/completions/completions.js";
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
    const params: ChatCompletionCreateParamsNonStreaming = {
      model: options.model,
      messages: this.toMessageParams(messages, options.system),
    };

    if (options.tools && options.tools.length > 0) {
      params.tools = options.tools.map((tool): ChatCompletionTool => ({
        type: "function",
        function: {
          name: tool.name,
          description: tool.description,
          parameters: tool.inputSchema,
        },
      }));
    }

    if (options.maxTokens) {
      params.max_tokens = options.maxTokens;
    }

    if (options.temperature !== undefined) {
      params.temperature = options.temperature;
    }

    const response = await this.openai.chat.completions.create(params);

    const choice = response.choices[0];
    const functionCalls = (choice?.message?.tool_calls ?? [])
      .filter((tc): tc is ChatCompletionMessageFunctionToolCall => tc.type === "function");
    const toolCalls = this.parseToolCalls(functionCalls);

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

  private toMessageParams(
    messages: Message[],
    system?: string,
  ): ChatCompletionMessageParam[] {
    const result: ChatCompletionMessageParam[] = [];

    if (system) {
      result.push({ role: "system", content: system });
    }

    for (const msg of messages) {
      if (msg.role === "assistant" && msg.toolCalls && msg.toolCalls.length > 0) {
        result.push({
          role: "assistant",
          content: msg.content || null,
          tool_calls: msg.toolCalls.map((tc): ChatCompletionMessageFunctionToolCall => ({
            id: tc.id,
            type: "function",
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
          role: msg.role as "user" | "assistant",
          content: msg.content,
        });
      }
    }

    return result;
  }

  private parseToolCalls(
    toolCalls?: ChatCompletionMessageFunctionToolCall[],
  ): ToolCall[] {
    if (!toolCalls) return [];

    return toolCalls.map((tc) => ({
      id: tc.id,
      name: tc.function.name,
      input: JSON.parse(tc.function.arguments),
    }));
  }
}
