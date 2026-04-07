import { execa } from "execa";
import { basename, dirname, join } from "node:path";
import { PHASES } from "../config/phase-config.js";

// ── Git context helpers ──

export async function repoRoot(): Promise<string> {
  const { stdout } = await execa("git", ["worktree", "list", "--porcelain"]);
  const firstLine = stdout.split("\n")[0];
  return firstLine.replace(/^worktree /, "");
}

export function repoName(root: string): string {
  return basename(root) || root;
}

export async function defaultBranch(): Promise<string> {
  try {
    const { stdout } = await execa("git", [
      "symbolic-ref",
      "refs/remotes/origin/HEAD",
    ]);
    return stdout.replace("refs/remotes/origin/", "").trim();
  } catch {
    // Fallback: check common branch names
    try {
      await execa("git", ["show-ref", "--verify", "--quiet", "refs/heads/main"]);
      return "main";
    } catch {
      try {
        await execa("git", [
          "show-ref",
          "--verify",
          "--quiet",
          "refs/heads/master",
        ]);
        return "master";
      } catch {
        throw new Error("Cannot determine default branch");
      }
    }
  }
}

// ── Naming conventions ──

export function worktreeDir(root: string, item: string): string {
  return join(dirname(root), `${repoName(root)}--${item}`);
}

export function branchName(item: string, phase: string): string {
  return `genie/${item}-${phase}`;
}

// ── Branch helpers ──

export async function branchExists(branch: string): Promise<boolean> {
  try {
    await execa("git", ["show-ref", "--verify", "--quiet", `refs/heads/${branch}`]);
    return true;
  } catch {
    return false;
  }
}

export async function findBranch(item: string): Promise<string | undefined> {
  // Exact match
  try {
    await execa("git", [
      "show-ref",
      "--verify",
      "--quiet",
      `refs/heads/genie/${item}`,
    ]);
    return `genie/${item}`;
  } catch {
    // No exact match
  }

  // Glob match
  const { stdout } = await execa("git", [
    "for-each-ref",
    "--format=%(refname:short)",
    `refs/heads/genie/${item}-*`,
  ]);
  const first = stdout.trim().split("\n")[0];
  return first || undefined;
}

// ── Session listing ──

export interface SessionInfo {
  path: string;
  branch: string;
  slug: string;
}

export async function listSessions(): Promise<SessionInfo[]> {
  const { stdout } = await execa("git", ["worktree", "list", "--porcelain"]);
  const sessions: SessionInfo[] = [];
  const blocks = stdout.split("\n\n");

  for (const block of blocks) {
    const lines = block.trim().split("\n");
    const pathLine = lines.find((l) => l.startsWith("worktree "));
    const branchLine = lines.find((l) => l.startsWith("branch refs/heads/genie/"));
    if (!pathLine || !branchLine) continue;

    const path = pathLine.replace("worktree ", "");
    const branch = branchLine.replace("branch refs/heads/", "");
    // Strip "genie/" prefix and known phase suffix to recover the item slug.
    // Must match against known phases to avoid stripping slug segments
    // (e.g., "P1-done-handler-deliver" → slug "P1-done-handler", not "P1-done-handler").
    const withoutPrefix = branch.replace("genie/", "");
    const phaseSuffix = PHASES.find((p) => withoutPrefix.endsWith(`-${p}`));
    const slug = phaseSuffix
      ? withoutPrefix.slice(0, -(phaseSuffix.length + 1))
      : withoutPrefix;

    sessions.push({ path, branch, slug });
  }

  return sessions;
}

// ── Session lifecycle ──

/**
 * How to integrate a worktree session after execution.
 * "force" is internal-only (used by sessionFinish for cleanup) — not exposed in CLI.
 */
export type FinishMode = "pr" | "merge" | "force" | "leave-branch";

