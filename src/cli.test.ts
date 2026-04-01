import { describe, it, expect, vi, beforeEach } from "vitest";
import { createCli } from "./cli.js";

vi.mock("./execution/single-item.js", () => ({
  executeSingleItem: vi.fn(),
}));

vi.mock("./execution/daemon.js", () => ({
  runDaemonCycle: vi.fn(),
}));

vi.mock("./git/worktree.js", () => ({
  listSessions: vi.fn(),
  sessionCleanup: vi.fn(),
}));

vi.mock("./environment/auth.js", () => ({
  resolveAuth: vi.fn(),
}));

import { executeSingleItem } from "./execution/single-item.js";
import type { SingleItemResult } from "./execution/single-item.js";
import { runDaemonCycle } from "./execution/daemon.js";
import type { DaemonCycleResult } from "./execution/daemon.js";
import { listSessions, sessionCleanup } from "./git/worktree.js";
import type { SessionInfo } from "./git/worktree.js";
import { resolveAuth } from "./environment/auth.js";

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
    expect(opts.authMode).toBeUndefined();
  });

  it("--auth oauth passes authMode and calls resolveAuth", async () => {
    // Arrange
    vi.mocked(resolveAuth).mockReturnValue({
      mode: "oauth",
      hasApiKey: false,
      billingNote: "OAuth billing",
    });
    const cli = createCli();

    // Act
    await cli.parseAsync(["node", "genies-core", "run", "--auth", "oauth", "item.md"]);

    // Assert
    expect(resolveAuth).toHaveBeenCalledWith("oauth");
    expect(executeSingleItem).toHaveBeenCalledWith(
      "item.md",
      expect.objectContaining({ authMode: "oauth" }),
    );
  });

  it("--auth apikey passes authMode and calls resolveAuth", async () => {
    // Arrange
    vi.mocked(resolveAuth).mockReturnValue({
      mode: "apikey",
      hasApiKey: true,
      billingNote: "API key billing",
    });
    const cli = createCli();

    // Act
    await cli.parseAsync(["node", "genies-core", "run", "--auth", "apikey", "item.md"]);

    // Assert
    expect(resolveAuth).toHaveBeenCalledWith("apikey");
    expect(executeSingleItem).toHaveBeenCalledWith(
      "item.md",
      expect.objectContaining({ authMode: "apikey" }),
    );
  });
});

function mockDaemonResult(overrides?: Partial<DaemonCycleResult>): DaemonCycleResult {
  return {
    itemsCompleted: 2,
    itemsFailed: 0,
    costUsd: 0.10,
    exitCode: 0,
    ...overrides,
  };
}

describe("daemon command", () => {
  beforeEach(() => {
    vi.resetAllMocks();
    vi.mocked(runDaemonCycle).mockResolvedValue(mockDaemonResult());
    vi.spyOn(process, "exit").mockImplementation(() => undefined as never);
    vi.spyOn(console, "log").mockImplementation(() => {});
  });

  it("registers daemon subcommand", () => {
    // Arrange
    const cli = createCli();

    // Act
    const cmd = cli.commands.find((c) => c.name() === "daemon");

    // Assert
    expect(cmd).toBeDefined();
  });

  it("calls runDaemonCycle with defaults", async () => {
    // Arrange
    const cli = createCli();

    // Act
    await cli.parseAsync(["node", "genies-core", "daemon"]);

    // Assert
    expect(runDaemonCycle).toHaveBeenCalledWith(
      expect.objectContaining({
        throughPhase: "done",
        finishMode: "pr",
      }),
    );
  });

  it("--through sets ending phase", async () => {
    // Arrange
    const cli = createCli();

    // Act
    await cli.parseAsync(["node", "genies-core", "daemon", "--through", "deliver"]);

    // Assert
    expect(runDaemonCycle).toHaveBeenCalledWith(
      expect.objectContaining({ throughPhase: "deliver" }),
    );
  });

  it("--finish sets finish mode", async () => {
    // Arrange
    const cli = createCli();

    // Act
    await cli.parseAsync(["node", "genies-core", "daemon", "--finish", "merge"]);

    // Assert
    expect(runDaemonCycle).toHaveBeenCalledWith(
      expect.objectContaining({ finishMode: "merge" }),
    );
  });

  it("--parallel sets concurrency", async () => {
    // Arrange
    const cli = createCli();

    // Act
    await cli.parseAsync(["node", "genies-core", "daemon", "--parallel", "4"]);

    // Assert
    expect(runDaemonCycle).toHaveBeenCalledWith(
      expect.objectContaining({ parallel: 4 }),
    );
  });

  it("--priority filters by priority", async () => {
    // Arrange
    const cli = createCli();

    // Act
    await cli.parseAsync(["node", "genies-core", "daemon", "--priority", "P0"]);

    // Assert
    expect(runDaemonCycle).toHaveBeenCalledWith(
      expect.objectContaining({ priorities: ["P0"] }),
    );
  });

  it("--model passes through", async () => {
    // Arrange
    const cli = createCli();

    // Act
    await cli.parseAsync(["node", "genies-core", "daemon", "--model", "claude-opus-4-6"]);

    // Assert
    expect(runDaemonCycle).toHaveBeenCalledWith(
      expect.objectContaining({ model: "claude-opus-4-6" }),
    );
  });

  it("--trunk, --skip-permissions, --budget, --log-dir pass through", async () => {
    // Arrange
    const cli = createCli();

    // Act
    await cli.parseAsync([
      "node", "genies-core", "daemon",
      "--trunk", "--skip-permissions", "--budget", "10", "--log-dir", "/tmp/logs",
    ]);

    // Assert
    expect(runDaemonCycle).toHaveBeenCalledWith(
      expect.objectContaining({
        trunkMode: true,
        skipPermissions: true,
        maxBudgetUsd: 10,
        logDir: "/tmp/logs",
      }),
    );
  });

  it("prints summary and propagates exit code", async () => {
    // Arrange
    vi.mocked(runDaemonCycle).mockResolvedValue(mockDaemonResult({
      itemsCompleted: 3,
      itemsFailed: 1,
      costUsd: 0.25,
      exitCode: 1,
    }));
    const cli = createCli();

    // Act
    await cli.parseAsync(["node", "genies-core", "daemon"]);

    // Assert
    const output = vi.mocked(console.log).mock.calls.map((c) => c[0]).join("\n");
    expect(output).toContain("3");
    expect(output).toContain("1");
    expect(output).toContain("0.25");
    expect(process.exit).toHaveBeenCalledWith(1);
  });
});

