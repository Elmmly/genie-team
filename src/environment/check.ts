import { execa } from "execa";
import { detectAuth } from "./auth.js";
import { loadGenieConfig } from "../config/genie-config.js";
import { getProviderStatuses } from "./provider-status.js";

export type CheckStatus = "pass" | "warn" | "fail";

export interface CheckResult {
  name: string;
  status: CheckStatus;
  detail: string;
}

// ── Individual checks ──
// Each check is an independent function returning a CheckResult.
// No check depends on another — they can run in any order.

export async function checkClaudeCli(): Promise<CheckResult> {
  try {
    const { stdout } = await execa("claude", ["--version"]);
    return {
      name: "Claude CLI",
      status: "pass",
      detail: `v${stdout.trim()}`,
    };
  } catch {
    return {
      name: "Claude CLI",
      status: "fail",
      detail: "claude not found on PATH — install from https://claude.com/claude-code",
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

export function checkProvider(): CheckResult {
  const config = loadGenieConfig();
  const statuses = getProviderStatuses();
  const active = statuses.find((s) => s.name === config.provider);

  if (!active) {
    return {
      name: "Provider",
      status: "fail",
      detail: `Unknown provider "${config.provider}" in config`,
    };
  }

  if (!active.installed) {
    return {
      name: "Provider",
      status: "fail",
      detail: `${active.name} not installed — run: genies-core install ${active.name}`,
    };
  }

  if (active.status === "installed_no_key") {
    return {
      name: "Provider",
      status: "warn",
      detail: `${active.name} (Tier ${active.tier}) — ${active.envKey} not set`,
    };
  }

  return {
    name: "Provider",
    status: "pass",
    detail: `${active.name} (Tier ${active.tier} — ready)`,
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

  const config = loadGenieConfig();

  // Run async checks concurrently
  const [claudeCli, gitRepo, ghAuth] = await Promise.all([
    checkClaudeCli(),
    checkGitRepo(),
    checkGhAuth(),
  ]);

  // Only show Claude CLI check if using claude provider
  if (config.provider === "claude") {
    results.push(claudeCli);
  }
  results.push(gitRepo, ghAuth);

  // Sync checks
  if (config.provider === "claude") {
    results.push(checkAuth());
  }
  results.push(checkProvider());
  results.push(checkGenieConfig());

  const hasFail = results.some((r) => r.status === "fail");
  return { results, exitCode: hasFail ? 1 : 0 };
}
