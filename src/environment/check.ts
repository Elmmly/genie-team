import { existsSync, readFileSync } from "node:fs";
import { createRequire } from "node:module";
import { dirname, join } from "node:path";
import { execa } from "execa";
import { CLAUDE_PATH_ENV, resolveClaudeExecutable } from "./claude-cli.js";

const require = createRequire(import.meta.url);
import { detectAuth } from "./auth.js";
import { loadGenieConfig } from "../config/genie-config.js";

export type CheckStatus = "pass" | "warn" | "fail";

export interface CheckResult {
  name: string;
  status: CheckStatus;
  detail: string;
}

// ── Individual checks ──
// Each check is an independent function returning a CheckResult.
// No check depends on another — they can run in any order.

function sdkVersion(): string {
  try {
    // The package does not export its package.json; walk up from its entry file.
    let dir = dirname(require.resolve("@anthropic-ai/claude-agent-sdk"));
    for (let depth = 0; depth < 3; depth++) {
      const candidate = join(dir, "package.json");
      if (existsSync(candidate)) {
        const pkg = JSON.parse(readFileSync(candidate, "utf-8")) as { name?: string; version?: string };
        if (pkg.name === "@anthropic-ai/claude-agent-sdk") return pkg.version ?? "unknown";
      }
      dir = dirname(dir);
    }
  } catch {
    // fall through
  }
  return "unknown";
}

export async function checkClaudeCli(): Promise<CheckResult> {
  const exe = await resolveClaudeExecutable();
  if (!exe) {
    return {
      name: "Claude CLI",
      status: "fail",
      detail: `claude not found on PATH — install from https://claude.com/claude-code or set ${CLAUDE_PATH_ENV}`,
    };
  }
  try {
    const { stdout } = await execa(exe, ["--version"]);
    return {
      name: "Claude CLI",
      status: "pass",
      detail: `v${stdout.trim()} at ${exe} · SDK ${sdkVersion()}`,
    };
  } catch {
    return {
      name: "Claude CLI",
      status: "fail",
      detail: `${exe} did not run — check ${CLAUDE_PATH_ENV} or reinstall from https://claude.com/claude-code`,
    };
  }
}

export async function checkGitRepo(): Promise<CheckResult> {
  try {
    await execa("git", ["rev-parse", "--git-dir"]);
  } catch {
    return {
      name: "Git Repository",
      status: "fail",
      detail: "Not in a git repository",
    };
  }

  // Check for dirty working tree (warn, not fail)
  try {
    const { stdout } = await execa("git", ["status", "--porcelain"]);
    if (stdout.trim().length > 0) {
      return {
        name: "Git Repository",
        status: "warn",
        detail: "Working tree has uncommitted changes",
      };
    }
  } catch {
    // If status check fails, still pass — we confirmed it's a git repo
  }

  return { name: "Git Repository", status: "pass", detail: "Clean" };
}

export async function checkGhAuth(): Promise<CheckResult> {
  try {
    await execa("gh", ["--version"]);
  } catch {
    return {
      name: "GitHub CLI",
      status: "fail",
      detail: "gh not found on PATH — install from https://cli.github.com",
    };
  }

  try {
    await execa("gh", ["auth", "status"]);
    return { name: "GitHub CLI", status: "pass", detail: "Authenticated" };
  } catch {
    return {
      name: "GitHub CLI",
      status: "fail",
      detail: "gh not authenticated — run 'gh auth login'",
    };
  }
}

export function checkAuth(): CheckResult {
  const auth = detectAuth();
  return {
    name: "Auth Mode",
    status: "pass",
    detail: auth.billingNote,
  };
}

export function checkGenieConfig(): CheckResult {
  try {
    const config = loadGenieConfig();
    const tierCount = Object.keys(config.tiers).length;
    const genieCount = Object.keys(config.assignments).length;
    return {
      name: "Genie Config",
      status: "pass",
      detail: `${tierCount} tiers, ${genieCount} genie assignments`,
    };
  } catch (err) {
    return {
      name: "Genie Config",
      status: "fail",
      detail: `Failed to load: ${err instanceof Error ? err.message : String(err)}`,
    };
  }
}

// ── Runner ──

const STATUS_ICON: Record<CheckStatus, string> = {
  pass: "ok",
  warn: "!!",
  fail: "FAIL",
};

export function formatCheckResult(result: CheckResult): string {
  const icon = STATUS_ICON[result.status];
  return `  [${icon}] ${result.name.padEnd(16)} ${result.detail}`;
}

export async function runChecks(): Promise<{
  results: CheckResult[];
  exitCode: number;
}> {
  const results: CheckResult[] = [];

  // Run async checks concurrently
  const [claudeCli, gitRepo, ghAuth] = await Promise.all([
    checkClaudeCli(),
    checkGitRepo(),
    checkGhAuth(),
  ]);

  results.push(claudeCli, gitRepo, ghAuth);

  // Sync checks
  results.push(checkAuth());
  results.push(checkGenieConfig());

  const hasFail = results.some((r) => r.status === "fail");
  return { results, exitCode: hasFail ? 1 : 0 };
}
