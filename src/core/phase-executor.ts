import { query } from "@anthropic-ai/claude-agent-sdk";
import {
  type PhaseName,
  getMaxTurns,
  getPhaseTools,
  type TurnOverrides,
} from "../config/phase-config.js";
import { buildPhasePrompt } from "../config/prompt-builder.js";

export interface PhaseOptions {
  model?: string;
  cwd?: string;
  skipPermissions?: boolean;
  trunkMode?: boolean;
  hasContextDir?: boolean;
  turnOverrides?: TurnOverrides;
  resumeSessionId?: string;
  maxBudgetUsd?: number;
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

  const queryOptions: Record<string, unknown> = {
    allowedTools,
    maxTurns,
    settingSources: ["project"],
    systemPrompt: { type: "preset", preset: "claude_code" },
  };

  if (options?.model) {
    queryOptions.model = options.model;
  }

  if (options?.cwd) {
    queryOptions.cwd = options.cwd;
  }

  if (options?.skipPermissions) {
    queryOptions.permissionMode = "bypassPermissions";
    queryOptions.allowDangerouslySkipPermissions = true;
  }

  if (options?.resumeSessionId) {
    queryOptions.resume = options.resumeSessionId;
  }

  if (options?.maxBudgetUsd !== undefined) {
    queryOptions.maxBudgetUsd = options.maxBudgetUsd;
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

    // Capture result from final message
    if ("result" in msg) {
      output = msg.result as string;
      exhausted = msg.stop_reason === "max_tokens";

      const usage = msg.usage as
        | { input_tokens: number; output_tokens: number }
        | undefined;
      if (usage) {
        inputTokens = usage.input_tokens;
        outputTokens = usage.output_tokens;
      }

      costUsd = (msg.cost_usd as number) ?? 0;
      numTurns = (msg.num_turns as number) ?? 0;
    }
  }

  return {
    output,
    sessionId,
    inputTokens,
    outputTokens,
    costUsd,
    numTurns,
    exhausted,
  };
}
