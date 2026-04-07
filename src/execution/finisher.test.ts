import { describe, it, expect, vi, beforeEach } from "vitest";
import { finisherStateToPhases, runFinisher, type FinisherOptions } from "./finisher.js";

vi.mock("execa", () => ({
  execa: vi.fn(),
}));

vi.mock("node:fs", async (importOriginal) => {
  const actual = await importOriginal<typeof import("node:fs")>();
  return {
    ...actual,
    existsSync: vi.fn(() => true),
  };
});

vi.mock("../core/phase-executor.js", () => ({
  runPhase: vi.fn(),
}));

vi.mock("../core/frontmatter.js", () => ({
  getFrontmatterField: vi.fn(),
}));

vi.mock("../git/worktree.js", () => ({
  repoRoot: vi.fn(),
  sessionStart: vi.fn(),
  sessionCleanup: vi.fn(),
  integratePr: vi.fn(),
  integrateTrunk: vi.fn(),
  listSessions: vi.fn(),
}));

import { execa } from "execa";
import { existsSync } from "node:fs";
import { runPhase } from "../core/phase-executor.js";
import { getFrontmatterField } from "../core/frontmatter.js";
import {
  repoRoot,
  sessionStart,
  sessionCleanup,
  integratePr,
  integrateTrunk,
  listSessions,
} from "../git/worktree.js";

describe("finisherStateToPhases", () => {
  it("implemented + uncommitted → commit, discern, commit, done", () => {
    expect(finisherStateToPhases("implemented", "", true)).toEqual(["commit", "discern", "commit", "done"]);
  });

  it("implemented + clean → discern, commit, done", () => {
    expect(finisherStateToPhases("implemented", "", false)).toEqual(["discern", "commit", "done"]);
  });

  it("reviewed + APPROVED + uncommitted → commit, done", () => {
    expect(finisherStateToPhases("reviewed", "APPROVED", true)).toEqual(["commit", "done"]);
  });

  it("reviewed + APPROVED + clean → done", () => {
    expect(finisherStateToPhases("reviewed", "APPROVED", false)).toEqual(["done"]);
  });

  it("reviewed + CHANGES_REQUESTED → deliver, discern", () => {
    expect(finisherStateToPhases("reviewed", "CHANGES_REQUESTED", false)).toEqual(["deliver", "discern"]);
  });

  it("reviewed + CHANGES_REQUESTED + uncommitted still returns deliver, discern", () => {
    expect(finisherStateToPhases("reviewed", "CHANGES_REQUESTED", true)).toEqual(["deliver", "discern"]);
  });

  it("designed → deliver, discern, commit, done", () => {
    expect(finisherStateToPhases("designed", "", false)).toEqual(["deliver", "discern", "commit", "done"]);
  });

  it("other status + uncommitted → commit", () => {
    expect(finisherStateToPhases("discovered", "", true)).toEqual(["commit"]);
  });

  it("other status + clean → empty", () => {
    expect(finisherStateToPhases("discovered", "", false)).toEqual([]);
  });

  it("edge: empty status + uncommitted → commit", () => {
    expect(finisherStateToPhases("", "", true)).toEqual(["commit"]);
  });

  it("edge: reviewed + unknown verdict + uncommitted → commit", () => {
    expect(finisherStateToPhases("reviewed", "UNKNOWN", true)).toEqual(["commit"]);
  });

  it("edge: reviewed + unknown verdict + clean → empty", () => {
    expect(finisherStateToPhases("reviewed", "UNKNOWN", false)).toEqual([]);
  });
});

