import { query, type Options as SDKOptions } from "@anthropic-ai/claude-agent-sdk";
import { buildAuthEnv } from "../environment/auth.js";
import {
  type PhaseName,
  getMaxTurns,
  getPhaseTools,
  type TurnOverrides,
} from "../config/phase-config.js";
import { buildPhasePrompt } from "../config/prompt-builder.js";

export interface ToolUseEvent {
  toolName: string;
  toolInput: Record<string, unknown>;
}

export interface PhaseHooks {
  onToolUse?: (event: ToolUseEvent) => void;
  onResult?: (result: PhaseResult) => void;
}

export interface PhaseOptions {
  model?: string;
  cwd?: string;
  skipPermissions?: boolean;
  trunkMode?: boolean;
  hasContextDir?: boolean;
  turnOverrides?: TurnOverrides;
  resumeSessionId?: string;
  maxBudgetUsd?: number;
  hooks?: PhaseHooks;
  authMode?: "oauth" | "apikey";
}

export interface PhaseResult {
  output: string;
  sessionId: string;
  inputTokens: number;
  outputTokens: number;
  costUsd: number;
  numTurns: number;
  exhausted: boolean;
}

/**
 * Execute a single PDLC phase via the Claude Agent SDK.
 *
 * Wraps query() with phase-specific configuration:
 * - Prompt built from phase + input (with optional trunk-mode prefix)
 * - Tool allowlist from phase config
 * - Turn budget from phase defaults or overrides
 * - CLAUDE.md loaded via settingSources: ["project"]
 * - Session resume for multi-phase continuity
 */
export async function runPhase(
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
    settingSources: ["project"],
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
        hooks: [async (input) => {
          const hookInput = input as { tool_name: string; tool_input: unknown };
          onToolUse({
            toolName: hookInput.tool_name,
            toolInput: (hookInput.tool_input ?? {}) as Record<string, unknown>,
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

  for await (const message of query({ prompt, options: queryOptions })) {
    const msg = message as Record<string, unknown>;

    // Capture session ID from init message
    if (msg.type === "system" && msg.subtype === "init") {
      sessionId = msg.session_id as string;
    }

    // Capture result from final SDKResultMessage
    if (msg.type === "result") {
      output = (msg.result as string) ?? "";
      exhausted = msg.subtype === "error_max_turns" || msg.subtype === "error_max_budget_usd";

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
