import { GoogleGenAI } from "@google/genai";
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
 * Maps between our unified types and Google's generateContent API.
 * Key differences from OpenAI:
 * - Tools use functionDeclarations (not function parameters)
 * - Function calls may lack IDs (we generate them)
 * - Tool results use functionResponse matched by name/call_id
 * - Arguments are objects (not JSON strings like OpenAI)
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
    const contents = this.toGoogleContents(messages);

    const config: Record<string, unknown> = {};

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

    const response = await this.ai.models.generateContent({
      model: options.model,
      contents,
      config,
    });

    const candidate = response.candidates?.[0];
    const parts = (candidate?.content?.parts ?? []) as Array<Record<string, unknown>>;
    const toolCalls = this.parseToolCalls(parts);
    const textContent = response.text ?? "";

    return {
      content: textContent,
      toolCalls,
      usage: {
        inputTokens: response.usageMetadata?.promptTokenCount ?? 0,
        outputTokens: response.usageMetadata?.candidatesTokenCount ?? 0,
      },
      finishReason: candidate?.finishReason ?? "STOP",
    };
  }

  private toGoogleContents(messages: Message[]): Array<Record<string, unknown>> {
    const contents: Array<Record<string, unknown>> = [];

    for (const msg of messages) {
      if (msg.role === "system") {
        // System messages handled via systemInstruction config
        continue;
      }

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
              name: msg.toolResult.toolCallId, // Google matches by name
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

  private parseToolCalls(parts: Array<Record<string, unknown>>): ToolCall[] {
    const calls: ToolCall[] = [];

    for (const part of parts) {
      const fc = part.functionCall as { id?: string; name: string; args: Record<string, unknown> } | undefined;
      if (!fc) continue;

      calls.push({
        id: fc.id ?? generateCallId(),
        name: fc.name,
        input: fc.args ?? {},
      });
    }

    return calls;
  }
}
