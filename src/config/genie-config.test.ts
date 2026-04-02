import { describe, it, expect, vi, beforeEach } from "vitest";
import fs from "node:fs";
import path from "node:path";
import os from "node:os";
import {
  loadGenieConfig,
  getModelForGenie,
  resolveGenieConfig,
  DEFAULT_CONFIG,
  type GenieConfig,
} from "./genie-config.js";

vi.mock("node:fs");

describe("loadGenieConfig", () => {
  beforeEach(() => {
    vi.resetAllMocks();
  });

  it("returns defaults when no config file exists", () => {
    // Arrange
    vi.mocked(fs.existsSync).mockReturnValue(false);

    // Act
    const config = loadGenieConfig("/nonexistent/project");

    // Assert
    expect(config).toEqual(DEFAULT_CONFIG);
  });

  it("loads config from project .claude/ directory", () => {
    // Arrange
    const projectRoot = "/my/project";
    const projectConfigPath = path.join(
      projectRoot,
      ".claude",
      "genie-config.yaml",
    );
    const yamlContent = `
tiers:
  reasoning:
    model: "claude-opus-4-6"
    description: "Deep analysis"
  default:
    model: "claude-sonnet-4-6"
    description: "Standard"

assignments:
  scout: reasoning
  crafter: default
`;
    vi.mocked(fs.existsSync).mockImplementation(
      (p) => p === projectConfigPath,
    );
    vi.mocked(fs.readFileSync).mockImplementation((p) => {
      if (p === projectConfigPath) return yamlContent;
      throw new Error(`Unexpected read: ${p}`);
    });

    // Act
    const config = loadGenieConfig(projectRoot);

    // Assert
    expect(config.tiers.reasoning.model).toBe("claude-opus-4-6");
    expect(config.tiers.default.model).toBe("claude-sonnet-4-6");
    expect(config.assignments.scout).toBe("reasoning");
    expect(config.assignments.crafter).toBe("default");
  });

  it("falls back to global ~/.claude/ when project config missing", () => {
    // Arrange
    const globalConfigPath = path.join(
      os.homedir(),
      ".claude",
      "genie-config.yaml",
    );
    const yamlContent = `
tiers:
  default:
    model: "claude-sonnet-4-6"
    description: "Global default"

assignments:
  scout: default
`;
    vi.mocked(fs.existsSync).mockImplementation((p) => p === globalConfigPath);
    vi.mocked(fs.readFileSync).mockImplementation((p) => {
      if (p === globalConfigPath) return yamlContent;
      throw new Error(`Unexpected read: ${p}`);
    });

    // Act
    const config = loadGenieConfig("/project/without/config");

    // Assert
    expect(config.tiers.default.model).toBe("claude-sonnet-4-6");
    expect(config.assignments.scout).toBe("default");
  });

  it("project config takes precedence over global", () => {
    // Arrange
    const projectRoot = "/my/project";
    const projectConfigPath = path.join(
      projectRoot,
      ".claude",
      "genie-config.yaml",
    );
    const globalConfigPath = path.join(
      os.homedir(),
      ".claude",
      "genie-config.yaml",
    );

    const projectYaml = `
tiers:
  default:
    model: "claude-sonnet-4-6"
    description: "Project model"
assignments:
  scout: default
`;
    const globalYaml = `
tiers:
  default:
    model: "claude-haiku-4-5-20251001"
    description: "Global model"
assignments:
  scout: default
`;
    vi.mocked(fs.existsSync).mockImplementation(
      (p) => p === projectConfigPath || p === globalConfigPath,
    );
    vi.mocked(fs.readFileSync).mockImplementation((p) => {
      if (p === projectConfigPath) return projectYaml;
      if (p === globalConfigPath) return globalYaml;
      throw new Error(`Unexpected read: ${p}`);
    });

    // Act
    const config = loadGenieConfig(projectRoot);

    // Assert
    expect(config.tiers.default.model).toBe("claude-sonnet-4-6");
  });

  it("throws on malformed YAML", () => {
    // Arrange
    const projectRoot = "/my/project";
    const configPath = path.join(projectRoot, ".claude", "genie-config.yaml");
    vi.mocked(fs.existsSync).mockImplementation((p) => p === configPath);
    vi.mocked(fs.readFileSync).mockImplementation((p) => {
      if (p === configPath) return "{{ invalid yaml: [";
      throw new Error(`Unexpected read: ${p}`);
    });

    // Act & Assert
    expect(() => loadGenieConfig(projectRoot)).toThrow();
  });

  it("uses cwd as default projectRoot when not provided", () => {
    // Arrange
    vi.mocked(fs.existsSync).mockReturnValue(false);

    // Act
    const config = loadGenieConfig();

    // Assert
    expect(config).toEqual(DEFAULT_CONFIG);
    expect(fs.existsSync).toHaveBeenCalledWith(
      path.join(process.cwd(), ".claude", "genie-config.yaml"),
    );
  });

  it("warns on invalid tier reference in assignments", () => {
    // Arrange
    const projectRoot = "/my/project";
    const configPath = path.join(projectRoot, ".claude", "genie-config.yaml");
    const yamlContent = `
tiers:
  default:
    model: "claude-sonnet-4-6"
    description: "Standard"

assignments:
  scout: nonexistent_tier
`;
    vi.mocked(fs.existsSync).mockImplementation((p) => p === configPath);
    vi.mocked(fs.readFileSync).mockImplementation((p) => {
      if (p === configPath) return yamlContent;
      throw new Error(`Unexpected read: ${p}`);
    });
    const warnSpy = vi.spyOn(console, "warn").mockImplementation(() => {});

    // Act
    const config = loadGenieConfig(projectRoot);

    // Assert
    expect(warnSpy).toHaveBeenCalledWith(
      expect.stringContaining("nonexistent_tier"),
    );
    expect(config.assignments.scout).toBe("nonexistent_tier");

    warnSpy.mockRestore();
  });

  it("handles config with empty tiers gracefully", () => {
    // Arrange
    const projectRoot = "/my/project";
    const configPath = path.join(projectRoot, ".claude", "genie-config.yaml");
    vi.mocked(fs.existsSync).mockImplementation((p) => p === configPath);
    vi.mocked(fs.readFileSync).mockImplementation((p) => {
      if (p === configPath) return "tiers: {}\nassignments: {}";
      throw new Error(`Unexpected read: ${p}`);
    });

    // Act
    const config = loadGenieConfig(projectRoot);

    // Assert
    expect(Object.keys(config.tiers)).toHaveLength(0);
    expect(Object.keys(config.assignments)).toHaveLength(0);
  });
});

