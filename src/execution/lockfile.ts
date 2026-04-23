import { existsSync, readFileSync, writeFileSync, unlinkSync, mkdirSync } from "node:fs";
import { join } from "node:path";

export interface LockOptions {
  /** Directory for lock files (default: process.cwd()). */
  lockDir?: string;
  /** Hours before considering a lock stale (default: 4). */
  staleHours?: number;
}

export interface LockHandle {
  release: () => Promise<void>;
}

interface LockFileContent {
  pid: number;
  timestamp: string;
  slug: string;
}

const DEFAULT_STALE_HOURS = 4;

function lockFilePath(slug: string, lockDir: string): string {
  return join(lockDir, `.genies-${slug}.lock`);
}

/**
 * Check if a PID is alive by sending signal 0.
 * Returns true if the process exists, false if it does not.
 */
function isPidAlive(pid: number): boolean {
  try {
    process.kill(pid, 0);
    return true;
  } catch {
    return false;
  }
}

/**
 * Determine whether an existing lock should be considered stale
 * based on its timestamp and the staleHours threshold.
 */
function isStale(lockContent: LockFileContent, staleHours: number): boolean {
  const lockTime = new Date(lockContent.timestamp).getTime();
  const now = Date.now();
  const staleMs = staleHours * 60 * 60 * 1000;
  return now - lockTime > staleMs;
}

/**
 * Acquire a lock for the given slug.
 *
 * - If no lock exists, creates one.
 * - If lock exists but PID is dead, removes stale lock and acquires.
 * - If lock exists but timestamp exceeds staleHours, removes and acquires.
 * - If lock exists and PID is alive and not stale, throws.
 */
export async function acquireLock(
  slug: string,
  opts?: LockOptions,
): Promise<LockHandle> {
  const lockDir = opts?.lockDir ?? process.cwd();
  const staleHours = opts?.staleHours ?? DEFAULT_STALE_HOURS;
  const filePath = lockFilePath(slug, lockDir);

  mkdirSync(lockDir, { recursive: true });

  if (existsSync(filePath)) {
    const raw = readFileSync(filePath, "utf-8");
    const lockContent: LockFileContent = JSON.parse(raw);

    if (isStale(lockContent, staleHours)) {
      // Stale lock — remove and acquire
      unlinkSync(filePath);
    } else if (isPidAlive(lockContent.pid)) {
      throw new Error(
        `Locked: slug "${slug}" is held by running process ${lockContent.pid} (${filePath})`,
      );
    } else {
      // PID is dead — remove and acquire
      unlinkSync(filePath);
    }
  }

  const content: LockFileContent = {
    pid: process.pid,
    timestamp: new Date().toISOString(),
    slug,
  };

  writeFileSync(filePath, JSON.stringify(content));

  return {
    release: async () => {
      unlinkSync(filePath);
    },
  };
}

/**
 * Check if a slug is currently locked by a live, non-stale process.
 */
export function isLocked(slug: string, opts?: LockOptions): boolean {
  const lockDir = opts?.lockDir ?? process.cwd();
  const staleHours = opts?.staleHours ?? DEFAULT_STALE_HOURS;
  const filePath = lockFilePath(slug, lockDir);

  if (!existsSync(filePath)) {
    return false;
  }

  const raw = readFileSync(filePath, "utf-8");
  const lockContent: LockFileContent = JSON.parse(raw);

  if (isStale(lockContent, staleHours)) {
    return false;
  }

  return isPidAlive(lockContent.pid);
}
