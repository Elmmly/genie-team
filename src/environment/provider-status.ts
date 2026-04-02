import { createRequire } from "node:module";

const require = createRequire(import.meta.url);

/** Provider SDK package names. Shared source of truth. */
export const PROVIDER_PACKAGES: Record<string, string> = {
  claude: "@anthropic-ai/claude-agent-sdk",
  anthropic: "@anthropic-ai/sdk",
  openai: "openai",
  google: "@google/genai",
};

export type ProviderInstallStatus = "ready" | "installed_no_key" | "not_installed";

export interface ProviderStatus {
  name: string;
  tier: 1 | 2;
  installed: boolean;
  hasKey: boolean;
  status: ProviderInstallStatus;
  envKey: string;
  npmPackage: string;
  description: string;
}

const PROVIDER_INFO: Array<{
  name: string;
  tier: 1 | 2;
  envKey: string;
  description: string;
}> = [
  { name: "claude", tier: 1, envKey: "ANTHROPIC_API_KEY", description: "Claude Agent SDK (full fidelity)" },
  { name: "anthropic", tier: 2, envKey: "ANTHROPIC_API_KEY", description: "Anthropic Messages API" },
  { name: "openai", tier: 2, envKey: "OPENAI_API_KEY", description: "OpenAI Chat Completions" },
  { name: "google", tier: 2, envKey: "GEMINI_API_KEY", description: "Google Gemini GenerateContent" },
];

function isPackageInstalled(pkg: string): boolean {
  try {
    require.resolve(pkg);
    return true;
  } catch {
    return false;
  }
}

export function getProviderStatuses(): ProviderStatus[] {
  return PROVIDER_INFO.map((p) => {
    const npmPackage = PROVIDER_PACKAGES[p.name];
    const installed = isPackageInstalled(npmPackage);
    // Claude can use OAuth — key is optional for Tier 1
    const hasKey = p.name === "claude"
      ? installed
      : !!process.env[p.envKey];

    let status: ProviderInstallStatus;
    if (!installed) {
      status = "not_installed";
    } else if (!hasKey && p.name !== "claude") {
      status = "installed_no_key";
    } else {
      status = "ready";
    }

    return {
      ...p,
      installed,
      hasKey,
      status,
      npmPackage,
    };
  });
}
