import { executeBatch, type BatchOptions, type BatchResult } from "./batch-executor.js";
import { resolveItems, type ResolveOptions } from "./item-resolver.js";
import type { PhaseName } from "../config/phase-config.js";
import type { FinishMode } from "../git/worktree.js";

export interface DaemonOptions {
  throughPhase: PhaseName;
  finishMode: FinishMode;
  parallel?: number;
  priorities?: string[];
  trunkMode?: boolean;
  model?: string;
  skipPermissions?: boolean;
  maxBudgetUsd?: number;
  logDir?: string;
  cwd?: string;
  authMode?: "oauth" | "apikey";
}

export interface DaemonCycleResult {
  itemsCompleted: number;
  itemsFailed: number;
  costUsd: number;
  exitCode: number;
}

/**
 * Run one daemon cycle: resolve items → execute batch → return summary.
 *
 * The daemon loop (interval, max-cycles, cost caps) is handled by
 * the caller — this function is a single cycle.
 */
export async function runDaemonCycle(
  options: DaemonOptions,
): Promise<DaemonCycleResult> {
  const projectRoot = options.cwd ?? process.cwd();

  const resolveOpts: ResolveOptions = {};
  if (options.priorities) {
    resolveOpts.priorities = options.priorities;
  }

  const items = await resolveItems(projectRoot, resolveOpts);

  if (items.length === 0) {
    return { itemsCompleted: 0, itemsFailed: 0, costUsd: 0, exitCode: 0 };
  }

  const batchOpts: BatchOptions = {
    throughPhase: options.throughPhase,
    finishMode: options.finishMode,
    parallel: options.parallel,
    trunkMode: options.trunkMode,
    model: options.model,
    skipPermissions: options.skipPermissions,
    maxBudgetUsd: options.maxBudgetUsd,
    logDir: options.logDir,
    authMode: options.authMode,
    continueOnFailure: true, // daemon always continues
  };

  const result = await executeBatch(items, batchOpts);

  return {
    itemsCompleted: result.succeeded.length,
    itemsFailed: result.failed.length + result.conflicts.length,
    costUsd: result.totalCostUsd,
    exitCode: result.exitCode,
  };
}