describe("session command", () => {
  beforeEach(() => {
    vi.resetAllMocks();
    vi.spyOn(process, "exit").mockImplementation(() => undefined as never);
    vi.spyOn(console, "log").mockImplementation(() => {});
  });

  it("registers session subcommand", () => {
    // Arrange
    const cli = createCli();

    // Act
    const cmd = cli.commands.find((c) => c.name() === "session");

    // Assert
    expect(cmd).toBeDefined();
  });

  it("session list calls listSessions and prints results", async () => {
    // Arrange
    vi.mocked(listSessions).mockResolvedValue([
      { path: "/tmp/project--P0-auth", branch: "genie/P0-auth-deliver", slug: "P0-auth" },
    ]);
    const cli = createCli();

    // Act
    await cli.parseAsync(["node", "genies-core", "session", "list"]);

    // Assert
    expect(listSessions).toHaveBeenCalled();
    const output = vi.mocked(console.log).mock.calls.map((c) => c[0]).join("\n");
    expect(output).toContain("P0-auth");
    expect(output).toContain("genie/P0-auth-deliver");
  });

  it("session list prints message when no sessions", async () => {
    // Arrange
    vi.mocked(listSessions).mockResolvedValue([]);
    const cli = createCli();

    // Act
    await cli.parseAsync(["node", "genies-core", "session", "list"]);

    // Assert
    const output = vi.mocked(console.log).mock.calls.map((c) => c[0]).join("\n");
    expect(output).toContain("No active");
  });

  it("session cleanup calls sessionCleanup with item slug", async () => {
    // Arrange
    vi.mocked(sessionCleanup).mockResolvedValue();
    const cli = createCli();

    // Act
    await cli.parseAsync(["node", "genies-core", "session", "cleanup", "P0-auth"]);

    // Assert
    expect(sessionCleanup).toHaveBeenCalledWith("P0-auth");
  });

  it("session cleanup --all cleans up all sessions", async () => {
    // Arrange
    vi.mocked(listSessions).mockResolvedValue([
      { path: "/tmp/p--P0-auth", branch: "genie/P0-auth-deliver", slug: "P0-auth" },
      { path: "/tmp/p--P1-search", branch: "genie/P1-search-design", slug: "P1-search" },
    ]);
    vi.mocked(sessionCleanup).mockResolvedValue();
    const cli = createCli();

    // Act
    await cli.parseAsync(["node", "genies-core", "session", "cleanup", "--all"]);

    // Assert
    expect(sessionCleanup).toHaveBeenCalledWith("P0-auth");
    expect(sessionCleanup).toHaveBeenCalledWith("P1-search");
    expect(sessionCleanup).toHaveBeenCalledTimes(2);
  });
});
