import { query, type Options as SDKOptions } from "@anthropic-ai/claude-agent-sdk";
import { buildAuthEnv } from "../environment/auth.js";
import {
  type PhaseName,
  getMaxTurns,
  getPhaseTools,
} from "../config/phase-config.js";
import { buildPhasePrompt } from "../config/prompt-builder.js";
import type { PhaseExecutor, PhaseOptions, PhaseResult } from "./phase-executor.js";

function formatVerboseMessage(msg: Record<string, unknown>): void {
  switch (msg.type) {
    case "assistant": {
      const message = msg.message as Record<string, unknown> | undefined;
      const content = message?.content as Array<Record<string, unknown>> | undefined;
      if (!Array.isArray(content)) return;
      for (const block of content) {
        if (block.type === "tool_use") {
          const name = block.name as string;
          const input = block.input as Record<string, unknown> | undefined;
          if (name === "Write" || name === "Edit") {
            console.error(`  ${name}: ${input?.file_path ?? "unknown"}`);
          } else if (name === "Bash") {
            const cmd = (input?.command as string ?? "").split("\n")[0].slice(0, 60);
            console.error(`  Bash: ${cmd}`);
          } else if (name === "Read") {
            console.error(`  Read: ${input?.file_path ?? "unknown"}`);
          } else {
            console.error(`  ${name}`);
          }
        }
      }
      break;
    }
    case "result": {
      const turns = msg.num_turns as number;
      const cost = msg.total_cost_usd as number;
      console.error(`  Done (${turns} turns, $${cost.toFixed(4)})`);
      break;
    }
    case "system":
      if (msg.subtype === "task_notification") {
        const title = (msg as Record<string, unknown>).title as string | undefined;
        if (title) console.error(`  ${title}`);
      }
      break;
  }
}

/** SDK result subtypes that indicate the phase was cut short. */
const EXHAUSTION_SUBTYPES = new Set(["error_max_turns", "error_max_budget_usd"]);

/**
 * Tier 1 PhaseExecutor: wraps @anthropic-ai/claude-agent-sdk query().
 *
 * Full fidelity: hooks, sessions, budget caps, permissions, MCP, subagents.
 */
export class ClaudeAgentExecutor implements PhaseExecutor {
  readonly name = "claude";
  readonly tier = 1 as const;

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
    const allowedTools = getPhaseTools(phase);

    const queryOptions: SDKOptions = {
      allowedTools,
      maxTurns,
      settingSources: ["user", "project"],
      systemPrompt: { type: "preset", preset: "claude_code" },
      model: options?.model,
      cwd: options?.cwd,
      resume: options?.resumeSessionId,
      maxBudgetUsd: options?.maxBudgetUsd,
    };

    if (options?.skipPermissions) {
      queryOptions.permissionMode = "bypassPermissions";
      queryOptions.allowDangerouslySkipPermissions = true;
    }

    const authEnv = buildAuthEnv(options?.authMode);
    if (authEnv) {
      queryOptions.env = authEnv;
    }

    if (options?.hooks?.onToolUse) {
      const onToolUse = options.hooks.onToolUse;
      queryOptions.hooks = {
        PostToolUse: [{
          hooks: [async (hookInput) => {
            const typed = hookInput as { tool_name: string; tool_input: unknown };
            onToolUse({
              toolName: typed.tool_name,
              toolInput: (typed.tool_input ?? {}) as Record<string, unknown>,
            });
            return {};
          }],
        }],
      };
    }

    let sessionId = "";
    let output = "";
    let inputTokens = 0;
    let outputTokens = 0;
    let costUsd = 0;
    let numTurns = 0;
    let exhausted = false;

    const verbose = options?.verbose ?? false;

    for await (const message of query({ prompt, options: queryOptions })) {
      const msg = message as Record<string, unknown>;

      if (verbose) {
        formatVerboseMessage(msg);
      }

      if (msg.type === "system" && msg.subtype === "init") {
        sessionId = msg.session_id as string;
      }

      if (msg.type === "result") {
        output = (msg.result as string) ?? "";
        exhausted = EXHAUSTION_SUBTYPES.has(msg.subtype as string);

        const usage = msg.usage as
          | { input_tokens: number; output_tokens: number }
          | undefined;
        if (usage) {
          inputTokens = usage.input_tokens;
          outputTokens = usage.output_tokens;
        }

        costUsd = (msg.total_cost_usd as number) ?? 0;
        numTurns = (msg.num_turns as number) ?? 0;
      }
    }

    const result: PhaseResult = {
      output,
      sessionId,
      inputTokens,
      outputTokens,
      costUsd,
      numTurns,
      exhausted,
    };

    options?.hooks?.onResult?.(result);

    return result;
  }
}