describe("getModelForGenie", () => {
  it("returns model for known genie", () => {
    // Arrange
    const config: GenieConfig = {
      provider: "claude",
      tiers: {
        reasoning: { model: "claude-opus-4-6", description: "Deep analysis" },
        default: { model: "claude-sonnet-4-6", description: "Standard" },
      },
      assignments: {
        scout: "reasoning",
        crafter: "default",
      },
    };

    // Act
    const model = getModelForGenie(config, "scout");

    // Assert
    expect(model).toBe("claude-opus-4-6");
  });

  it("returns default tier model for unknown genie", () => {
    // Arrange
    const config: GenieConfig = {
      provider: "claude",
      tiers: {
        default: { model: "claude-sonnet-4-6", description: "Standard" },
      },
      assignments: {},
    };

    // Act
    const model = getModelForGenie(config, "unknown-genie");

    // Assert
    expect(model).toBe("claude-sonnet-4-6");
  });

  it("returns undefined when genie has no assignment and no default tier", () => {
    // Arrange
    const config: GenieConfig = {
      provider: "claude",
      tiers: {
        reasoning: { model: "claude-opus-4-6", description: "Deep analysis" },
      },
      assignments: {},
    };

    // Act
    const model = getModelForGenie(config, "unknown-genie");

    // Assert
    expect(model).toBeUndefined();
  });

  it("returns undefined when genie references a non-existent tier", () => {
    // Arrange
    const config: GenieConfig = {
      provider: "claude",
      tiers: {
        default: { model: "claude-sonnet-4-6", description: "Standard" },
      },
      assignments: {
        scout: "nonexistent",
      },
    };

    // Act
    const model = getModelForGenie(config, "scout");

    // Assert
    expect(model).toBeUndefined();
  });
});

describe("DEFAULT_CONFIG", () => {
  it("has all standard genies assigned", () => {
    // Arrange
    const standardGenies = [
      "scout",
      "shaper",
      "architect",
      "crafter",
      "critic",
      "tidier",
      "designer",
    ];

    // Act & Assert
    for (const genie of standardGenies) {
      expect(DEFAULT_CONFIG.assignments).toHaveProperty(genie);
    }
  });

  it("has reasoning, default, and fast tiers", () => {
    // Act & Assert
    expect(DEFAULT_CONFIG.tiers).toHaveProperty("reasoning");
    expect(DEFAULT_CONFIG.tiers).toHaveProperty("default");
    expect(DEFAULT_CONFIG.tiers).toHaveProperty("fast");
  });

  it("each tier has a model and description", () => {
    // Act & Assert
    for (const [, tier] of Object.entries(DEFAULT_CONFIG.tiers)) {
      expect(tier.model).toBeTruthy();
      expect(tier.description).toBeTruthy();
    }
  });

  it("all assignments reference valid tiers", () => {
    // Act & Assert
    for (const [, tierName] of Object.entries(DEFAULT_CONFIG.assignments)) {
      expect(DEFAULT_CONFIG.tiers).toHaveProperty(tierName);
    }
  });

  it("has provider defaulting to claude", () => {
    expect(DEFAULT_CONFIG.provider).toBe("claude");
  });
});

