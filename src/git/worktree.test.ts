import { describe, it, expect, vi, beforeEach } from "vitest";
import {
  repoRoot,
  repoName,
  defaultBranch,
  worktreeDir,
  branchName,
  branchExists,
  findBranch,
  sessionStart,
  sessionCleanup,
  sessionFinish,
  integratePr,
  integrateTrunk,
  listSessions,
} from "./worktree.js";

vi.mock("execa", () => ({
  execa: vi.fn(),
}));

import { execa } from "execa";

describe("repoRoot", () => {
  beforeEach(() => vi.resetAllMocks());

  it("returns first worktree path", async () => {
    // Arrange
    vi.mocked(execa).mockResolvedValue({
      stdout: "worktree /Users/me/project\nHEAD abc123\nbranch refs/heads/main\n",
    } as never);

    // Act
    const root = await repoRoot();

    // Assert
    expect(root).toBe("/Users/me/project");
  });
});

describe("defaultBranch", () => {
  beforeEach(() => vi.resetAllMocks());

  it("detects branch from symbolic ref", async () => {
    // Arrange
    vi.mocked(execa).mockResolvedValue({
      stdout: "refs/remotes/origin/main",
    } as never);

    // Act
    const branch = await defaultBranch();

    // Assert
    expect(branch).toBe("main");
  });

  it("falls back to main if symbolic ref fails", async () => {
    // Arrange
    vi.mocked(execa)
      .mockRejectedValueOnce(new Error("no ref")) // symbolic-ref
      .mockResolvedValueOnce({ stdout: "" } as never); // show-ref main succeeds

    // Act
    const branch = await defaultBranch();

    // Assert
    expect(branch).toBe("main");
  });
});

describe("worktreeDir", () => {
  it("constructs path from repo root", () => {
    expect(worktreeDir("/Users/me/project", "P0-item")).toBe(
      "/Users/me/project--P0-item",
    );
  });
});

describe("branchName", () => {
  it("constructs genie branch name", () => {
    expect(branchName("P0-item", "deliver")).toBe("genie/P0-item-deliver");
  });
});

describe("branchExists", () => {
  beforeEach(() => vi.resetAllMocks());

  it("returns true when branch exists", async () => {
    // Arrange
    vi.mocked(execa).mockResolvedValue({ stdout: "" } as never);

    // Act & Assert
    expect(await branchExists("genie/P0-item-deliver")).toBe(true);
  });

  it("returns false when branch does not exist", async () => {
    // Arrange
    vi.mocked(execa).mockRejectedValue(new Error("not a ref"));

    // Act & Assert
    expect(await branchExists("genie/P0-item-deliver")).toBe(false);
  });
});

describe("findBranch", () => {
  beforeEach(() => vi.resetAllMocks());

  it("returns exact match first", async () => {
    // Arrange
    vi.mocked(execa).mockResolvedValue({ stdout: "" } as never);

    // Act
    const branch = await findBranch("P0-item");

    // Assert
    expect(branch).toBe("genie/P0-item");
  });

  it("falls back to glob match", async () => {
    // Arrange
    vi.mocked(execa)
      .mockRejectedValueOnce(new Error("no exact")) // show-ref exact
      .mockResolvedValueOnce({ stdout: "genie/P0-item-deliver" } as never); // for-each-ref

    // Act
    const branch = await findBranch("P0-item");

    // Assert
    expect(branch).toBe("genie/P0-item-deliver");
  });

  it("returns undefined when no branch found", async () => {
    // Arrange
    vi.mocked(execa)
      .mockRejectedValueOnce(new Error("no exact"))
      .mockResolvedValueOnce({ stdout: "" } as never);

    // Act
    const branch = await findBranch("P0-item");

    // Assert
    expect(branch).toBeUndefined();
  });
});

