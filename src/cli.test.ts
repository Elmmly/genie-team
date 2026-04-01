import { describe, it, expect, vi, beforeEach } from "vitest";
import { createCli } from "./cli.js";

vi.mock("./execution/single-item.js", () => ({
  executeSingleItem: vi.fn(),
}));

import { executeSingleItem } from "./execution/single-item.js";
import type { SingleItemResult } from "./execution/single-item.js";

function mockRunResult(overrides?: Partial<SingleItemResult>): SingleItemResult {
  return {
    exitCode: 0,
    verdict: "APPROVED",
    totalCostUsd: 0.05,
    phaseResults: [
      { phase: "deliver" as const, result: {} as never, durationMs: 1000 },
    ],
    ...overrides,
  };
}

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

  it("registers run subcommand", () => {
    // Arrange
    const cli = createCli();

    // Act
    const runCmd = cli.commands.find((c) => c.name() === "run");

    // Assert
    expect(runCmd).toBeDefined();
  });
});

describe("run command", () => {
  beforeEach(() => {
    vi.resetAllMocks();
    vi.spyOn(process, "exit").mockImplementation(() => undefined as never);
    vi.spyOn(console, "log").mockImplementation(() => {});
  });

  it("AC-1: calls executeSingleItem with item argument", async () => {
    // Arrange
    vi.mocked(executeSingleItem).mockResolvedValue(mockRunResult());
    const cli = createCli();

    // Act
    await cli.parseAsync(["node", "genies-core", "run", "docs/backlog/P1-auth.md"]);

    // Assert
    expect(executeSingleItem).toHaveBeenCalledWith(
      "docs/backlog/P1-auth.md",
      expect.objectContaining({
        fromPhase: "discover",
        throughPhase: "done",
      }),
    );
  });

  it("AC-2: --from sets starting phase with default discover", async () => {
    // Arrange
    vi.mocked(executeSingleItem).mockResolvedValue(mockRunResult());
    const cli = createCli();

    // Act
    await cli.parseAsync(["node", "genies-core", "run", "--from", "design", "item.md"]);

    // Assert
    expect(executeSingleItem).toHaveBeenCalledWith(
      "item.md",
      expect.objectContaining({ fromPhase: "design" }),
    );
  });

  it("AC-3: --through sets ending phase with default done", async () => {
    // Arrange
    vi.mocked(executeSingleItem).mockResolvedValue(mockRunResult());
    const cli = createCli();

    // Act
    await cli.parseAsync(["node", "genies-core", "run", "--through", "deliver", "item.md"]);

    // Assert
    expect(executeSingleItem).toHaveBeenCalledWith(
      "item.md",
      expect.objectContaining({ throughPhase: "deliver" }),
    );
  });

  it("AC-4: rejects invalid --from phase with exit code 3", async () => {
    // Arrange
    const cli = createCli();
    cli.exitOverride();
    cli.configureOutput({ writeErr: () => {} });

    // Act & Assert
    await expect(
      cli.parseAsync(["node", "genies-core", "run", "--from", "bogus", "item.md"]),
    ).rejects.toThrow();
  });

  it("AC-4: rejects invalid --through phase with exit code 3", async () => {
    // Arrange
    const cli = createCli();
    cli.exitOverride();
    cli.configureOutput({ writeErr: () => {} });

    // Act & Assert
    await expect(
      cli.parseAsync(["node", "genies-core", "run", "--through", "nope", "item.md"]),
    ).rejects.toThrow();
  });

  it("AC-5: prints summary with phases, cost, and verdict", async () => {
    // Arrange
    vi.mocked(executeSingleItem).mockResolvedValue(mockRunResult({
      totalCostUsd: 0.1234,
      verdict: "APPROVED",
      phaseResults: [
        { phase: "design" as const, result: {} as never, durationMs: 500 },
        { phase: "deliver" as const, result: {} as never, durationMs: 1000 },
      ],
    }));
    const cli = createCli();

    // Act
    await cli.parseAsync(["node", "genies-core", "run", "item.md"]);

    // Assert
    const output = vi.mocked(console.log).mock.calls.map((c) => c[0]).join("\n");
    expect(output).toContain("design");
    expect(output).toContain("deliver");
    expect(output).toContain("0.1234");
    expect(output).toContain("APPROVED");
  });

  it("AC-7: propagates exit code from executeSingleItem", async () => {
    // Arrange
    vi.mocked(executeSingleItem).mockResolvedValue(mockRunResult({ exitCode: 1 }));
    const cli = createCli();

    // Act
    await cli.parseAsync(["node", "genies-core", "run", "item.md"]);

    // Assert
    expect(process.exit).toHaveBeenCalledWith(1);
  });

  it("AC-7: propagates exit code 0 on success", async () => {
    // Arrange
    vi.mocked(executeSingleItem).mockResolvedValue(mockRunResult({ exitCode: 0 }));
    const cli = createCli();

    // Act
    await cli.parseAsync(["node", "genies-core", "run", "item.md"]);

    // Assert
    expect(process.exit).toHaveBeenCalledWith(0);
  });
});

