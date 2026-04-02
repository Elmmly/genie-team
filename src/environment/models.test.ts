import { describe, it, expect, vi, beforeEach } from "vitest";
import fs from "node:fs";
import { formatModelsTable } from "./models.js";
import { DEFAULT_CONFIG, type GenieConfig } from "../config/genie-config.js";

describe("formatModelsTable", () => {
  it("includes all tier names", () => {
    // Arrange & Act
    const output = formatModelsTable(DEFAULT_CONFIG);

    // Assert
    expect(output).toContain("reasoning");
    expect(output).toContain("default");
    expect(output).toContain("fast");
  });

  it("includes model IDs", () => {
    // Arrange & Act
    const output = formatModelsTable(DEFAULT_CONFIG);

    // Assert
    expect(output).toContain("claude-opus-4-6");
    expect(output).toContain("claude-sonnet-4-6");
    expect(output).toContain("claude-haiku-4-5-20251001");
  });

  it("includes genie assignments", () => {
    // Arrange & Act
    const output = formatModelsTable(DEFAULT_CONFIG);

    // Assert
    expect(output).toContain("scout");
    expect(output).toContain("architect");
    expect(output).toContain("crafter");
    expect(output).toContain("critic");
  });

  it("groups genies by tier", () => {
    // Arrange
    const config: GenieConfig = {
      provider: "claude",
      tiers: {
        reasoning: { model: "claude-opus-4-6", description: "Deep" },
        default: { model: "claude-sonnet-4-6", description: "Standard" },
      },
      assignments: {
        scout: "reasoning",
        architect: "reasoning",
        crafter: "default",
      },
    };

    // Act
    const output = formatModelsTable(config);

    // Assert — reasoning line should contain both scout and architect
    const lines = output.split("\n");
    const reasoningLine = lines.find((l) => l.includes("claude-opus-4-6"));
    expect(reasoningLine).toContain("scout");
    expect(reasoningLine).toContain("architect");
  });

  it("handles config with no assignments", () => {
    // Arrange
    const config: GenieConfig = {
      provider: "claude",
      tiers: {
        default: { model: "claude-sonnet-4-6", description: "Standard" },
      },
      assignments: {},
    };

    // Act
    const output = formatModelsTable(config);

    // Assert
    expect(output).toContain("claude-sonnet-4-6");
  });

  it("shows config source when provided", () => {
    // Arrange & Act
    const output = formatModelsTable(DEFAULT_CONFIG, "/project/.claude/genie-config.yaml");

    // Assert
    expect(output).toContain("/project/.claude/genie-config.yaml");
  });

  it("shows 'built-in defaults' when no config path", () => {
    // Arrange & Act
    const output = formatModelsTable(DEFAULT_CONFIG);

    // Assert
    expect(output).toContain("built-in defaults");
  });
});
