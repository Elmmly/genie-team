import type { GenieConfig } from "../config/genie-config.js";

/**
 * Format the model tier configuration as a human-readable table.
 */
export function formatModelsTable(
  config: GenieConfig,
  configPath?: string,
): string {
  const lines: string[] = [];

  lines.push("Model Tier Configuration");
  lines.push(`Default provider: ${config.provider}`);
  lines.push("─".repeat(60));

  // Build genie-to-tier reverse map
  const tierGenies: Record<string, string[]> = {};
  for (const [genie, tier] of Object.entries(config.assignments)) {
    if (!tierGenies[tier]) tierGenies[tier] = [];
    tierGenies[tier].push(genie);
  }

  // Format each tier
  for (const [tierName, tier] of Object.entries(config.tiers)) {
    const genies = tierGenies[tierName] ?? [];
    const genieList = genies.length > 0 ? genies.join(", ") : "(none)";
    const providerNote = tier.provider ? ` [${tier.provider}]` : "";
    lines.push(
      `  ${tierName.padEnd(12)} ${tier.model.padEnd(32)} ${genieList}${providerNote}`,
    );
  }

  lines.push("");
  lines.push(`Source: ${configPath ?? "built-in defaults"}`);

  return lines.join("\n");
}
