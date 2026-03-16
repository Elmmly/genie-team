import fs from "node:fs";
import path from "node:path";
import os from "node:os";
import yaml from "js-yaml";

/** Model tier definition — maps a tier name to a specific model ID. */
export interface ModelTier {
  model: string;
  description: string;
}

/** Genie configuration — defines model tiers and per-genie tier assignments. */
export interface GenieConfig {
  tiers: Record<string, ModelTier>;
  assignments: Record<string, string>;
}

/** Sensible defaults matching the standard genie-config.yaml example. */
export const DEFAULT_CONFIG: GenieConfig = {
  tiers: {
    reasoning: {
      model: "claude-opus-4-6",
      description: "Deep analysis and design",
    },
    default: {
      model: "claude-sonnet-4-6",
      description: "Standard delivery",
    },
    fast: {
      model: "claude-haiku-4-5-20251001",
      description: "Quick validation",
    },
  },
  assignments: {
    scout: "reasoning",
    shaper: "default",
    architect: "reasoning",
    crafter: "default",
    critic: "fast",
    tidier: "default",
    designer: "default",
  },
};

interface RawGenieConfig {
  tiers?: Record<string, { model?: string; description?: string }>;
  assignments?: Record<string, string>;
}

/**
 * Loads genie configuration from the first available source:
 * 1. Project-level: {projectRoot}/.claude/genie-config.yaml
 * 2. Global: ~/.claude/genie-config.yaml
 * 3. Built-in defaults
 *
 * Throws on malformed YAML. Returns defaults when no config file exists.
 * Warns if assignments reference non-existent tiers.
 */
export function loadGenieConfig(projectRoot?: string): GenieConfig {
  const root = projectRoot ?? process.cwd();
  const projectConfigPath = path.join(root, ".claude", "genie-config.yaml");
  const globalConfigPath = path.join(
    os.homedir(),
    ".claude",
    "genie-config.yaml",
  );

  if (fs.existsSync(projectConfigPath)) {
    return parseConfigFile(projectConfigPath);
  }

  if (fs.existsSync(globalConfigPath)) {
    return parseConfigFile(globalConfigPath);
  }

  return DEFAULT_CONFIG;
}

/**
 * Resolves the model ID for a given genie name.
 * Falls back to 'default' tier if no assignment exists.
 * Returns undefined if the resolved tier does not exist.
 */
export function getModelForGenie(
  config: GenieConfig,
  genieName: string,
): string | undefined {
  const tierName = config.assignments[genieName] ?? "default";
  return config.tiers[tierName]?.model;
}

function parseConfigFile(filePath: string): GenieConfig {
  const content = fs.readFileSync(filePath, "utf-8");
  const raw = yaml.load(content) as RawGenieConfig;

  if (!raw || typeof raw !== "object") {
    throw new Error(
      `Invalid genie config at ${filePath}: expected an object`,
    );
  }

  const tiers: Record<string, ModelTier> = {};
  if (raw.tiers && typeof raw.tiers === "object") {
    for (const [name, tier] of Object.entries(raw.tiers)) {
      tiers[name] = {
        model: tier.model ?? "",
        description: tier.description ?? "",
      };
    }
  }

  const assignments: Record<string, string> = {};
  if (raw.assignments && typeof raw.assignments === "object") {
    for (const [genie, tierName] of Object.entries(raw.assignments)) {
      assignments[genie] = tierName;
      if (!tiers[tierName]) {
        console.warn(
          `genie-config: genie "${genie}" references tier "${tierName}" which does not exist in tiers`,
        );
      }
    }
  }

  return { tiers, assignments };
}
