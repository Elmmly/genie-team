import { describe, it, expect, vi, beforeEach } from "vitest";
import { createCli } from "./cli.js";

vi.mock("./execution/single-item.js", () => ({
  executeSingleItem: vi.fn(),
}));

vi.mock("./execution/daemon.js", () => ({
  runDaemonCycle: vi.fn(),
}));

vi.mock("./execution/daemon-loop.js", () => ({
  runDaemon: vi.fn(),
  stopDaemon: vi.fn(),
  readDaemonStatus: vi.fn(),
}));

vi.mock("./git/worktree.js", () => ({
  listSessions: vi.fn(),
  sessionCleanup: vi.fn(),
}));

vi.mock("./environment/auth.js", () => ({
  resolveAuth: vi.fn(),
}));

vi.mock("./environment/check.js", () => ({
  runChecks: vi.fn(),
  formatCheckResult: vi.fn(),
}));

vi.mock("./execution/lockfile.js", () => ({
  acquireLock: vi.fn(),
}));

vi.mock("./status/batch-status.js", () => ({
  readBatchStatus: vi.fn(),
  formatStatusTable: vi.fn(),
  formatStatusJson: vi.fn(),
}));

import { executeSingleItem } from "./execution/single-item.js";
import type { SingleItemResult } from "./execution/single-item.js";
import { runDaemonCycle } from "./execution/daemon.js";
import type { DaemonCycleResult } from "./execution/daemon.js";
import { runDaemon, stopDaemon, readDaemonStatus } from "./execution/daemon-loop.js";
import type { DaemonStatus } from "./execution/daemon-loop.js";
import { listSessions, sessionCleanup } from "./git/worktree.js";
import type { SessionInfo } from "./git/worktree.js";
import { resolveAuth } from "./environment/auth.js";
import { runChecks } from "./environment/check.js";
import { acquireLock } from "./execution/lockfile.js";
import { readBatchStatus, formatStatusTable, formatStatusJson } from "./status/batch-status.js";
import type { StatusReport } from "./status/batch-status.js";

/** Set up default mocks for run command preflight and lock. Call after vi.resetAllMocks(). */
function setupRunMocks(): void {
  vi.mocked(runChecks).mockResolvedValue({ results: [], exitCode: 0 });
  vi.mocked(acquireLock).mockResolvedValue({ release: vi.fn() });
}

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
    expect(() => cli.parse(["node", "genies", "unknown-cmd"])).toThrow();
  });

  it("parses --version without error", () => {
    // Arrange
    const cli = createCli();
    cli.exitOverride();
    cli.configureOutput({ writeOut: () => {} });

    // Act & Assert
    expect(() => cli.parse(["node", "genies", "--version"])).toThrow();
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

  it("registers quality subcommand", () => {
    // Arrange
    const cli = createCli();

    // Act
    const qualityCmd = cli.commands.find((c) => c.name() === "quality");

    // Assert
    expect(qualityCmd).toBeDefined();
  });
});

describe("run command", () => {
  beforeEach(() => {
    vi.resetAllMocks();
    setupRunMocks();
    vi.spyOn(process, "exit").mockImplementation(() => undefined as never);
    vi.spyOn(console, "log").mockImplementation(() => {});
  });

  it("AC-1: calls executeSingleItem with item argument", async () => {
    // Arrange
    vi.mocked(executeSingleItem).mockResolvedValue(mockRunResult());
    const cli = createCli();

    // Act
    await cli.parseAsync(["node", "genies", "run", "docs/backlog/P1-auth.md"]);

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
    await cli.parseAsync(["node", "genies", "run", "--from", "design", "item.md"]);

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
    await cli.parseAsync(["node", "genies", "run", "--through", "deliver", "item.md"]);

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
      cli.parseAsync(["node", "genies", "run", "--from", "bogus", "item.md"]),
    ).rejects.toThrow();
  });

  it("AC-4: rejects invalid --through phase with exit code 3", async () => {
    // Arrange
    const cli = createCli();
    cli.exitOverride();
    cli.configureOutput({ writeErr: () => {} });

    // Act & Assert
    await expect(
      cli.parseAsync(["node", "genies", "run", "--through", "nope", "item.md"]),
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
    await cli.parseAsync(["node", "genies", "run", "item.md"]);

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
    await cli.parseAsync(["node", "genies", "run", "item.md"]);

    // Assert
    expect(process.exit).toHaveBeenCalledWith(1);
  });

  it("AC-7: propagates exit code 0 on success", async () => {
    // Arrange
    vi.mocked(executeSingleItem).mockResolvedValue(mockRunResult({ exitCode: 0 }));
    const cli = createCli();

    // Act
    await cli.parseAsync(["node", "genies", "run", "item.md"]);

    // Assert
    expect(process.exit).toHaveBeenCalledWith(0);
  });
});

