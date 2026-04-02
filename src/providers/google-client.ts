import {
  GoogleGenAI,
  type Content,
  type GenerateContentConfig,
  type GenerateContentParameters,
} from "@google/genai";
import type {
  LLMClient,
  Message,
  CompletionOptions,
  CompletionResponse,
  ToolCall,
} from "../core/llm-types.js";

let callIdCounter = 0;

function generateCallId(): string {
  return `fc_${++callIdCounter}_${Date.now()}`;
}

/**
 * LLMClient implementation for Google Gemini.
 *
 * Key differences from Anthropic/OpenAI:
 * - Tools use functionDeclarations
 * - Function calls may lack IDs (we generate them)
 * - Tool results use functionResponse
 * - Arguments are objects (not JSON strings like OpenAI)
 *
 * Note: Google's SDK does not export a `Part` type directly, so
 * response parts are narrowed via property checks rather than
 * type imports.
 */
export class GoogleLLMClient implements LLMClient {
  readonly name = "google";
  private readonly ai: GoogleGenAI;

  constructor(apiKey: string) {
    this.ai = new GoogleGenAI({ apiKey });
  }

  async complete(
    messages: Message[],
    options: CompletionOptions,
  ): Promise<CompletionResponse> {
    const contents = this.toContents(messages);

    const config: GenerateContentConfig = {};

    if (options.system) {
      config.systemInstruction = options.system;
    }

    if (options.tools && options.tools.length > 0) {
      config.tools = [{
        functionDeclarations: options.tools.map((tool) => ({
          name: tool.name,
          description: tool.description,
          parameters: tool.inputSchema,
        })),
      }];
    }

    if (options.maxTokens) {
      config.maxOutputTokens = options.maxTokens;
    }

    if (options.temperature !== undefined) {
      config.temperature = options.temperature;
    }

    const params: GenerateContentParameters = {
      model: options.model,
      contents,
      config,
    };

    const response = await this.ai.models.generateContent(params);

    const candidate = response.candidates?.[0];
    const parts = candidate?.content?.parts ?? [];
    const toolCalls = this.parseToolCalls(parts);

    return {
      content: response.text ?? "",
      toolCalls,
      usage: {
        inputTokens: response.usageMetadata?.promptTokenCount ?? 0,
        outputTokens: response.usageMetadata?.candidatesTokenCount ?? 0,
      },
      finishReason: candidate?.finishReason ?? "STOP",
    };
  }

  private toContents(messages: Message[]): Content[] {
    const contents: Content[] = [];

    for (const msg of messages) {
      if (msg.role === "system") continue;

      if (msg.role === "assistant" && msg.toolCalls && msg.toolCalls.length > 0) {
        contents.push({
          role: "model",
          parts: msg.toolCalls.map((tc) => ({
            functionCall: {
              id: tc.id,
              name: tc.name,
              args: tc.input,
            },
          })),
        });
      } else if (msg.role === "tool" && msg.toolResult) {
        contents.push({
          role: "user",
          parts: [{
            functionResponse: {
              id: msg.toolResult.toolCallId,
              name: msg.toolResult.toolCallId,
              response: { result: msg.toolResult.content },
            },
          }],
        });
      } else if (msg.role === "assistant") {
        contents.push({
          role: "model",
          parts: [{ text: msg.content }],
        });
      } else {
        contents.push({
          role: "user",
          parts: [{ text: msg.content }],
        });
      }
    }

    return contents;
  }

  private parseToolCalls(parts: unknown[]): ToolCall[] {
    const calls: ToolCall[] = [];

    for (const part of parts) {
      // Google SDK does not export Part or FunctionCallContent; narrow via property check.
      // The SDK type defines `arguments` but runtime responses may use `args`.
      const maybeFc = part as {
        functionCall?: {
          id?: string;
          name: string;
          arguments?: Record<string, unknown>;
          args?: Record<string, unknown>;
        };
      };
      if (!maybeFc.functionCall) continue;

      const fc = maybeFc.functionCall;
      calls.push({
        id: fc.id ?? generateCallId(),
        name: fc.name,
        input: fc.arguments ?? fc.args ?? {},
      });
    }

    return calls;
  }
}
