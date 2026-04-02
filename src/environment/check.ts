import { execa } from "execa";
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

const PROVIDER_ENV_KEYS: Record<string, string> = {
  claude: "ANTHROPIC_API_KEY",
  anthropic: "ANTHROPIC_API_KEY",
  openai: "OPENAI_API_KEY",
  google: "GEMINI_API_KEY",
};

export function checkProvider(): CheckResult {
  const config = loadGenieConfig();
  const provider = config.provider;
  const envKey = PROVIDER_ENV_KEYS[provider];

  if (!envKey) {
    return {
      name: "Provider",
      status: "warn",
      detail: `Unknown provider "${provider}" in config`,
    };
  }

  // Claude Tier 1 can use OAuth — API key is optional
  if (provider === "claude") {
    return {
      name: "Provider",
      status: "pass",
      detail: `claude (Tier 1 — Claude Agent SDK)`,
    };
  }

  const hasKey = !!process.env[envKey];
  return {
    name: "Provider",
    status: hasKey ? "pass" : "warn",
    detail: hasKey
      ? `${provider} (Tier 2 — ${envKey} set)`
      : `${provider} (Tier 2 — ${envKey} not set)`,
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
  results.push(checkProvider());
  results.push(checkGenieConfig());

  const hasFail = results.some((r) => r.status === "fail");
  return { results, exitCode: hasFail ? 1 : 0 };
}