describe("run command extended flags", () => {
  beforeEach(() => {
    vi.resetAllMocks();
    setupRunMocks();
    vi.mocked(executeSingleItem).mockResolvedValue(mockRunResult());
    vi.spyOn(process, "exit").mockImplementation(() => undefined as never);
    vi.spyOn(console, "log").mockImplementation(() => {});
  });

  it("--model passes model override", async () => {
    // Arrange
    const cli = createCli();

    // Act
    await cli.parseAsync(["node", "genies", "run", "--model", "claude-sonnet-4-5-20250514", "item.md"]);

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
    await cli.parseAsync(["node", "genies", "run", "--turns", "200", "item.md"]);

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
    await cli.parseAsync(["node", "genies", "run", "--no-resume", "item.md"]);

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
    await cli.parseAsync(["node", "genies", "run", "--trunk", "item.md"]);

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
    await cli.parseAsync(["node", "genies", "run", "--budget", "5.00", "item.md"]);

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
    await cli.parseAsync(["node", "genies", "run", "--review-cycles", "3", "item.md"]);

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
    await cli.parseAsync(["node", "genies", "run", "--skip-permissions", "item.md"]);

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
    await cli.parseAsync(["node", "genies", "run", "item.md"]);

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
    expect(opts.verbose).toBeUndefined();
  });

  it("--verbose passes verbose true", async () => {
    // Arrange
    const cli = createCli();

    // Act
    await cli.parseAsync(["node", "genies", "run", "--verbose", "item.md"]);

    // Assert
    expect(executeSingleItem).toHaveBeenCalledWith(
      "item.md",
      expect.objectContaining({ verbose: true }),
    );
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
    await cli.parseAsync(["node", "genies", "run", "--auth", "oauth", "item.md"]);

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
    await cli.parseAsync(["node", "genies", "run", "--auth", "apikey", "item.md"]);

    // Assert
    expect(resolveAuth).toHaveBeenCalledWith("apikey");
    expect(executeSingleItem).toHaveBeenCalledWith(
      "item.md",
      expect.objectContaining({ authMode: "apikey" }),
    );
  });
});

