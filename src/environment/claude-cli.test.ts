import { describe, it, expect } from "vitest";
import { CLAUDE_PATH_ENV, resolveClaudeExecutable } from "./claude-cli.js";

describe("resolveClaudeExecutable", () => {
  it("prefers GENIE_CLAUDE_PATH when it is set", async () => {
    // Arrange
    const env = { [CLAUDE_PATH_ENV]: "/opt/claude/bin/claude" };
    const which = async () => "/usr/local/bin/claude";

    // Act
    const result = await resolveClaudeExecutable(env, which);

    // Assert
    expect(result).toBe("/opt/claude/bin/claude");
  });

  it("falls back to the claude found on PATH", async () => {
    // Arrange
    const env = {};
    const which = async (bin: string) => (bin === "claude" ? "/usr/local/bin/claude" : undefined);

    // Act
    const result = await resolveClaudeExecutable(env, which);

    // Assert
    expect(result).toBe("/usr/local/bin/claude");
  });

  it("ignores a blank GENIE_CLAUDE_PATH", async () => {
    // Arrange
    const env = { [CLAUDE_PATH_ENV]: "   " };
    const which = async () => "/usr/local/bin/claude";

    // Act
    const result = await resolveClaudeExecutable(env, which);

    // Assert
    expect(result).toBe("/usr/local/bin/claude");
  });

  it("returns undefined when nothing is found so the SDK uses its bundled copy", async () => {
    // Arrange
    const env = {};
    const which = async () => undefined;

    // Act
    const result = await resolveClaudeExecutable(env, which);

    // Assert
    expect(result).toBeUndefined();
  });
});
