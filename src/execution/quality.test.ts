import { describe, it, expect, vi, beforeEach } from "vitest";
import { runQualityChecks, VALIDATORS } from "./quality.js";

vi.mock("execa", () => ({
  execa: vi.fn(),
}));

import { execa } from "execa";

describe("quality command", () => {
  beforeEach(() => {
    vi.resetAllMocks();
  });

  it("exports known validator script names", () => {
    // Assert
    expect(VALIDATORS).toEqual([
      "check-crossrefs.sh",
      "check-source-sync.sh",
      "lint-frontmatter-yaml.sh",
      "validate-frontmatter.sh",
    ]);
  });

  it("runs all validators when no files specified", async () => {
    // Arrange
    vi.mocked(execa).mockResolvedValue({ exitCode: 0 } as never);

    // Act
    const result = await runQualityChecks({ projectRoot: "/fake/root" });

    // Assert
    expect(execa).toHaveBeenCalledTimes(VALIDATORS.length);
    for (const script of VALIDATORS) {
      expect(execa).toHaveBeenCalledWith(
        expect.stringContaining(script),
        [],
        expect.objectContaining({ cwd: "/fake/root" }),
      );
    }
    expect(result.exitCode).toBe(0);
  });

  it("passes file arguments through to each validator", async () => {
    // Arrange
    vi.mocked(execa).mockResolvedValue({ exitCode: 0 } as never);

    // Act
    await runQualityChecks({
      projectRoot: "/fake/root",
      files: ["docs/backlog/P1-auth.md", "docs/backlog/P2-search.md"],
    });

    // Assert
    for (const script of VALIDATORS) {
      expect(execa).toHaveBeenCalledWith(
        expect.stringContaining(script),
        ["docs/backlog/P1-auth.md", "docs/backlog/P2-search.md"],
        expect.objectContaining({ cwd: "/fake/root" }),
      );
    }
  });

  it("returns non-zero exitCode when any validator fails", async () => {
    // Arrange
    vi.mocked(execa)
      .mockResolvedValueOnce({ exitCode: 0 } as never)
      .mockRejectedValueOnce(Object.assign(new Error("failed"), { exitCode: 1 }))
      .mockResolvedValueOnce({ exitCode: 0 } as never)
      .mockResolvedValueOnce({ exitCode: 0 } as never);

    // Act
    const result = await runQualityChecks({ projectRoot: "/fake/root" });

    // Assert
    expect(result.exitCode).toBe(1);
  });

  it("collects results from each validator", async () => {
    // Arrange
    vi.mocked(execa).mockResolvedValue({ exitCode: 0 } as never);

    // Act
    const result = await runQualityChecks({ projectRoot: "/fake/root" });

    // Assert
    expect(result.results).toHaveLength(VALIDATORS.length);
    for (const r of result.results) {
      expect(r).toHaveProperty("script");
      expect(r).toHaveProperty("exitCode", 0);
    }
  });

  it("continues running remaining validators after one fails", async () => {
    // Arrange
    vi.mocked(execa)
      .mockRejectedValueOnce(Object.assign(new Error("fail"), { exitCode: 1 }))
      .mockResolvedValue({ exitCode: 0 } as never);

    // Act
    await runQualityChecks({ projectRoot: "/fake/root" });

    // Assert - all validators were called despite first failure
    expect(execa).toHaveBeenCalledTimes(VALIDATORS.length);
  });
});