describe("run command phase 3 flags", () => {
  beforeEach(() => {
    vi.resetAllMocks();
    setupRunMocks();
    vi.mocked(executeSingleItem).mockResolvedValue(mockRunResult());
    vi.spyOn(process, "exit").mockImplementation(() => undefined as never);
    vi.spyOn(console, "log").mockImplementation(() => {});
  });

  it("--dry-run sets dryRun true", async () => {
    // Arrange
    const cli = createCli();

    // Act
    await cli.parseAsync(["node", "genies", "run", "--dry-run", "item.md"]);

    // Assert
    expect(executeSingleItem).toHaveBeenCalledWith(
      "item.md",
      expect.objectContaining({ dryRun: true }),
    );
  });

  it("--no-worktree sets noWorktree true", async () => {
    // Arrange
    const cli = createCli();

    // Act
    await cli.parseAsync(["node", "genies", "run", "--no-worktree", "item.md"]);

    // Assert
    expect(executeSingleItem).toHaveBeenCalledWith(
      "item.md",
      expect.objectContaining({ noWorktree: true }),
    );
  });

  it("--finish-mode sets finishMode", async () => {
    // Arrange
    const cli = createCli();

    // Act
    await cli.parseAsync(["node", "genies", "run", "--finish-mode", "merge", "item.md"]);

    // Assert
    expect(executeSingleItem).toHaveBeenCalledWith(
      "item.md",
      expect.objectContaining({ finishMode: "merge" }),
    );
  });

  it("--finish-mode rejects invalid mode", async () => {
    // Arrange
    const cli = createCli();
    cli.exitOverride();
    cli.configureOutput({ writeErr: () => {} });

    // Act & Assert
    await expect(
      cli.parseAsync(["node", "genies", "run", "--finish-mode", "bad", "item.md"]),
    ).rejects.toThrow();
  });

  it("--min-phase sets minPhase", async () => {
    // Arrange
    const cli = createCli();

    // Act
    await cli.parseAsync(["node", "genies", "run", "--min-phase", "design", "item.md"]);

    // Assert
    expect(executeSingleItem).toHaveBeenCalledWith(
      "item.md",
      expect.objectContaining({ minPhase: "design" }),
    );
  });

  it("--continue-on-failure sets continueOnFailure true", async () => {
    // Arrange
    const cli = createCli();

    // Act
    await cli.parseAsync(["node", "genies", "run", "--continue-on-failure", "item.md"]);

    // Assert
    expect(executeSingleItem).toHaveBeenCalledWith(
      "item.md",
      expect.objectContaining({ continueOnFailure: true }),
    );
  });

  it("--cleanup-on-failure sets cleanupOnFailure true", async () => {
    // Arrange
    const cli = createCli();

    // Act
    await cli.parseAsync(["node", "genies", "run", "--cleanup-on-failure", "item.md"]);

    // Assert
    expect(executeSingleItem).toHaveBeenCalledWith(
      "item.md",
      expect.objectContaining({ cleanupOnFailure: true }),
    );
  });

  it("--slug sets worktreeSlug", async () => {
    // Arrange
    const cli = createCli();

    // Act
    await cli.parseAsync(["node", "genies", "run", "--slug", "custom-slug", "item.md"]);

    // Assert
    expect(executeSingleItem).toHaveBeenCalledWith(
      "item.md",
      expect.objectContaining({ worktreeSlug: "custom-slug" }),
    );
  });

  it("--lock sets useLock true", async () => {
    // Arrange
    const cli = createCli();

    // Act
    await cli.parseAsync(["node", "genies", "run", "--lock", "item.md"]);

    // Assert
    expect(executeSingleItem).toHaveBeenCalledWith(
      "item.md",
      expect.objectContaining({ useLock: true }),
    );
  });

  it("--no-preflight sets noPreflight true", async () => {
    // Arrange
    const cli = createCli();

    // Act
    await cli.parseAsync(["node", "genies", "run", "--no-preflight", "item.md"]);

    // Assert
    expect(executeSingleItem).toHaveBeenCalledWith(
      "item.md",
      expect.objectContaining({ noPreflight: true }),
    );
  });

  it("--discover-turns sets per-phase turn override", async () => {
    // Arrange
    const cli = createCli();

    // Act
    await cli.parseAsync(["node", "genies", "run", "--discover-turns", "25", "item.md"]);

    // Assert
    expect(executeSingleItem).toHaveBeenCalledWith(
      "item.md",
      expect.objectContaining({
        turnOverrides: expect.objectContaining({ discover: 25 }),
      }),
    );
  });

  it("--deliver-turns sets per-phase turn override", async () => {
    // Arrange
    const cli = createCli();

    // Act
    await cli.parseAsync(["node", "genies", "run", "--deliver-turns", "200", "item.md"]);

    // Assert
    expect(executeSingleItem).toHaveBeenCalledWith(
      "item.md",
      expect.objectContaining({
        turnOverrides: expect.objectContaining({ deliver: 200 }),
      }),
    );
  });

  it("per-phase turns combine with --turns global", async () => {
    // Arrange
    const cli = createCli();

    // Act
    await cli.parseAsync([
      "node", "genies", "run",
      "--turns", "50",
      "--deliver-turns", "200",
      "item.md",
    ]);

    // Assert
    expect(executeSingleItem).toHaveBeenCalledWith(
      "item.md",
      expect.objectContaining({
        turnOverrides: { global: 50, deliver: 200 },
      }),
    );
  });

  it("--deliver-min-turns sets deliverMinTurns", async () => {
    // Arrange
    const cli = createCli();

    // Act
    await cli.parseAsync(["node", "genies", "run", "--deliver-min-turns", "10", "item.md"]);

    // Assert
    expect(executeSingleItem).toHaveBeenCalledWith(
      "item.md",
      expect.objectContaining({ deliverMinTurns: 10 }),
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
    await cli.parseAsync(["node", "genies", "daemon"]);

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
    await cli.parseAsync(["node", "genies", "daemon", "--through", "deliver"]);

    // Assert
    expect(runDaemonCycle).toHaveBeenCalledWith(
      expect.objectContaining({ throughPhase: "deliver" }),
    );
  });

  it("--finish sets finish mode", async () => {
    // Arrange
    const cli = createCli();

    // Act
    await cli.parseAsync(["node", "genies", "daemon", "--finish", "merge"]);

    // Assert
    expect(runDaemonCycle).toHaveBeenCalledWith(
      expect.objectContaining({ finishMode: "merge" }),
    );
  });

  it("--parallel sets concurrency", async () => {
    // Arrange
    const cli = createCli();

    // Act
    await cli.parseAsync(["node", "genies", "daemon", "--parallel", "4"]);

    // Assert
    expect(runDaemonCycle).toHaveBeenCalledWith(
      expect.objectContaining({ parallel: 4 }),
    );
  });

  it("--priority filters by priority", async () => {
    // Arrange
    const cli = createCli();

    // Act
    await cli.parseAsync(["node", "genies", "daemon", "--priority", "P0"]);

    // Assert
    expect(runDaemonCycle).toHaveBeenCalledWith(
      expect.objectContaining({ priorities: ["P0"] }),
    );
  });

  it("--model passes through", async () => {
    // Arrange
    const cli = createCli();

    // Act
    await cli.parseAsync(["node", "genies", "daemon", "--model", "claude-opus-4-6"]);

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
      "node", "genies", "daemon",
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
    await cli.parseAsync(["node", "genies", "daemon"]);

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
    await cli.parseAsync(["node", "genies", "session", "list"]);

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
    await cli.parseAsync(["node", "genies", "session", "list"]);

    // Assert
    const output = vi.mocked(console.log).mock.calls.map((c) => c[0]).join("\n");
    expect(output).toContain("No active");
  });

  it("session cleanup calls sessionCleanup with item slug", async () => {
    // Arrange
    vi.mocked(sessionCleanup).mockResolvedValue();
    const cli = createCli();

    // Act
    await cli.parseAsync(["node", "genies", "session", "cleanup", "P0-auth"]);

    // Assert
    expect(sessionCleanup).toHaveBeenCalledWith("P0-auth");
  });

  it("session cleanup without item or --all exits with code 3", async () => {
    // Arrange
    vi.spyOn(console, "error").mockImplementation(() => {});
    const cli = createCli();

    // Act
    await cli.parseAsync(["node", "genies", "session", "cleanup"]);

    // Assert
    expect(process.exit).toHaveBeenCalledWith(3);
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
    await cli.parseAsync(["node", "genies", "session", "cleanup", "--all"]);

    // Assert
    expect(sessionCleanup).toHaveBeenCalledWith("P0-auth");
    expect(sessionCleanup).toHaveBeenCalledWith("P1-search");
    expect(sessionCleanup).toHaveBeenCalledTimes(2);
  });
});

function mockStatusReport(overrides?: Partial<StatusReport>): StatusReport {
  return {
    items: [
      { slug: "P1-auth", phase: "deliver", status: "done", durationSecs: 120, logFile: "/tmp/P1-auth.log" },
    ],
    summary: { total: 1, done: 1, running: 0, stuck: 0, failed: 0 },
    exitCode: 0,
    ...overrides,
  };
}

describe("status command", () => {
  beforeEach(() => {
    vi.resetAllMocks();
    vi.spyOn(process, "exit").mockImplementation(() => undefined as never);
    vi.spyOn(console, "log").mockImplementation(() => {});
  });

  it("registers status subcommand", () => {
    // Arrange
    const cli = createCli();

    // Act
    const cmd = cli.commands.find((c) => c.name() === "status");

    // Assert
    expect(cmd).toBeDefined();
  });

  it("calls readBatchStatus with --log-dir", async () => {
    // Arrange
    vi.mocked(readBatchStatus).mockResolvedValue(mockStatusReport());
    vi.mocked(formatStatusTable).mockReturnValue("table output");
    const cli = createCli();

    // Act
    await cli.parseAsync(["node", "genies", "status", "--log-dir", "/tmp/logs"]);

    // Assert
    expect(readBatchStatus).toHaveBeenCalledWith("/tmp/logs", expect.any(Object));
  });

  it("falls back to LOG_DIR env var when --log-dir not provided", async () => {
    // Arrange
    const origEnv = process.env.LOG_DIR;
    process.env.LOG_DIR = "/tmp/env-logs";
    vi.mocked(readBatchStatus).mockResolvedValue(mockStatusReport());
    vi.mocked(formatStatusTable).mockReturnValue("table output");
    const cli = createCli();

    // Act
    await cli.parseAsync(["node", "genies", "status"]);

    // Assert
    expect(readBatchStatus).toHaveBeenCalledWith("/tmp/env-logs", expect.any(Object));
    process.env.LOG_DIR = origEnv;
  });

  it("passes --stuck-mins to readBatchStatus", async () => {
    // Arrange
    vi.mocked(readBatchStatus).mockResolvedValue(mockStatusReport());
    vi.mocked(formatStatusTable).mockReturnValue("table output");
    const cli = createCli();

    // Act
    await cli.parseAsync(["node", "genies", "status", "--log-dir", "/tmp/logs", "--stuck-mins", "20"]);

    // Assert
    expect(readBatchStatus).toHaveBeenCalledWith("/tmp/logs", { stuckMins: 20 });
  });

  it("outputs table format by default", async () => {
    // Arrange
    vi.mocked(readBatchStatus).mockResolvedValue(mockStatusReport());
    vi.mocked(formatStatusTable).mockReturnValue("TABLE OUTPUT");
    const cli = createCli();

    // Act
    await cli.parseAsync(["node", "genies", "status", "--log-dir", "/tmp/logs"]);

    // Assert
    expect(formatStatusTable).toHaveBeenCalled();
    expect(formatStatusJson).not.toHaveBeenCalled();
    const output = vi.mocked(console.log).mock.calls.map((c) => c[0]).join("\n");
    expect(output).toContain("TABLE OUTPUT");
  });

  it("outputs JSON format with --json", async () => {
    // Arrange
    vi.mocked(readBatchStatus).mockResolvedValue(mockStatusReport());
    vi.mocked(formatStatusJson).mockReturnValue('{"json": true}');
    const cli = createCli();

    // Act
    await cli.parseAsync(["node", "genies", "status", "--log-dir", "/tmp/logs", "--json"]);

    // Assert
    expect(formatStatusJson).toHaveBeenCalled();
    expect(formatStatusTable).not.toHaveBeenCalled();
    const output = vi.mocked(console.log).mock.calls.map((c) => c[0]).join("\n");
    expect(output).toContain('{"json": true}');
  });

  it("exits with report exit code", async () => {
    // Arrange
    vi.mocked(readBatchStatus).mockResolvedValue(mockStatusReport({ exitCode: 2 }));
    vi.mocked(formatStatusTable).mockReturnValue("table");
    const cli = createCli();

    // Act
    await cli.parseAsync(["node", "genies", "status", "--log-dir", "/tmp/logs"]);

    // Assert
    expect(process.exit).toHaveBeenCalledWith(2);
  });

  it("exits 3 when no --log-dir and no LOG_DIR env", async () => {
    // Arrange
    const origEnv = process.env.LOG_DIR;
    delete process.env.LOG_DIR;
    vi.spyOn(console, "error").mockImplementation(() => {});
    const cli = createCli();

    // Act
    await cli.parseAsync(["node", "genies", "status"]);

    // Assert
    expect(process.exit).toHaveBeenCalledWith(3);
    process.env.LOG_DIR = origEnv;
  });
});

function mockDaemonStatus(overrides?: Partial<DaemonStatus>): DaemonStatus {
  return {
    daemon_pid: 1234,
    started_at: "2026-04-07T00:00:00Z",
    current_cycle: 5,
    last_cycle_at: "2026-04-07T00:25:00Z",
    cumulative_cost_usd: 2.50,
    status: "sleeping",
    next_scan_at: "2026-04-07T00:30:00Z",
    items_completed: ["P1-auth"],
    items_failed: [],
    items_stalled: [],
    totals: { completed: 1, failed: 0, stalled: 0, finisher_recovered: 0 },
    ...overrides,
  };
}

describe("daemon start subcommand", () => {
  beforeEach(() => {
    vi.resetAllMocks();
    vi.mocked(runDaemon).mockResolvedValue();
    vi.spyOn(process, "exit").mockImplementation(() => undefined as never);
    vi.spyOn(console, "log").mockImplementation(() => {});
  });

  it("registers daemon start subcommand", () => {
    // Arrange
    const cli = createCli();

    // Act
    const daemonCmd = cli.commands.find((c) => c.name() === "daemon");
    const startCmd = daemonCmd?.commands.find((c) => c.name() === "start");

    // Assert
    expect(startCmd).toBeDefined();
  });

  it("calls runDaemon with defaults", async () => {
    // Arrange
    const cli = createCli();

    // Act
    await cli.parseAsync(["node", "genies", "daemon", "start"]);

    // Assert
    expect(runDaemon).toHaveBeenCalledWith(
      expect.objectContaining({
        throughPhase: "done",
        finishMode: "pr",
      }),
    );
  });

  it("--interval sets interval", async () => {
    // Arrange
    const cli = createCli();

    // Act
    await cli.parseAsync(["node", "genies", "daemon", "start", "--interval", "60"]);

    // Assert
    expect(runDaemon).toHaveBeenCalledWith(
      expect.objectContaining({ interval: 60 }),
    );
  });

  it("--max-cycles sets maxCycles", async () => {
    // Arrange
    const cli = createCli();

    // Act
    await cli.parseAsync(["node", "genies", "daemon", "start", "--max-cycles", "10"]);

    // Assert
    expect(runDaemon).toHaveBeenCalledWith(
      expect.objectContaining({ maxCycles: 10 }),
    );
  });

  it("--max-cost sets maxCostUsd", async () => {
    // Arrange
    const cli = createCli();

    // Act
    await cli.parseAsync(["node", "genies", "daemon", "start", "--max-cost", "50.00"]);

    // Assert
    expect(runDaemon).toHaveBeenCalledWith(
      expect.objectContaining({ maxCostUsd: 50.0 }),
    );
  });

  it("--status-file sets statusFile", async () => {
    // Arrange
    const cli = createCli();

    // Act
    await cli.parseAsync(["node", "genies", "daemon", "start", "--status-file", "/tmp/daemon.json"]);

    // Assert
    expect(runDaemon).toHaveBeenCalledWith(
      expect.objectContaining({ statusFile: "/tmp/daemon.json" }),
    );
  });
});

describe("daemon stop subcommand", () => {
  beforeEach(() => {
    vi.resetAllMocks();
    vi.mocked(stopDaemon).mockResolvedValue();
    vi.spyOn(process, "exit").mockImplementation(() => undefined as never);
    vi.spyOn(console, "log").mockImplementation(() => {});
  });

  it("registers daemon stop subcommand", () => {
    // Arrange
    const cli = createCli();

    // Act
    const daemonCmd = cli.commands.find((c) => c.name() === "daemon");
    const stopCmd = daemonCmd?.commands.find((c) => c.name() === "stop");

    // Assert
    expect(stopCmd).toBeDefined();
  });

  it("calls stopDaemon with status file", async () => {
    // Arrange
    const cli = createCli();

    // Act
    await cli.parseAsync(["node", "genies", "daemon", "stop", "--status-file", "/tmp/daemon.json"]);

    // Assert
    expect(stopDaemon).toHaveBeenCalledWith("/tmp/daemon.json");
  });
});

describe("daemon status subcommand", () => {
  beforeEach(() => {
    vi.resetAllMocks();
    vi.spyOn(process, "exit").mockImplementation(() => undefined as never);
    vi.spyOn(console, "log").mockImplementation(() => {});
  });

  it("registers daemon status subcommand", () => {
    // Arrange
    const cli = createCli();

    // Act
    const daemonCmd = cli.commands.find((c) => c.name() === "daemon");
    const statusCmd = daemonCmd?.commands.find((c) => c.name() === "status");

    // Assert
    expect(statusCmd).toBeDefined();
  });

  it("displays daemon status from status file", async () => {
    // Arrange
    vi.mocked(readDaemonStatus).mockReturnValue(mockDaemonStatus());
    const cli = createCli();

    // Act
    await cli.parseAsync(["node", "genies", "daemon", "status", "--status-file", "/tmp/daemon.json"]);

    // Assert
    expect(readDaemonStatus).toHaveBeenCalledWith("/tmp/daemon.json");
    const output = vi.mocked(console.log).mock.calls.map((c) => c[0]).join("\n");
    expect(output).toContain("sleeping");
  });

  it("reports when no daemon is running", async () => {
    // Arrange
    vi.mocked(readDaemonStatus).mockReturnValue(undefined);
    const cli = createCli();

    // Act
    await cli.parseAsync(["node", "genies", "daemon", "status", "--status-file", "/tmp/daemon.json"]);

    // Assert
    const output = vi.mocked(console.log).mock.calls.map((c) => c[0]).join("\n");
    expect(output).toContain("No daemon");
  });
});

describe("daemon backward compatibility", () => {
  beforeEach(() => {
    vi.resetAllMocks();
    vi.mocked(runDaemonCycle).mockResolvedValue(mockDaemonResult());
    vi.spyOn(process, "exit").mockImplementation(() => undefined as never);
    vi.spyOn(console, "log").mockImplementation(() => {});
  });

  it("daemon with no subcommand still runs one-shot cycle", async () => {
    // Arrange
    const cli = createCli();

    // Act
    await cli.parseAsync(["node", "genies", "daemon"]);

    // Assert
    expect(runDaemonCycle).toHaveBeenCalled();
  });
});
