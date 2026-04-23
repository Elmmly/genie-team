import { execa } from "execa";
import { existsSync } from "node:fs";
import { join } from "node:path";
import { runPhase } from "../core/phase-executor.js";
import { getFrontmatterField } from "../core/frontmatter.js";
import {
  repoRoot,
  sessionStart,
  sessionCleanup,
  integratePr,
  integrateTrunk,
  listSessions,
  type FinishMode,
} from "../git/worktree.js";
import type { PhaseName } from "../config/phase-config.js";
import type { ExecutionOptions } from "./single-item.js";

export interface FinisherOptions extends ExecutionOptions {
  throughPhase: PhaseName;
  finishMode: FinishMode;
}

export interface FinisherResult {
  recovered: number;
  stalled: string[];
}

/**
 * Determine which PDLC phases remain for a branch based on its
 * current status, review verdict, and uncommitted-changes state.
 */
export function finisherStateToPhases(
  status: string,
  verdict: string,
  hasUncommitted: boolean,
): PhaseName[] {
  if (status === "implemented") {
    if (hasUncommitted) {
      return ["commit", "discern", "commit", "done"];
    }
    return ["discern", "commit", "done"];
  }

  if (status === "reviewed") {
    if (verdict === "APPROVED") {
      if (hasUncommitted) {
        return ["commit", "done"];
      }
      return ["done"];
    }
    if (verdict === "CHANGES_REQUESTED") {
      return ["deliver", "discern"];
    }
  }

  if (status === "designed") {
    return ["deliver", "discern", "commit", "done"];
  }

  if (hasUncommitted) {
    return ["commit"];
  }
  return [];
}

/**
 * List genie/* branch names (short format, e.g. "genie/P1-auth-deliver").
 */
async function listGenieBranches(): Promise<string[]> {
  const { stdout } = await execa("git", [
    "branch", "--list", "genie/*", "--format=%(refname:short)",
  ]);
  return stdout.split("\n").filter((b) => b.length > 0);
}

/**
 * Check if a worktree has uncommitted changes.
 */
async function hasUncommittedChanges(cwd: string): Promise<boolean> {
  const { stdout } = await execa("git", ["status", "--porcelain"], { cwd });
  return stdout.trim().length > 0;
}

/**
 * Find the backlog item file for a branch slug in a worktree.
 */
function findBacklogItem(wtDir: string, slug: string): string | undefined {
  // Try common patterns: slug might be "P1-auth-deliver", item is "P1-auth"
  const itemSlug = slug.replace(/-[a-z]+$/, ""); // strip phase suffix
  const patterns = [
    join(wtDir, "docs", "backlog", `${slug}.md`),
    join(wtDir, "docs", "backlog", `${itemSlug}.md`),
  ];
  for (const p of patterns) {
    if (existsSync(p)) return p;
  }
  return undefined;
}

/**
 * Run the finisher pass: scan genie/* branches, determine remaining
 * phases, execute them, and integrate the results.
 */
export async function runFinisher(
  options: FinisherOptions,
): Promise<FinisherResult> {
  let recovered = 0;
  const stalled: string[] = [];

  const branches = await listGenieBranches();
  if (branches.length === 0) {
    return { recovered, stalled };
  }

  // Skip branches that have active worktrees (someone is working on them)
  const activeSessions = await listSessions();
  const activeSlugSet = new Set(activeSessions.map((s) => s.slug));

  for (const fullBranch of branches) {
    const slug = fullBranch.replace(/^genie\//, "");

    if (activeSlugSet.has(slug)) {
      continue;
    }

    // Clean up any stale worktree, then create fresh
    try {
      await sessionCleanup(slug);
    } catch (err) {
      // No prior worktree — expected for first-time branches
      console.error(`[finisher] cleanup skipped for ${slug}: ${(err as Error).message}`);
    }

    let wtDir: string;
    try {
      wtDir = await sessionStart(slug, "finisher");
    } catch {
      stalled.push(slug);
      continue;
    }

    // Find backlog item
    const itemFile = findBacklogItem(wtDir, slug);
    if (!itemFile) {
      // No backlog item found — clean up and skip
      try { await sessionCleanup(slug); } catch { /* ignore */ }
      continue;
    }

    // Read state from frontmatter
    let itemStatus = "";
    let itemVerdict = "";
    try {
      const s = await getFrontmatterField(itemFile, "status");
      if (typeof s === "string") itemStatus = s;
      const v = await getFrontmatterField(itemFile, "verdict");
      if (typeof v === "string") itemVerdict = v;
    } catch {
      // Unreadable frontmatter — skip
      try { await sessionCleanup(slug); } catch { /* ignore */ }
      continue;
    }

    const uncommitted = await hasUncommittedChanges(wtDir);
    const phases = finisherStateToPhases(itemStatus, itemVerdict, uncommitted);

    if (phases.length === 0) {
      try { await sessionCleanup(slug); } catch { /* ignore */ }
      continue;
    }

    // Execute remaining phases
    let phaseFailed = false;
    for (const phase of phases) {
      try {
        await runPhase(phase, itemFile, {
          cwd: wtDir,
          model: options.model,
          skipPermissions: options.skipPermissions,
          maxBudgetUsd: options.maxBudgetUsd,
          authMode: options.authMode,
        });
      } catch {
        phaseFailed = true;
        break;
      }
    }

    if (phaseFailed) {
      stalled.push(slug);
      continue;
    }

    // Integrate completed work
    let integrationOk = false;
    if (options.finishMode === "merge") {
      const { exitCode } = await integrateTrunk(slug);
      integrationOk = exitCode === 0;
    } else {
      const { exitCode } = await integratePr(slug);
      integrationOk = exitCode === 0;
    }

    if (integrationOk) {
      recovered++;
    } else {
      stalled.push(slug);
    }
  }

  return { recovered, stalled };
}
