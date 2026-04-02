import { readFileSync, existsSync } from "node:fs";
import { join } from "node:path";
import type { PhaseName } from "../config/phase-config.js";
import { getMaxTurns } from "../config/phase-config.js";
import { buildPhasePrompt } from "../config/prompt-builder.js";
import type { PhaseExecutor, PhaseOptions, PhaseResult } from "./phase-executor.js";
import type { LLMClient, Message, ToolExecutor, ToolResult, CompletionOptions } from "./llm-types.js";

/**
 * Tier 2 PhaseExecutor: self-managed agent loop over any LLMClient.
 *
 * Sends prompts to the LLM, receives tool call requests, executes them
 * locally via ToolExecutor, and feeds results back. Continues until the
 * LLM produces a final response or limits are reached.
 *
 * Supports: tool use, turn limits, onToolUse hooks, onResult hooks, verbose.
 * Does NOT support: session resume, MCP servers, subagents (Tier 1 only).
 */
export class LLMApiExecutor implements PhaseExecutor {
  readonly name = "llm-api";
  readonly tier = 2 as const;

  constructor(
    private readonly client: LLMClient,
    private readonly toolExecutor: ToolExecutor,
  ) {}

  async runPhase(
    phase: PhaseName,
    input: string,
    options?: PhaseOptions,
  ): Promise<PhaseResult> {
    const prompt = buildPhasePrompt(phase, input, {
      trunkMode: options?.trunkMode,
      hasContextDir: options?.hasContextDir,
    });

    const maxTurns = getMaxTurns(phase, options?.turnOverrides);
    const verbose = options?.verbose ?? false;

    const projectContext = this.loadProjectContext(options?.cwd ?? process.cwd());
    const systemParts = [
      projectContext,
      `You are a genie-team ${phase} specialist.`,
    ].filter(Boolean);

    const tools = this.toolExecutor.availableTools();
    const completionOpts: CompletionOptions = {
      model: options?.model ?? "default",
      system: systemParts.join("\n\n"),
      tools,
    };

    const messages: Message[] = [{ role: "user", content: prompt }];
    let turns = 0;
    let totalInputTokens = 0;
    let totalOutputTokens = 0;
    let lastContent = "";
    let exhausted = false;

    while (turns < maxTurns) {
      const response = await this.client.complete(messages, completionOpts);
      turns++;
      totalInputTokens += response.usage.inputTokens;
      totalOutputTokens += response.usage.outputTokens;

      if (verbose) {
        if (response.toolCalls.length > 0) {
          for (const call of response.toolCalls) {
            console.error(`  ${call.name}: ${JSON.stringify(call.input).slice(0, 80)}`);
          }
        }
      }

      // No tool calls — LLM is done
      if (response.toolCalls.length === 0) {
        lastContent = response.content;
        break;
      }

      // Execute tool calls
      messages.push({
        role: "assistant",
        content: response.content,
        toolCalls: response.toolCalls,
      });

      for (const call of response.toolCalls) {
        options?.hooks?.onToolUse?.({
          toolName: call.name,
          toolInput: call.input,
        });

        const toolOutput = await this.toolExecutor.execute(call.name, call.input);

        const toolResult: ToolResult = {
          toolCallId: call.id,
          content: toolOutput,
        };

        messages.push({
          role: "tool",
          content: toolOutput,
          toolResult,
        });
      }

      // Check if we've hit the turn limit
      if (turns >= maxTurns) {
        lastContent = response.content || "Turn limit reached.";
        exhausted = true;
      }
    }

    if (verbose) {
      console.error(`  Done (${turns} turns)`);
    }

    const result: PhaseResult = {
      output: lastContent,
      sessionId: "",
      inputTokens: totalInputTokens,
      outputTokens: totalOutputTokens,
      costUsd: 0, // Tier 2 doesn't track cost directly — caller computes from tokens
      numTurns: turns,
      exhausted,
    };

    options?.hooks?.onResult?.(result);

    return result;
  }

  private loadProjectContext(cwd: string): string {
    const parts: string[] = [];

    // Load CLAUDE.md (primary project context)
    const claudeMd = join(cwd, "CLAUDE.md");
    if (existsSync(claudeMd)) {
      try {
        parts.push(readFileSync(claudeMd, "utf-8"));
      } catch { /* skip unreadable */ }
    }

    // Load strategic context files
    const contextDir = join(cwd, "docs", "context");
    if (existsSync(contextDir)) {
      for (const file of ["strategy.md", "market.md", "assumptions.md"]) {
        const filePath = join(contextDir, file);
        if (existsSync(filePath)) {
          try {
            parts.push(readFileSync(filePath, "utf-8"));
          } catch { /* skip unreadable */ }
        }
      }
    }

    return parts.join("\n\n");
  }
}