describe("provider configuration", () => {
  beforeEach(() => {
    vi.resetAllMocks();
  });

  it("parses top-level provider from config", () => {
    // Arrange
    const projectRoot = "/my/project";
    const configPath = path.join(projectRoot, ".claude", "genie-config.yaml");
    const yamlContent = `
provider: openai
tiers:
  default:
    model: gpt-4o
    description: Standard
assignments:
  crafter: default
`;
    vi.mocked(fs.existsSync).mockImplementation((p) => p === configPath);
    vi.mocked(fs.readFileSync).mockImplementation((p) => {
      if (p === configPath) return yamlContent;
      throw new Error(`Unexpected read: ${p}`);
    });

    // Act
    const config = loadGenieConfig(projectRoot);

    // Assert
    expect(config.provider).toBe("openai");
  });

  it("defaults provider to claude when not specified", () => {
    // Arrange
    const projectRoot = "/my/project";
    const configPath = path.join(projectRoot, ".claude", "genie-config.yaml");
    const yamlContent = `
tiers:
  default:
    model: claude-sonnet-4-6
    description: Standard
assignments:
  crafter: default
`;
    vi.mocked(fs.existsSync).mockImplementation((p) => p === configPath);
    vi.mocked(fs.readFileSync).mockImplementation((p) => {
      if (p === configPath) return yamlContent;
      throw new Error(`Unexpected read: ${p}`);
    });

    // Act
    const config = loadGenieConfig(projectRoot);

    // Assert
    expect(config.provider).toBe("claude");
  });

  it("parses per-tier provider override", () => {
    // Arrange
    const projectRoot = "/my/project";
    const configPath = path.join(projectRoot, ".claude", "genie-config.yaml");
    const yamlContent = `
provider: openai
tiers:
  default:
    model: gpt-4o
    description: Standard
  fast:
    provider: google
    model: gemini-2.0-flash
    description: Quick
assignments:
  crafter: default
  critic: fast
`;
    vi.mocked(fs.existsSync).mockImplementation((p) => p === configPath);
    vi.mocked(fs.readFileSync).mockImplementation((p) => {
      if (p === configPath) return yamlContent;
      throw new Error(`Unexpected read: ${p}`);
    });

    // Act
    const config = loadGenieConfig(projectRoot);

    // Assert
    expect(config.tiers.fast.provider).toBe("google");
    expect(config.tiers.default.provider).toBeUndefined();
  });
});

describe("resolveGenieConfig", () => {
  it("returns model and provider for a genie", () => {
    // Arrange
    const config: GenieConfig = {
      provider: "openai",
      tiers: {
        reasoning: { model: "gpt-4o", description: "Deep" },
      },
      assignments: { scout: "reasoning" },
    };

    // Act
    const resolved = resolveGenieConfig(config, "scout");

    // Assert
    expect(resolved.model).toBe("gpt-4o");
    expect(resolved.provider).toBe("openai");
  });

  it("uses per-tier provider when set", () => {
    // Arrange
    const config: GenieConfig = {
      provider: "openai",
      tiers: {
        fast: { model: "gemini-2.0-flash", description: "Quick", provider: "google" },
      },
      assignments: { critic: "fast" },
    };

    // Act
    const resolved = resolveGenieConfig(config, "critic");

    // Assert
    expect(resolved.model).toBe("gemini-2.0-flash");
    expect(resolved.provider).toBe("google");
  });

  it("falls back to top-level provider when tier has no provider", () => {
    // Arrange
    const config: GenieConfig = {
      provider: "anthropic",
      tiers: {
        default: { model: "claude-sonnet-4-6", description: "Standard" },
      },
      assignments: { crafter: "default" },
    };

    // Act
    const resolved = resolveGenieConfig(config, "crafter");

    // Assert
    expect(resolved.provider).toBe("anthropic");
  });

  it("defaults to claude when no provider anywhere", () => {
    // Arrange
    const config: GenieConfig = {
      provider: "claude",
      tiers: {
        default: { model: "claude-sonnet-4-6", description: "Standard" },
      },
      assignments: {},
    };

    // Act
    const resolved = resolveGenieConfig(config, "unknown-genie");

    // Assert
    expect(resolved.provider).toBe("claude");
  });
});