describe("runFinisher", () => {
  const baseOpts: FinisherOptions = {
    throughPhase: "done",
    finishMode: "pr",
  };

  beforeEach(() => {
    vi.resetAllMocks();
    vi.mocked(repoRoot).mockResolvedValue("/repo");
    vi.mocked(listSessions).mockResolvedValue([]);
  });

  it("returns empty result when no genie/* branches exist", async () => {
    // Arrange
    vi.mocked(execa).mockResolvedValue({ stdout: "" } as never);

    // Act
    const result = await runFinisher(baseOpts);

    // Assert
    expect(result.recovered).toBe(0);
    expect(result.stalled).toEqual([]);
  });

  it("recovers a branch with designed status via PR", async () => {
    // Arrange — one genie branch, backlog item at "designed" status
    (vi.mocked(execa) as any).mockImplementation(async (cmd: string, args?: string[]) => {
      if (cmd === "git" && args?.[0] === "branch") {
        return { stdout: "genie/P1-auth-deliver" } as never;
      }
      if (cmd === "git" && args?.[0] === "status") {
        return { stdout: "" } as never; // clean working tree
      }
      return { stdout: "" } as never;
    });
    vi.mocked(sessionStart).mockResolvedValue("/repo--P1-auth");
    vi.mocked(sessionCleanup).mockResolvedValue();
    vi.mocked(getFrontmatterField).mockImplementation(async (_path: string, field: string) => {
      if (field === "status") return "designed";
      if (field === "verdict") return undefined;
      return undefined;
    });
    vi.mocked(runPhase).mockResolvedValue({
      output: "Phase complete",
      sessionId: "s1",
      inputTokens: 100,
      outputTokens: 50,
      costUsd: 0.01,
      numTurns: 5,
      exhausted: false,
    });
    vi.mocked(integratePr).mockResolvedValue({ exitCode: 0, prUrl: "https://github.com/pr/1" });

    // Act
    const result = await runFinisher(baseOpts);

    // Assert
    expect(result.recovered).toBe(1);
    expect(result.stalled).toEqual([]);
    // Should have run deliver, discern, commit, done
    expect(runPhase).toHaveBeenCalledTimes(4);
    expect(integratePr).toHaveBeenCalledWith("P1-auth-deliver");
  });

  it("uses trunk integration when finishMode is merge", async () => {
    // Arrange
    (vi.mocked(execa) as any).mockImplementation(async (cmd: string, args?: string[]) => {
      if (cmd === "git" && args?.[0] === "branch") {
        return { stdout: "genie/P1-auth-deliver" } as never;
      }
      if (cmd === "git" && args?.[0] === "status") {
        return { stdout: "" } as never;
      }
      return { stdout: "" } as never;
    });
    vi.mocked(sessionStart).mockResolvedValue("/repo--P1-auth");
    vi.mocked(sessionCleanup).mockResolvedValue();
    vi.mocked(getFrontmatterField).mockImplementation(async (_path: string, field: string) => {
      if (field === "status") return "reviewed";
      if (field === "verdict") return "APPROVED";
      return undefined;
    });
    vi.mocked(runPhase).mockResolvedValue({
      output: "Done",
      sessionId: "s1",
      inputTokens: 100,
      outputTokens: 50,
      costUsd: 0.01,
      numTurns: 5,
      exhausted: false,
    });
    vi.mocked(integrateTrunk).mockResolvedValue({ exitCode: 0 });

    // Act
    const result = await runFinisher({ ...baseOpts, finishMode: "merge" });

    // Assert
    expect(integrateTrunk).toHaveBeenCalledWith("P1-auth-deliver");
    expect(integratePr).not.toHaveBeenCalled();
    expect(result.recovered).toBe(1);
  });

  it("reports stalled when phase execution fails", async () => {
    // Arrange
    (vi.mocked(execa) as any).mockImplementation(async (cmd: string, args?: string[]) => {
      if (cmd === "git" && args?.[0] === "branch") {
        return { stdout: "genie/P1-auth-deliver" } as never;
      }
      if (cmd === "git" && args?.[0] === "status") {
        return { stdout: "" } as never;
      }
      return { stdout: "" } as never;
    });
    vi.mocked(sessionStart).mockResolvedValue("/repo--P1-auth");
    vi.mocked(sessionCleanup).mockResolvedValue();
    vi.mocked(getFrontmatterField).mockImplementation(async (_path: string, field: string) => {
      if (field === "status") return "designed";
      return undefined;
    });
    vi.mocked(runPhase).mockRejectedValue(new Error("Phase failed"));

    // Act
    const result = await runFinisher(baseOpts);

    // Assert
    expect(result.recovered).toBe(0);
    expect(result.stalled).toContain("P1-auth-deliver");
  });

  it("reports stalled when integration fails", async () => {
    // Arrange
    (vi.mocked(execa) as any).mockImplementation(async (cmd: string, args?: string[]) => {
      if (cmd === "git" && args?.[0] === "branch") {
        return { stdout: "genie/P1-auth-deliver" } as never;
      }
      if (cmd === "git" && args?.[0] === "status") {
        return { stdout: "" } as never;
      }
      return { stdout: "" } as never;
    });
    vi.mocked(sessionStart).mockResolvedValue("/repo--P1-auth");
    vi.mocked(sessionCleanup).mockResolvedValue();
    vi.mocked(getFrontmatterField).mockImplementation(async (_path: string, field: string) => {
      if (field === "status") return "reviewed";
      if (field === "verdict") return "APPROVED";
      return undefined;
    });
    vi.mocked(runPhase).mockResolvedValue({
      output: "Done",
      sessionId: "s1",
      inputTokens: 100,
      outputTokens: 50,
      costUsd: 0.01,
      numTurns: 5,
      exhausted: false,
    });
    vi.mocked(integratePr).mockResolvedValue({ exitCode: 1 });

    // Act
    const result = await runFinisher(baseOpts);

    // Assert
    expect(result.recovered).toBe(0);
    expect(result.stalled).toContain("P1-auth-deliver");
  });

  it("skips branches with no remaining phases", async () => {
    // Arrange — branch with unknown status and clean working tree → no phases
    (vi.mocked(execa) as any).mockImplementation(async (cmd: string, args?: string[]) => {
      if (cmd === "git" && args?.[0] === "branch") {
        return { stdout: "genie/P1-auth-deliver" } as never;
      }
      if (cmd === "git" && args?.[0] === "status") {
        return { stdout: "" } as never;
      }
      return { stdout: "" } as never;
    });
    vi.mocked(sessionStart).mockResolvedValue("/repo--P1-auth");
    vi.mocked(sessionCleanup).mockResolvedValue();
    vi.mocked(getFrontmatterField).mockResolvedValue("done");

    // Act
    const result = await runFinisher(baseOpts);

    // Assert
    expect(runPhase).not.toHaveBeenCalled();
    expect(result.recovered).toBe(0);
    expect(result.stalled).toEqual([]);
  });

  it("handles multiple branches", async () => {
    // Arrange — two branches
    (vi.mocked(execa) as any).mockImplementation(async (cmd: string, args?: string[]) => {
      if (cmd === "git" && args?.[0] === "branch") {
        return { stdout: "genie/P1-auth-deliver\ngenie/P2-search-design" } as never;
      }
      if (cmd === "git" && args?.[0] === "status") {
        return { stdout: "" } as never;
      }
      return { stdout: "" } as never;
    });
    vi.mocked(sessionStart).mockResolvedValue("/repo--item");
    vi.mocked(sessionCleanup).mockResolvedValue();
    vi.mocked(getFrontmatterField).mockImplementation(async (_path: string, field: string) => {
      if (field === "status") return "reviewed";
      if (field === "verdict") return "APPROVED";
      return undefined;
    });
    vi.mocked(runPhase).mockResolvedValue({
      output: "Done",
      sessionId: "s1",
      inputTokens: 100,
      outputTokens: 50,
      costUsd: 0.01,
      numTurns: 5,
      exhausted: false,
    });
    vi.mocked(integratePr).mockResolvedValue({ exitCode: 0 });

    // Act
    const result = await runFinisher(baseOpts);

    // Assert
    expect(result.recovered).toBe(2);
  });

  it("skips branches that have active worktrees", async () => {
    // Arrange
    (vi.mocked(execa) as any).mockImplementation(async (cmd: string, args?: string[]) => {
      if (cmd === "git" && args?.[0] === "branch") {
        return { stdout: "genie/P1-auth-deliver" } as never;
      }
      return { stdout: "" } as never;
    });
    vi.mocked(listSessions).mockResolvedValue([
      { slug: "P1-auth-deliver", branch: "genie/P1-auth-deliver", path: "/repo--P1-auth" },
    ]);

    // Act
    const result = await runFinisher(baseOpts);

    // Assert
    expect(sessionStart).not.toHaveBeenCalled();
    expect(result.recovered).toBe(0);
    expect(result.stalled).toEqual([]);
  });
});
