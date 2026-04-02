import { executeBatch, type BatchOptions } from "./batch-executor.js";
import { resolveItems, type ResolveOptions } from "./item-resolver.js";
import type { ExecutionOptions } from "./single-item.js";
import type { PhaseExecutor } from "../core/phase-executor.js";
import type { PhaseName } from "../config/phase-config.js";
import type { FinishMode } from "../git/worktree.js";

export interface DaemonOptions extends ExecutionOptions {
  throughPhase: PhaseName;
  finishMode: FinishMode;
  parallel?: number;
  priorities?: string[];
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
  executor: PhaseExecutor,
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

  const { priorities: _, ...rest } = options;
  const batchOpts: BatchOptions = {
    ...rest,
    continueOnFailure: true, // daemon always continues
  };

  const result = await executeBatch(executor, items, batchOpts);

  return {
    itemsCompleted: result.succeeded.length,
    itemsFailed: result.failed.length + result.conflicts.length,
    costUsd: result.totalCostUsd,
    exitCode: result.exitCode,
  };
}
