import { describe, it, expect, vi, beforeEach } from "vitest";
import {
  runDaemonCycle,
  type DaemonOptions,
  type DaemonCycleResult,
} from "./daemon.js";

vi.mock("./batch-executor.js", () => ({
  executeBatch: vi.fn(),
}));

vi.mock("./item-resolver.js", () => ({
  resolveItems: vi.fn(),
}));

import { executeBatch } from "./batch-executor.js";
import { resolveItems } from "./item-resolver.js";

describe("runDaemonCycle", () => {
  beforeEach(() => {
    vi.resetAllMocks();
  });

  it("resolves items and executes batch", async () => {
    // Arrange
    vi.mocked(resolveItems).mockResolvedValue([
      { slug: "P1-auth", input: "docs/backlog/P1-auth.md", phase: "deliver" as const },
    ]);
    vi.mocked(executeBatch).mockResolvedValue({
      succeeded: [{ slug: "P1-auth", input: "docs/backlog/P1-auth.md", exitCode: 0, costUsd: 0.05 }],
      failed: [],
      conflicts: [],
      totalCostUsd: 0.05,
      exitCode: 0,
    });

    // Act
    const result = await runDaemonCycle({
      throughPhase: "discern",
      finishMode: "pr",
    });

    // Assert
    expect(result.itemsCompleted).toBe(1);
    expect(result.costUsd).toBeCloseTo(0.05);
  });

  it("returns zero items when nothing to do", async () => {
    // Arrange
    vi.mocked(resolveItems).mockResolvedValue([]);

    // Act
    const result = await runDaemonCycle({
      throughPhase: "discern",
      finishMode: "pr",
    });

    // Assert
    expect(result.itemsCompleted).toBe(0);
    expect(result.costUsd).toBe(0);
  });

  it("reports failures from batch", async () => {
    // Arrange
    vi.mocked(resolveItems).mockResolvedValue([
      { slug: "P1-fail", input: "docs/backlog/P1-fail.md", phase: "deliver" as const },
    ]);
    vi.mocked(executeBatch).mockResolvedValue({
      succeeded: [],
      failed: [{ slug: "P1-fail", input: "docs/backlog/P1-fail.md", exitCode: 1, costUsd: 0.02 }],
      conflicts: [],
      totalCostUsd: 0.02,
      exitCode: 1,
    });

    // Act
    const result = await runDaemonCycle({
      throughPhase: "discern",
      finishMode: "pr",
    });

    // Assert
    expect(result.itemsFailed).toBe(1);
    expect(result.exitCode).toBe(1);
  });
});
