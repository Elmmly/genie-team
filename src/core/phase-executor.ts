import type { PhaseName, TurnOverrides } from "../config/phase-config.js";

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
  verbose?: boolean;
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
 * Abstraction over AI provider agent execution.
 *
 * Tier 1 implementations wrap an embeddable agent SDK (e.g., Claude Agent SDK).
 * Tier 2 implementations use an LLM API SDK with a self-managed agent loop.
 *
 * All implementations accept the same PhaseOptions and return PhaseResult,
 * though Tier 2 may not support all options (e.g., sessions, MCP).
 */
export interface PhaseExecutor {
  readonly name: string;
  readonly tier: 1 | 2;
  runPhase(phase: PhaseName, input: string, options?: PhaseOptions): Promise<PhaseResult>;
}
