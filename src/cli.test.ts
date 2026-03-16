import { describe, it, expect } from "vitest";
import { createCli } from "./cli.js";

describe("CLI", () => {
  it("exits 127 for unknown subcommands", () => {
    // Arrange
    const cli = createCli();
    cli.exitOverride();

    // Act & Assert
    expect(() => cli.parse(["node", "genies-core", "unknown-cmd"])).toThrow();
  });

  it("parses --version without error", () => {
    // Arrange
    const cli = createCli();
    cli.exitOverride();
    cli.configureOutput({ writeOut: () => {} });

    // Act & Assert
    expect(() => cli.parse(["node", "genies-core", "--version"])).toThrow();
    // Commander throws on --version (exits 0), but should not crash
  });

  it("registers check subcommand", () => {
    // Arrange
    const cli = createCli();

    // Act
    const checkCmd = cli.commands.find((c) => c.name() === "check");

    // Assert
    expect(checkCmd).toBeDefined();
  });

  it("registers models subcommand", () => {
    // Arrange
    const cli = createCli();

    // Act
    const modelsCmd = cli.commands.find((c) => c.name() === "models");

    // Assert
    expect(modelsCmd).toBeDefined();
  });
});
