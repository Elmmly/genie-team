/**
 * Unified LLM types for multi-provider support.
 *
 * Inspired by Cataliva's pkg/llm/provider.go. These types abstract
 * across Anthropic, OpenAI, and Google LLM API SDKs. Each provider
 * adapter maps to/from these types.
 */

/** Role of a message sender in the conversation. */
export type Role = "user" | "assistant" | "system" | "tool";

/** A conversation message. */
export interface Message {
  role: Role;
  content: string;
  toolCalls?: ToolCall[];
  toolResult?: ToolResult;
}

/** A tool the LLM can call. */
export interface Tool {
  name: string;
  description: string;
  inputSchema: Record<string, unknown>;
}

/** The LLM requesting a tool invocation. */
export interface ToolCall {
  id: string;
  name: string;
  input: Record<string, unknown>;
}

/** The result of executing a tool. */
export interface ToolResult {
  toolCallId: string;
  content: string;
  isError?: boolean;
}

/** Token consumption for a completion. */
export interface TokenUsage {
  inputTokens: number;
  outputTokens: number;
}

/** Response from an LLM completion. */
export interface CompletionResponse {
  content: string;
  toolCalls: ToolCall[];
  usage: TokenUsage;
  finishReason: string;
}

/** Options for a completion request. */
export interface CompletionOptions {
  model: string;
  system?: string;
  tools?: Tool[];
  maxTokens?: number;
  temperature?: number;
}

/**
 * Unified LLM client interface.
 *
 * One implementation per provider (Anthropic, OpenAI, Google).
 * Each adapter maps between these types and the provider's SDK types.
 */
export interface LLMClient {
  /** Provider identifier (e.g., "anthropic", "openai", "google"). */
  readonly name: string;

  /** Send a completion request and return the full response. */
  complete(
    messages: Message[],
    options: CompletionOptions,
  ): Promise<CompletionResponse>;
}

/**
 * Interface for executing tools locally.
 *
 * Used by LLMApiExecutor (Tier 2) to handle tool calls from the LLM.
 * The executor receives the tool name and input, runs the operation,
 * and returns the result as a string.
 */
export interface ToolExecutor {
  /** Execute a tool and return the result. */
  execute(name: string, input: Record<string, unknown>): Promise<string>;

  /** List available tool definitions for the LLM. */
  availableTools(): Tool[];
}
