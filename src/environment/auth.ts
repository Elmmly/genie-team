export type AuthMode = "oauth" | "apikey";

export interface AuthInfo {
  mode: AuthMode;
  hasApiKey: boolean;
  billingNote: string;
}

/**
 * Detect auth mode from environment.
 */
export function detectAuth(): AuthInfo {
  const apiKey = process.env.ANTHROPIC_API_KEY;
  const hasApiKey = typeof apiKey === "string" && apiKey.length > 0;

  if (hasApiKey) {
    return {
      mode: "apikey",
      hasApiKey: true,
      billingNote: "API key billing (usage charged to key owner)",
    };
  }

  return {
    mode: "oauth",
    hasApiKey: false,
    billingNote: "OAuth billing (usage charged to Claude account)",
  };
}

/**
 * Build an env override for SDK query() based on auth mode.
 * Returns undefined when no override is needed (default or apikey mode).
 */
export function buildAuthEnv(
  mode?: "oauth" | "apikey",
): Record<string, string | undefined> | undefined {
  if (mode === "oauth") {
    return { ...process.env, ANTHROPIC_API_KEY: undefined };
  }
  return undefined;
}

/**
 * Apply --auth flag override to auth detection.
 */
export function resolveAuth(override?: "oauth" | "apikey"): AuthInfo {
  const detected = detectAuth();

  if (!override) {
    return detected;
  }

  if (override === "oauth") {
    return {
      mode: "oauth",
      hasApiKey: detected.hasApiKey,
      billingNote: detected.hasApiKey
        ? "OAuth billing (API key present but --auth oauth specified)"
        : "OAuth billing (usage charged to Claude account)",
    };
  }

  // override === "apikey"
  if (!detected.hasApiKey) {
    throw new Error(
      "--auth apikey requires ANTHROPIC_API_KEY to be set in the environment",
    );
  }

  return {
    mode: "apikey",
    hasApiKey: true,
    billingNote: "API key billing (usage charged to key owner)",
  };
}