describe("sessionStart", () => {
  beforeEach(() => vi.resetAllMocks());

  it("creates worktree and returns path", async () => {
    // Arrange — repo root, default branch, branch doesn't exist, worktree add
    vi.mocked(execa)
      .mockResolvedValueOnce({
        stdout: "worktree /Users/me/project\nHEAD abc\nbranch refs/heads/main\n",
      } as never) // repoRoot
      .mockResolvedValueOnce({ stdout: "refs/remotes/origin/main" } as never) // defaultBranch
      .mockRejectedValueOnce(new Error("no branch")) // branchExists
      .mockResolvedValueOnce({ stdout: "" } as never); // worktree add

    // Act
    const path = await sessionStart("P0-item", "deliver");

    // Assert
    expect(path).toBe("/Users/me/project--P0-item");
  });
});

describe("sessionCleanup", () => {
  beforeEach(() => vi.resetAllMocks());

  it("removes worktree and branch without throwing", async () => {
    // Arrange
    vi.mocked(execa)
      .mockResolvedValueOnce({
        stdout: "worktree /Users/me/project\nHEAD abc\nbranch refs/heads/main\n",
      } as never) // repoRoot
      .mockRejectedValueOnce(new Error("no exact")) // findBranch exact
      .mockResolvedValueOnce({ stdout: "genie/P0-item-deliver" } as never) // findBranch glob
      .mockResolvedValue({ stdout: "" } as never); // worktree remove, branch -D

    // Act & Assert — should not throw
    await sessionCleanup("P0-item");
  });
});

describe("listSessions", () => {
  beforeEach(() => vi.resetAllMocks());

  it("returns genie worktrees from porcelain output", async () => {
    // Arrange
    const porcelain = [
      "worktree /Users/me/project",
      "HEAD abc123",
      "branch refs/heads/main",
      "",
      "worktree /Users/me/project--P0-auth",
      "HEAD def456",
      "branch refs/heads/genie/P0-auth-deliver",
      "",
      "worktree /Users/me/project--P1-search",
      "HEAD ghi789",
      "branch refs/heads/genie/P1-search-design",
      "",
    ].join("\n");
    vi.mocked(execa).mockResolvedValue({ stdout: porcelain } as never);

    // Act
    const sessions = await listSessions();

    // Assert
    expect(sessions).toHaveLength(2);
    expect(sessions[0]).toEqual({
      path: "/Users/me/project--P0-auth",
      branch: "genie/P0-auth-deliver",
      slug: "P0-auth",
    });
    expect(sessions[1]).toEqual({
      path: "/Users/me/project--P1-search",
      branch: "genie/P1-search-design",
      slug: "P1-search",
    });
  });

  it("handles multi-segment slugs correctly", async () => {
    // Arrange
    const porcelain = [
      "worktree /Users/me/project",
      "HEAD abc123",
      "branch refs/heads/main",
      "",
      "worktree /Users/me/project--P1-done-handler",
      "HEAD def456",
      "branch refs/heads/genie/P1-done-handler-deliver",
      "",
    ].join("\n");
    vi.mocked(execa).mockResolvedValue({ stdout: porcelain } as never);

    // Act
    const sessions = await listSessions();

    // Assert — slug should be "P1-done-handler", not "P1-done"
    expect(sessions[0].slug).toBe("P1-done-handler");
  });

  it("returns empty array when no genie worktrees exist", async () => {
    // Arrange
    const porcelain = [
      "worktree /Users/me/project",
      "HEAD abc123",
      "branch refs/heads/main",
      "",
    ].join("\n");
    vi.mocked(execa).mockResolvedValue({ stdout: porcelain } as never);

    // Act
    const sessions = await listSessions();

    // Assert
    expect(sessions).toEqual([]);
  });

  it("handles detached HEAD worktrees gracefully", async () => {
    // Arrange
    const porcelain = [
      "worktree /Users/me/project",
      "HEAD abc123",
      "branch refs/heads/main",
      "",
      "worktree /Users/me/project--detached",
      "HEAD def456",
      "detached",
      "",
    ].join("\n");
    vi.mocked(execa).mockResolvedValue({ stdout: porcelain } as never);

    // Act
    const sessions = await listSessions();

    // Assert
    expect(sessions).toEqual([]);
  });
});
