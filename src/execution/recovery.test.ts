import { describe, it, expect, vi, beforeEach } from "vitest";
import { runRecovery, type RecoveryOptions, type RecoveryResult } from "./recovery.js";
import * as worktree from "../git/worktree.js";

vi.mock("../git/worktree.js");

const mockWorktree = vi.mocked(worktree);

describe("runRecovery", () => {
  beforeEach(() => {
    vi.resetAllMocks();
  });

  it("returns empty result when no genie/* branches exist", async () => {
    // Arrange
    mockWorktree.listSessions.mockResolvedValue([]);

    // Act
    const result = await runRecovery({
      branches: [],
      finishMode: "pr",
      trunkMode: false,
    });

    // Assert
    expect(result.recovered).toEqual([]);
    expect(result.failed).toEqual([]);
  });

  it("recovers orphaned branches by creating PRs", async () => {
    // Arrange
    mockWorktree.listSessions.mockResolvedValue([]);
    mockWorktree.integratePr.mockResolvedValue({ prUrl: "https://github.com/pr/1", exitCode: 0 });

    // Act
    const result = await runRecovery({
      branches: ["P1-auth-deliver"],
      finishMode: "pr",
      trunkMode: false,
    });

    // Assert
    expect(result.recovered).toEqual(["P1-auth-deliver"]);
    expect(result.failed).toEqual([]);
    expect(mockWorktree.integratePr).toHaveBeenCalledWith("P1-auth-deliver");
  });

  it("skips branches that have active worktrees", async () => {
    // Arrange
    mockWorktree.listSessions.mockResolvedValue([
      { path: "/worktrees/repo--P1-auth", branch: "genie/P1-auth-deliver", slug: "P1-auth" },
    ]);
    mockWorktree.integratePr.mockResolvedValue({ prUrl: "https://github.com/pr/1", exitCode: 0 });

    // Act
    const result = await runRecovery({
      branches: ["P1-auth-deliver", "P2-search-design"],
      finishMode: "pr",
      trunkMode: false,
    });

    // Assert
    expect(result.recovered).toEqual(["P2-search-design"]);
    expect(result.failed).toEqual([]);
    // P1-auth-deliver should be skipped — it has an active worktree
    expect(mockWorktree.integratePr).toHaveBeenCalledTimes(1);
    expect(mockWorktree.integratePr).toHaveBeenCalledWith("P2-search-design");
  });

  it("reports failures for branches that cannot be integrated", async () => {
    // Arrange
    mockWorktree.listSessions.mockResolvedValue([]);
    mockWorktree.integratePr.mockResolvedValue({ exitCode: 1 });

    // Act
    const result = await runRecovery({
      branches: ["P1-auth-deliver"],
      finishMode: "pr",
      trunkMode: false,
    });

    // Assert
    expect(result.recovered).toEqual([]);
    expect(result.failed).toEqual(["P1-auth-deliver"]);
  });

  it("uses trunk integration when trunkMode is true", async () => {
    // Arrange
    mockWorktree.listSessions.mockResolvedValue([]);
    mockWorktree.integrateTrunk.mockResolvedValue({ exitCode: 0 });

    // Act
    const result = await runRecovery({
      branches: ["P1-auth-deliver"],
      finishMode: "merge",
      trunkMode: true,
    });

    // Assert
    expect(result.recovered).toEqual(["P1-auth-deliver"]);
    expect(mockWorktree.integrateTrunk).toHaveBeenCalledWith("P1-auth-deliver");
  });

  it("filters branches by priority when provided", async () => {
    // Arrange
    mockWorktree.listSessions.mockResolvedValue([]);
    mockWorktree.integratePr.mockResolvedValue({ prUrl: "https://github.com/pr/1", exitCode: 0 });

    // Act
    const result = await runRecovery({
      branches: ["P0-critical-deliver", "P1-auth-deliver", "P2-search-design"],
      finishMode: "pr",
      trunkMode: false,
      priorities: ["P1"],
    });

    // Assert
    expect(result.recovered).toEqual(["P1-auth-deliver"]);
    expect(mockWorktree.integratePr).toHaveBeenCalledTimes(1);
  });

  it("handles mix of recovered and failed branches", async () => {
    // Arrange
    mockWorktree.listSessions.mockResolvedValue([]);
    mockWorktree.integratePr
      .mockResolvedValueOnce({ prUrl: "https://github.com/pr/1", exitCode: 0 })
      .mockResolvedValueOnce({ exitCode: 1 });

    // Act
    const result = await runRecovery({
      branches: ["P1-auth-deliver", "P2-search-design"],
      finishMode: "pr",
      trunkMode: false,
    });

    // Assert
    expect(result.recovered).toEqual(["P1-auth-deliver"]);
    expect(result.failed).toEqual(["P2-search-design"]);
  });
});
