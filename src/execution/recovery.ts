import { listSessions, integratePr, integrateTrunk, type FinishMode } from "../git/worktree.js";

export interface RecoveryOptions {
  /** List of genie/* branch slugs to recover (without the genie/ prefix). */
  branches: string[];
  /** How to integrate recovered branches. */
  finishMode: FinishMode;
  /** Use trunk-based integration (merge) instead of PR. */
  trunkMode: boolean;
  /** Optional priority filter (e.g. ["P0", "P1"]). */
  priorities?: string[];
}

export interface RecoveryResult {
  recovered: string[];
  failed: string[];
}

/**
 * Run recovery: integrate orphaned genie/* branches.
 *
 * For each branch:
 * 1. Skip if there is an active worktree for it.
 * 2. Apply priority filter if provided.
 * 3. Attempt integration (PR or trunk merge).
 * 4. Categorize as recovered or failed.
 */
export async function runRecovery(
  options: RecoveryOptions,
): Promise<RecoveryResult> {
  const { branches, trunkMode, priorities } = options;
  const recovered: string[] = [];
  const failed: string[] = [];

  if (branches.length === 0) {
    return { recovered, failed };
  }

  // Get active worktree sessions to skip branches that are in use
  const sessions = await listSessions();
  const activeWorktreeBranches = new Set(
    sessions.map((s) => s.branch.replace("genie/", "")),
  );

  for (const branch of branches) {
    // Skip branches with active worktrees
    if (activeWorktreeBranches.has(branch)) {
      continue;
    }

    // Priority filter: branch must start with one of the priority prefixes
    if (priorities && priorities.length > 0) {
      const matchesPriority = priorities.some((p) => branch.startsWith(p));
      if (!matchesPriority) {
        continue;
      }
    }

    // Attempt integration
    const result = trunkMode
      ? await integrateTrunk(branch)
      : await integratePr(branch);

    if (result.exitCode === 0) {
      recovered.push(branch);
    } else {
      failed.push(branch);
    }
  }

  return { recovered, failed };
}