export async function sessionStart(
  item: string,
  phase: string,
): Promise<string> {
  const root = await repoRoot();
  const wtDir = worktreeDir(root, item);
  const branch = branchName(item, phase);
  const baseBranch = await defaultBranch();

  // Reuse: worktree and branch both exist.
  // Note: TOCTOU race exists between branchExists check and worktree add.
  // In parallel daemon runs, two workers could race on the same branch.
  // A proper fix requires file locking (e.g., proper-lockfile). Acceptable
  // risk for single-genie mode; revisit if parallel conflicts are observed.
  if (await branchExists(branch)) {
    // Check if worktree exists by trying to resolve it
    try {
      const { stdout } = await execa("git", ["worktree", "list", "--porcelain"]);
      if (stdout.includes(wtDir)) {
        return wtDir;
      }
      // Branch exists but no worktree — reattach
      await execa("git", ["worktree", "add", wtDir, branch, "-q"]);
      return wtDir;
    } catch {
      // Fall through to fresh creation
    }
  }

  // Clean stale worktree if exists
  try {
    await execa("git", ["worktree", "remove", "--force", wtDir]);
  } catch {
    // Not a worktree — fine
  }

  // Fresh start
  await execa("git", [
    "worktree",
    "add",
    wtDir,
    "-b",
    branch,
    baseBranch,
    "-q",
  ]);

  return wtDir;
}

export async function sessionCleanup(item: string): Promise<void> {
  const root = await repoRoot();
  const wtDir = worktreeDir(root, item);
  const branch = await findBranch(item);

  // Force remove worktree
  try {
    await execa("git", ["-C", root, "worktree", "remove", "--force", wtDir]);
  } catch {
    // Already removed or doesn't exist
  }

  // Force delete branch
  if (branch) {
    try {
      await execa("git", ["-C", root, "branch", "-D", branch]);
    } catch {
      // Already deleted
    }
  }
}

export async function sessionFinish(
  item: string,
  mode: FinishMode,
): Promise<{ prUrl?: string; exitCode: number }> {
  switch (mode) {
    case "force":
      await sessionCleanup(item);
      return { exitCode: 0 };
    case "leave-branch": {
      const root = await repoRoot();
      const wtDir = worktreeDir(root, item);
      try {
        await execa("git", ["-C", root, "worktree", "remove", wtDir]);
      } catch {
        try {
          await execa("git", [
            "-C",
            root,
            "worktree",
            "remove",
            "--force",
            wtDir,
          ]);
        } catch {
          // Already gone
        }
      }
      return { exitCode: 0 };
    }
    case "merge":
      return integrateTrunk(item);
    case "pr":
      return integratePr(item);
  }
}

export async function integratePr(
  item: string,
): Promise<{ prUrl?: string; exitCode: number }> {
  const root = await repoRoot();
  const branch = await findBranch(item);
  if (!branch) return { exitCode: 1 };

  const base = await defaultBranch();

  // Push
  try {
    await execa("git", ["-C", root, "push", "--quiet", "-u", "origin", branch]);
  } catch {
    return { exitCode: 1 };
  }

  // Create PR
  let prUrl: string | undefined;
  try {
    const scope = item.replace(/^P\d+-/, "");
    const title = `feat(${scope}): ${item} delivery`;
    const body = `## Summary\n\nSession delivery for backlog item.\n\n**Backlog:** docs/backlog/${item}.md`;

    const { stdout } = await execa("gh", [
      "pr",
      "create",
      "--base",
      base,
      "--head",
      branch,
      "--title",
      title,
      "--body",
      body,
    ], { cwd: root });
    prUrl = stdout.trim();
  } catch {
    // PR creation failed — branch is pushed, user can create manually
  }

  // Only delete local branch if PR was created successfully.
  // If PR creation failed, keep the local branch so the user has a reference.
  if (prUrl) {
    try {
      await execa("git", ["-C", root, "branch", "-D", branch]);
    } catch {
      // May already be deleted
    }
  }

  return { prUrl, exitCode: 0 };
}

export async function integrateTrunk(
  item: string,
): Promise<{ exitCode: number }> {
  const root = await repoRoot();
  const branch = await findBranch(item);
  if (!branch) return { exitCode: 1 };

  const base = await defaultBranch();

  // Rebase onto default
  try {
    await execa("git", ["-C", root, "rebase", base, branch, "-q"]);
  } catch {
    try {
      await execa("git", ["-C", root, "rebase", "--abort"]);
    } catch {
      // May not be in rebase state
    }
    return { exitCode: 2 }; // Rebase conflict
  }

  // Checkout default and ff-merge
  try {
    await execa("git", ["-C", root, "checkout", base, "-q"]);
  } catch {
    return { exitCode: 3 };
  }

  try {
    await execa("git", ["-C", root, "merge", "--ff-only", branch, "-q"]);
  } catch {
    return { exitCode: 4 };
  }

  // Delete branch
  try {
    await execa("git", ["-C", root, "branch", "-d", branch]);
  } catch {
    // Already deleted or not merged
  }

  return { exitCode: 0 };
}
