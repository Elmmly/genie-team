import { describe, it, expect, vi, beforeEach } from "vitest";
import {
  executeBatch,
  type BatchItem,
  type BatchOptions,
  type BatchResult,
} from "./batch-executor.js";

// Mock dependencies
vi.mock("./single-item.js", () => ({
  executeSingleItem: vi.fn(),
}));
vi.mock("../git/worktree.js", () => ({
  sessionStart: vi.fn(),
  sessionCleanup: vi.fn(),
  integratePr: vi.fn(),
  integrateTrunk: vi.fn(),
}));

import { executeSingleItem } from "./single-item.js";
import {
  sessionStart,
  sessionCleanup,
  integratePr,
  integrateTrunk,
} from "../git/worktree.js";

function makeItem(slug: string, phase = "deliver"): BatchItem {
  return { slug, input: `docs/backlog/${slug}.md`, phase: phase as "deliver" };
}

describe("executeBatch", () => {
  beforeEach(() => {
    vi.resetAllMocks();
    vi.mocked(sessionStart).mockResolvedValue("/tmp/worktree");
    vi.mocked(sessionCleanup).mockResolvedValue(undefined);
    vi.mocked(integratePr).mockResolvedValue({ exitCode: 0, prUrl: "https://github.com/pr/1" });
    vi.mocked(integrateTrunk).mockResolvedValue({ exitCode: 0 });
    vi.mocked(executeSingleItem).mockResolvedValue({
      exitCode: 0,
      totalCostUsd: 0.05,
      phaseResults: [],
    });
  });

  it("executes all items and returns results", async () => {
    // Arrange
    const items: BatchItem[] = [makeItem("P1-auth"), makeItem("P2-search")];

    // Act
    const result = await executeBatch(items, {
      throughPhase: "discern",
      finishMode: "pr",
    });

    // Assert
    expect(result.succeeded).toHaveLength(2);
    expect(result.failed).toHaveLength(0);
    expect(result.exitCode).toBe(0);
  });

  it("collects failed items without stopping", async () => {
    // Arrange
    vi.mocked(executeSingleItem)
      .mockResolvedValueOnce({ exitCode: 0, totalCostUsd: 0.01, phaseResults: [] })
      .mockResolvedValueOnce({ exitCode: 1, totalCostUsd: 0.02, phaseResults: [] })
      .mockResolvedValueOnce({ exitCode: 0, totalCostUsd: 0.01, phaseResults: [] });

    const items = [makeItem("P1-a"), makeItem("P1-b"), makeItem("P1-c")];

    // Act
    const result = await executeBatch(items, {
      throughPhase: "discern",
      finishMode: "pr",
      continueOnFailure: true,
    });

    // Assert
    expect(result.succeeded).toHaveLength(2);
    expect(result.failed).toHaveLength(1);
    expect(result.failed[0].slug).toBe("P1-b");
    expect(result.exitCode).toBe(1);
  });

  it("stops on first failure when continueOnFailure is false", async () => {
    // Arrange
    vi.mocked(executeSingleItem)
      .mockResolvedValueOnce({ exitCode: 0, totalCostUsd: 0.01, phaseResults: [] })
      .mockResolvedValueOnce({ exitCode: 1, totalCostUsd: 0.02, phaseResults: [] })
      .mockResolvedValueOnce({ exitCode: 0, totalCostUsd: 0.01, phaseResults: [] });

    const items = [makeItem("P1-a"), makeItem("P1-b"), makeItem("P1-c")];

    // Act
    const result = await executeBatch(items, {
      throughPhase: "discern",
      finishMode: "pr",
      continueOnFailure: false,
    });

    // Assert — should not reach P1-c
    expect(result.succeeded).toHaveLength(1);
    expect(result.failed).toHaveLength(1);
    expect(vi.mocked(executeSingleItem)).toHaveBeenCalledTimes(2);
  });

  it("respects parallel concurrency limit", async () => {
    // Arrange
    let concurrent = 0;
    let maxConcurrent = 0;

    vi.mocked(executeSingleItem).mockImplementation(async () => {
      concurrent++;
      maxConcurrent = Math.max(maxConcurrent, concurrent);
      await new Promise((r) => setTimeout(r, 10));
      concurrent--;
      return { exitCode: 0, totalCostUsd: 0.01, phaseResults: [] };
    });

    const items = [makeItem("P1-a"), makeItem("P1-b"), makeItem("P1-c"), makeItem("P1-d")];

    // Act
    await executeBatch(items, {
      throughPhase: "discern",
      finishMode: "pr",
      parallel: 2,
    });

    // Assert — should never exceed 2 concurrent
    expect(maxConcurrent).toBeLessThanOrEqual(2);
  });

  it("accumulates total cost", async () => {
    // Arrange
    vi.mocked(executeSingleItem)
      .mockResolvedValueOnce({ exitCode: 0, totalCostUsd: 0.10, phaseResults: [] })
      .mockResolvedValueOnce({ exitCode: 0, totalCostUsd: 0.20, phaseResults: [] });

    const items = [makeItem("P1-a"), makeItem("P1-b")];

    // Act
    const result = await executeBatch(items, {
      throughPhase: "discern",
      finishMode: "pr",
    });

    // Assert
    expect(result.totalCostUsd).toBeCloseTo(0.30);
  });

  it("integrates via trunk when finishMode is merge", async () => {
    // Arrange
    const items = [makeItem("P1-a")];

    // Act
    await executeBatch(items, {
      throughPhase: "discern",
      finishMode: "merge",
      trunkMode: true,
    });

    // Assert
    expect(integrateTrunk).toHaveBeenCalledWith("P1-a");
  });

  it("skips integration when finishMode is leave-branch", async () => {
    // Arrange
    const items = [makeItem("P1-a")];

    // Act
    await executeBatch(items, {
      throughPhase: "discern",
      finishMode: "leave-branch",
    });

    // Assert
    expect(integratePr).not.toHaveBeenCalled();
    expect(integrateTrunk).not.toHaveBeenCalled();
  });

  it("cleans up worktree on item failure", async () => {
    // Arrange
    vi.mocked(executeSingleItem).mockResolvedValue({
      exitCode: 1,
      totalCostUsd: 0.01,
      phaseResults: [],
    });

    const items = [makeItem("P1-fail")];

    // Act
    await executeBatch(items, {
      throughPhase: "discern",
      finishMode: "pr",
    });

    // Assert
    expect(sessionCleanup).toHaveBeenCalledWith("P1-fail");
  });

  it("threads authMode to executeSingleItem", async () => {
    // Arrange
    const items = [makeItem("P1-auth")];

    // Act
    await executeBatch(items, {
      throughPhase: "discern",
      finishMode: "pr",
      authMode: "oauth",
    });

    // Assert
    expect(executeSingleItem).toHaveBeenCalledWith(
      expect.any(String),
      expect.objectContaining({ authMode: "oauth" }),
    );
  });

  it("passes worktree path as cwd to executeSingleItem", async () => {
    // Arrange
    vi.mocked(sessionStart).mockResolvedValue("/tmp/worktree--P1-auth");
    const items = [makeItem("P1-auth")];

    // Act
    await executeBatch(items, {
      throughPhase: "discern",
      finishMode: "pr",
    });

    // Assert
    expect(executeSingleItem).toHaveBeenCalledWith(
      expect.any(String),
      expect.objectContaining({ cwd: "/tmp/worktree--P1-auth" }),
    );
  });

  it("threads reviewCycles to executeSingleItem", async () => {
    // Arrange
    const items = [makeItem("P1-item")];

    // Act
    await executeBatch(items, {
      throughPhase: "discern",
      finishMode: "pr",
      reviewCycles: 3,
    });

    // Assert
    expect(executeSingleItem).toHaveBeenCalledWith(
      expect.any(String),
      expect.objectContaining({ reviewCycles: 3 }),
    );
  });

  it("threads turnOverrides to executeSingleItem", async () => {
    // Arrange
    const items = [makeItem("P1-item")];

    // Act
    await executeBatch(items, {
      throughPhase: "discern",
      finishMode: "pr",
      turnOverrides: { global: 200 },
    });

    // Assert
    expect(executeSingleItem).toHaveBeenCalledWith(
      expect.any(String),
      expect.objectContaining({ turnOverrides: { global: 200 } }),
    );
  });
});
