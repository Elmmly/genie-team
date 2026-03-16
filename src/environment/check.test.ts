import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";
import {
  type CheckResult,
  checkClaudeCli,
  checkGitRepo,
  checkGhAuth,
  checkAuth,
  checkGenieConfig,
  runChecks,
} from "./check.js";

// Mock execa
vi.mock("execa", () => ({
  execa: vi.fn(),
}));

import { execa } from "execa";

describe("checkClaudeCli", () => {
  beforeEach(() => {
    vi.resetAllMocks();
  });

  it("passes when claude CLI is available", async () => {
    // Arrange
    vi.mocked(execa).mockResolvedValue({ stdout: "1.0.0" } as never);

    // Act
    const result = await checkClaudeCli();

    // Assert
    expect(result.status).toBe("pass");
    expect(result.name).toBe("Claude CLI");
  });

  it("fails when claude CLI is not found", async () => {
    // Arrange
    vi.mocked(execa).mockRejectedValue(new Error("not found"));

    // Act
    const result = await checkClaudeCli();

    // Assert
    expect(result.status).toBe("fail");
    expect(result.detail).toContain("not found");
  });
});

describe("checkGitRepo", () => {
  beforeEach(() => {
    vi.resetAllMocks();
  });

  it("passes when in a clean git repository", async () => {
    // Arrange
    vi.mocked(execa)
      .mockResolvedValueOnce({ stdout: ".git" } as never) // rev-parse
      .mockResolvedValueOnce({ stdout: "" } as never); // status --porcelain (clean)

    // Act
    const result = await checkGitRepo();

    // Assert
    expect(result.status).toBe("pass");
  });

  it("fails when not in a git repository", async () => {
    // Arrange
    vi.mocked(execa).mockRejectedValue(new Error("not a git repo"));

    // Act
    const result = await checkGitRepo();

    // Assert
    expect(result.status).toBe("fail");
  });

  it("warns about dirty working tree", async () => {
    // Arrange
    vi.mocked(execa)
      .mockResolvedValueOnce({ stdout: ".git" } as never)
      .mockResolvedValueOnce({ stdout: " M dirty-file.ts" } as never);

    // Act
    const result = await checkGitRepo();

    // Assert
    expect(result.status).toBe("warn");
    expect(result.detail).toContain("uncommitted");
  });
});

describe("checkGhAuth", () => {
  beforeEach(() => {
    vi.resetAllMocks();
  });

  it("passes when gh is authenticated", async () => {
    // Arrange
    vi.mocked(execa)
      .mockResolvedValueOnce({ stdout: "/usr/bin/gh" } as never)
      .mockResolvedValueOnce({ stdout: "Logged in" } as never);

    // Act
    const result = await checkGhAuth();

    // Assert
    expect(result.status).toBe("pass");
  });

  it("fails when gh is not installed", async () => {
    // Arrange
    vi.mocked(execa).mockRejectedValue(new Error("not found"));

    // Act
    const result = await checkGhAuth();

    // Assert
    expect(result.status).toBe("fail");
    expect(result.detail).toContain("not found");
  });

  it("fails when gh is not authenticated", async () => {
    // Arrange
    vi.mocked(execa)
      .mockResolvedValueOnce({ stdout: "/usr/bin/gh" } as never)
      .mockRejectedValueOnce(new Error("not logged in"));

    // Act
    const result = await checkGhAuth();

    // Assert
    expect(result.status).toBe("fail");
    expect(result.detail).toContain("not authenticated");
  });
});

describe("checkAuth", () => {
  let savedKey: string | undefined;

  beforeEach(() => {
    savedKey = process.env.ANTHROPIC_API_KEY;
  });

  afterEach(() => {
    if (savedKey !== undefined) {
      process.env.ANTHROPIC_API_KEY = savedKey;
    } else {
      delete process.env.ANTHROPIC_API_KEY;
    }
  });

  it("passes with API key billing info", () => {
    // Arrange
    process.env.ANTHROPIC_API_KEY = "sk-ant-test";

    // Act
    const result = checkAuth();

    // Assert
    expect(result.status).toBe("pass");
    expect(result.detail).toContain("API key");
  });

  it("passes with OAuth billing info", () => {
    // Arrange
    delete process.env.ANTHROPIC_API_KEY;

    // Act
    const result = checkAuth();

    // Assert
    expect(result.status).toBe("pass");
    expect(result.detail).toContain("OAuth");
  });
});

describe("checkGenieConfig", () => {
  it("returns pass with config source info", () => {
    // Act
    const result = checkGenieConfig();

    // Assert
    expect(result.status).toBe("pass");
    expect(result.name).toBe("Genie Config");
  });
});

describe("runChecks", () => {
  beforeEach(() => {
    vi.resetAllMocks();
  });

  it("returns exit 0 when all checks pass", async () => {
    // Arrange — mock all execa calls to succeed
    vi.mocked(execa).mockResolvedValue({ stdout: "ok" } as never);

    // Act
    const { results, exitCode } = await runChecks();

    // Assert
    expect(exitCode).toBe(0);
    expect(results.length).toBeGreaterThan(0);
  });

  it("returns exit 1 when any check fails", async () => {
    // Arrange — claude CLI not found
    vi.mocked(execa).mockRejectedValue(new Error("not found"));

    // Act
    const { exitCode } = await runChecks();

    // Assert
    expect(exitCode).toBe(1);
  });

  it("returns all results even when some fail", async () => {
    // Arrange
    vi.mocked(execa).mockRejectedValue(new Error("not found"));

    // Act
    const { results } = await runChecks();

    // Assert — should have results for all checks, not just the first failure
    expect(results.length).toBeGreaterThanOrEqual(4);
  });
});
