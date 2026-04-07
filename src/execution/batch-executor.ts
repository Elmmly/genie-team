import pLimit from "p-limit";
import { executeSingleItem, type ExecutionOptions } from "./single-item.js";
import {
  sessionStart,
  sessionCleanup,
  integratePr,
  integrateTrunk,
  type FinishMode,
} from "../git/worktree.js";
import type { PhaseName } from "../config/phase-config.js";

export interface BatchItem {
  slug: string;
  input: string;
  phase: PhaseName;
}

export interface BatchOptions extends ExecutionOptions {
  throughPhase: PhaseName;
  finishMode: FinishMode;
  parallel?: number;
  continueOnFailure?: boolean;
}

interface ItemOutcome {
  slug: string;
  input: string;
  exitCode: number;
  costUsd: number;
  prUrl?: string;
}

export interface BatchResult {
  succeeded: ItemOutcome[];
  failed: ItemOutcome[];
  conflicts: ItemOutcome[];
  totalCostUsd: number;
  exitCode: number;
}

/**
 * Execute a batch of backlog items, sequentially or in parallel.
 *
 * Each item runs in its own worktree. After execution, items are
 * integrated via the configured finish mode (PR, trunk merge, or
 * leave-branch for deferred integration).
 */
export async function executeBatch(
  items: BatchItem[],
  options: BatchOptions,
): Promise<BatchResult> {
  const parallel = options.parallel ?? 1;

  if (parallel <= 1) {
    return executeSequential(items, options);
  }
  return executeParallel(items, options, parallel);
}

/** Integrate outcomes and sort into succeeded/failed/conflicts buckets. */
async function integrateOutcomes(
  outcomes: Array<{ item: BatchItem; outcome: ItemOutcome }>,
  options: BatchOptions,
): Promise<{ succeeded: ItemOutcome[]; failed: ItemOutcome[]; conflicts: ItemOutcome[] }> {
  const succeeded: ItemOutcome[] = [];
  const failed: ItemOutcome[] = [];
  const conflicts: ItemOutcome[] = [];

  for (const { item, outcome } of outcomes) {
    if (outcome.exitCode === 0) {
      const integration = await integrateItem(item.slug, options);
      if (integration.exitCode === 2) {
        conflicts.push({ ...outcome, exitCode: 2 });
      } else if (integration.exitCode !== 0) {
        failed.push({ ...outcome, exitCode: integration.exitCode });
      } else {
        succeeded.push({ ...outcome, prUrl: integration.prUrl });
      }
    } else {
      failed.push(outcome);
      if (options.cleanupOnFailure) {
        await sessionCleanup(item.slug);
      }
    }
  }

  return { succeeded, failed, conflicts };
}

async function executeSequential(
  items: BatchItem[],
  options: BatchOptions,
): Promise<BatchResult> {
  const outcomes: Array<{ item: BatchItem; outcome: ItemOutcome }> = [];
  let totalCostUsd = 0;

  for (const item of items) {
    const outcome = await executeOneItem(item, options);
    totalCostUsd += outcome.costUsd;
    outcomes.push({ item, outcome });

    if (outcome.exitCode !== 0 && !options.continueOnFailure) break;
  }

  const { succeeded, failed, conflicts } = await integrateOutcomes(outcomes, options);

  return {
    succeeded,
    failed,
    conflicts,
    totalCostUsd,
    exitCode: failed.length > 0 || conflicts.length > 0 ? 1 : 0,
  };
}

async function executeParallel(
  items: BatchItem[],
  options: BatchOptions,
  concurrency: number,
): Promise<BatchResult> {
  let totalCostUsd = 0;

  const limit = pLimit(concurrency);
  const outcomes = await Promise.all(
    items.map((item) =>
      limit(async () => {
        const outcome = await executeOneItem(item, options);
        return { item, outcome };
      }),
    ),
  );

  for (const { outcome } of outcomes) {
    totalCostUsd += outcome.costUsd;
  }

  const { succeeded, failed, conflicts } = await integrateOutcomes(outcomes, options);

  return {
    succeeded,
    failed,
    conflicts,
    totalCostUsd,
    exitCode: failed.length > 0 || conflicts.length > 0 ? 1 : 0,
  };
}

async function executeOneItem(
  item: BatchItem,
  options: BatchOptions,
): Promise<ItemOutcome> {
  try {
    const cwd = options.noWorktree
      ? process.cwd()
      : await sessionStart(item.slug, item.phase);

    const { throughPhase, finishMode: _, parallel: _p, continueOnFailure: _c, ...executionOpts } = options;
    const result = await executeSingleItem(item.input, {
      ...executionOpts,
      cwd,
      fromPhase: item.phase,
      throughPhase,
    });

    return {
      slug: item.slug,
      input: item.input,
      exitCode: result.exitCode,
      costUsd: result.totalCostUsd,
    };
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err);
    console.error(`[batch] ${item.slug} failed: ${message}`);
    return {
      slug: item.slug,
      input: item.input,
      exitCode: 1,
      costUsd: 0,
    };
  }
}

async function integrateItem(
  slug: string,
  options: BatchOptions,
): Promise<{ exitCode: number; prUrl?: string }> {
  if (options.finishMode === "leave-branch") {
    return { exitCode: 0 };
  }

  if (options.trunkMode || options.finishMode === "merge") {
    return integrateTrunk(slug);
  }

  return integratePr(slug);
}
