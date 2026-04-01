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

async function executeSequential(
  items: BatchItem[],
  options: BatchOptions,
): Promise<BatchResult> {
  const succeeded: ItemOutcome[] = [];
  const failed: ItemOutcome[] = [];
  const conflicts: ItemOutcome[] = [];
  let totalCostUsd = 0;

  for (const item of items) {
    const outcome = await executeOneItem(item, options);
    totalCostUsd += outcome.costUsd;

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
      await sessionCleanup(item.slug);
      if (!options.continueOnFailure) break;
    }
  }

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
  const succeeded: ItemOutcome[] = [];
  const failed: ItemOutcome[] = [];
  const conflicts: ItemOutcome[] = [];
  let totalCostUsd = 0;

  // Concurrency semaphore
  let running = 0;
  let idx = 0;
  const outcomes: Array<{ item: BatchItem; outcome: ItemOutcome }> = [];

  await new Promise<void>((resolve) => {
    function launch() {
      while (running < concurrency && idx < items.length) {
        const item = items[idx++];
        running++;

        executeOneItem(item, options)
          .then((outcome) => {
            outcomes.push({ item, outcome });
            totalCostUsd += outcome.costUsd;
          })
          .catch(() => {
            outcomes.push({
              item,
              outcome: { slug: item.slug, input: item.input, exitCode: 1, costUsd: 0 },
            });
          })
          .finally(() => {
            running--;
            if (running === 0 && idx >= items.length) {
              resolve();
            } else {
              launch();
            }
          });
      }
      if (items.length === 0) resolve();
    }
    launch();
  });

  // Serialize integration
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
      await sessionCleanup(item.slug);
    }
  }

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
    const cwd = await sessionStart(item.slug, item.phase);

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
