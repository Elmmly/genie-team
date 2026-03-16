import { describe, it, expect } from "vitest";
import {
  PHASES,
  PHASE_ORDER,
  phaseIndex,
  getMaxTurns,
  getMinTurns,
  getPhaseTools,
  isValidPhase,
  type PhaseName,
} from "./phase-config.js";
import { buildPhasePrompt } from "./prompt-builder.js";

describe("PHASES", () => {
  it("contains all 7 lifecycle phases in order", () => {
    expect(PHASES).toEqual([
      "discover",
      "define",
      "design",
      "deliver",
      "discern",
      "commit",
      "done",
    ]);
  });
});

describe("isValidPhase", () => {
  it("returns true for valid phases", () => {
    expect(isValidPhase("discover")).toBe(true);
    expect(isValidPhase("deliver")).toBe(true);
    expect(isValidPhase("done")).toBe(true);
  });

  it("returns false for invalid phases", () => {
    expect(isValidPhase("invalid")).toBe(false);
    expect(isValidPhase("")).toBe(false);
  });
});

describe("phaseIndex", () => {
  it("returns correct index for each phase", () => {
    expect(phaseIndex("discover")).toBe(0);
    expect(phaseIndex("deliver")).toBe(3);
    expect(phaseIndex("done")).toBe(6);
  });

  it("returns -1 for invalid phase", () => {
    expect(phaseIndex("invalid" as PhaseName)).toBe(-1);
  });
});

describe("getMaxTurns", () => {
  it("returns default turns for each phase", () => {
    expect(getMaxTurns("discover")).toBe(50);
    expect(getMaxTurns("deliver")).toBe(100);
    expect(getMaxTurns("commit")).toBe(10);
    expect(getMaxTurns("done")).toBe(20);
  });

  it("respects per-phase overrides", () => {
    // Arrange
    const overrides = { deliver: 200 };

    // Act & Assert
    expect(getMaxTurns("deliver", overrides)).toBe(200);
    expect(getMaxTurns("discover", overrides)).toBe(50); // unaffected
  });

  it("respects global override", () => {
    // Arrange
    const overrides = { global: 30 };

    // Act & Assert
    expect(getMaxTurns("discover", overrides)).toBe(30);
    expect(getMaxTurns("deliver", overrides)).toBe(30);
  });

  it("per-phase override takes precedence over global", () => {
    // Arrange
    const overrides = { global: 30, deliver: 200 };

    // Act & Assert
    expect(getMaxTurns("deliver", overrides)).toBe(200);
    expect(getMaxTurns("discover", overrides)).toBe(30);
  });
});

describe("getMinTurns", () => {
  it("returns 0 for most phases", () => {
    expect(getMinTurns("discover")).toBe(0);
    expect(getMinTurns("define")).toBe(0);
    expect(getMinTurns("commit")).toBe(0);
  });

  it("returns 3 for deliver", () => {
    expect(getMinTurns("deliver")).toBe(3);
  });
});

describe("getPhaseTools", () => {
  it("returns correct tools for discover", () => {
    const tools = getPhaseTools("discover");

    expect(tools).toContain("Read");
    expect(tools).toContain("WebSearch");
    expect(tools).toContain("Task");
    expect(tools).not.toContain("Write");
    expect(tools).not.toContain("Bash");
  });

  it("returns correct tools for deliver", () => {
    const tools = getPhaseTools("deliver");

    expect(tools).toContain("Bash");
    expect(tools).toContain("Write");
    expect(tools).toContain("Edit");
  });

  it("returns only Bash for commit", () => {
    const tools = getPhaseTools("commit");

    expect(tools).toEqual(["Bash"]);
  });
});

describe("buildPhasePrompt", () => {
  it("builds standard prompt with /<phase> <input>", () => {
    // Act
    const prompt = buildPhasePrompt("discover", "user authentication");

    // Assert
    expect(prompt).toContain("/discover");
    expect(prompt).toContain("user authentication");
  });

  it("prepends git-mode prefix in trunk mode", () => {
    // Act
    const prompt = buildPhasePrompt(
      "deliver",
      "docs/backlog/P0-item.md",
      { trunkMode: true },
    );

    // Assert
    expect(prompt).toContain("git-mode: trunk");
    expect(prompt).toContain("/deliver");
    expect(prompt).toContain("docs/backlog/P0-item.md");
  });

  it("omits git-mode prefix in PR mode", () => {
    // Act
    const prompt = buildPhasePrompt("deliver", "docs/backlog/P0-item.md");

    // Assert
    expect(prompt).not.toContain("git-mode");
  });

  it("includes context note when contextDir is true", () => {
    // Act
    const prompt = buildPhasePrompt("design", "docs/backlog/P0-item.md", {
      hasContextDir: true,
    });

    // Assert
    expect(prompt).toContain("docs/context/");
  });

  it("omits context note when contextDir is false", () => {
    // Act
    const prompt = buildPhasePrompt("design", "docs/backlog/P0-item.md", {
      hasContextDir: false,
    });

    // Assert
    expect(prompt).not.toContain("docs/context/");
  });
});