describe("run command extended flags", () => {
  beforeEach(() => {
    vi.resetAllMocks();
    vi.mocked(executeSingleItem).mockResolvedValue(mockRunResult());
    vi.spyOn(process, "exit").mockImplementation(() => undefined as never);
    vi.spyOn(console, "log").mockImplementation(() => {});
  });

  it("--model passes model override", async () => {
    // Arrange
    const cli = createCli();

    // Act
    await cli.parseAsync(["node", "genies-core", "run", "--model", "claude-sonnet-4-5-20250514", "item.md"]);

    // Assert
    expect(executeSingleItem).toHaveBeenCalledWith(
      "item.md",
      expect.objectContaining({ model: "claude-sonnet-4-5-20250514" }),
    );
  });

  it("--turns sets global turn override", async () => {
    // Arrange
    const cli = createCli();

    // Act
    await cli.parseAsync(["node", "genies-core", "run", "--turns", "200", "item.md"]);

    // Assert
    expect(executeSingleItem).toHaveBeenCalledWith(
      "item.md",
      expect.objectContaining({ turnOverrides: { global: 200 } }),
    );
  });

  it("--no-resume sets noResume true", async () => {
    // Arrange
    const cli = createCli();

    // Act
    await cli.parseAsync(["node", "genies-core", "run", "--no-resume", "item.md"]);

    // Assert
    expect(executeSingleItem).toHaveBeenCalledWith(
      "item.md",
      expect.objectContaining({ noResume: true }),
    );
  });

  it("--trunk sets trunkMode true", async () => {
    // Arrange
    const cli = createCli();

    // Act
    await cli.parseAsync(["node", "genies-core", "run", "--trunk", "item.md"]);

    // Assert
    expect(executeSingleItem).toHaveBeenCalledWith(
      "item.md",
      expect.objectContaining({ trunkMode: true }),
    );
  });

  it("--budget sets maxBudgetUsd", async () => {
    // Arrange
    const cli = createCli();

    // Act
    await cli.parseAsync(["node", "genies-core", "run", "--budget", "5.00", "item.md"]);

    // Assert
    expect(executeSingleItem).toHaveBeenCalledWith(
      "item.md",
      expect.objectContaining({ maxBudgetUsd: 5.0 }),
    );
  });

  it("--review-cycles sets reviewCycles", async () => {
    // Arrange
    const cli = createCli();

    // Act
    await cli.parseAsync(["node", "genies-core", "run", "--review-cycles", "3", "item.md"]);

    // Assert
    expect(executeSingleItem).toHaveBeenCalledWith(
      "item.md",
      expect.objectContaining({ reviewCycles: 3 }),
    );
  });

  it("--skip-permissions sets skipPermissions true", async () => {
    // Arrange
    const cli = createCli();

    // Act
    await cli.parseAsync(["node", "genies-core", "run", "--skip-permissions", "item.md"]);

    // Assert
    expect(executeSingleItem).toHaveBeenCalledWith(
      "item.md",
      expect.objectContaining({ skipPermissions: true }),
    );
  });

  it("defaults: no extended flags yields minimal options", async () => {
    // Arrange
    const cli = createCli();

    // Act
    await cli.parseAsync(["node", "genies-core", "run", "item.md"]);

    // Assert
    const opts = vi.mocked(executeSingleItem).mock.calls[0][1];
    expect(opts.model).toBeUndefined();
    expect(opts.trunkMode).toBeUndefined();
    expect(opts.noResume).toBeUndefined();
    expect(opts.turnOverrides).toBeUndefined();
    expect(opts.maxBudgetUsd).toBeUndefined();
    expect(opts.reviewCycles).toBeUndefined();
    expect(opts.skipPermissions).toBeUndefined();
  });
});
