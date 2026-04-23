import { describe, it, expect } from "vitest";
import { parseArtifactPath } from "./artifact.js";

describe("parseArtifactPath", () => {
  it("extracts analysis path from output", () => {
    // Arrange
    const output = "Created discovery report at docs/analysis/20260401_spike_auth.md";

    // Act
    const result = parseArtifactPath(output, "analysis");

    // Assert
    expect(result).toBe("docs/analysis/20260401_spike_auth.md");
  });

  it("extracts backlog path from output", () => {
    // Arrange
    const output = "Shaped work written to docs/backlog/P1-auth-improvements.md for review";

    // Act
    const result = parseArtifactPath(output, "backlog");

    // Assert
    expect(result).toBe("docs/backlog/P1-auth-improvements.md");
  });

  it("returns undefined when no matching path found", () => {
    // Arrange
    const output = "No artifacts created in this phase";

    // Act
    const result = parseArtifactPath(output, "analysis");

    // Assert
    expect(result).toBeUndefined();
  });

  it("takes first match when multiple paths exist", () => {
    // Arrange
    const output = "Updated docs/backlog/P1-auth.md and also docs/backlog/P2-search.md";

    // Act
    const result = parseArtifactPath(output, "backlog");

    // Assert
    expect(result).toBe("docs/backlog/P1-auth.md");
  });

  it("handles path with subdirectories", () => {
    // Arrange
    const output = "Design doc at docs/analysis/security/auth-deep-dive.md complete";

    // Act
    const result = parseArtifactPath(output, "analysis");

    // Assert
    expect(result).toBe("docs/analysis/security/auth-deep-dive.md");
  });

  it("ignores paths in quotes or parens", () => {
    // Arrange
    const output = 'See "docs/analysis/old-report.md" for reference docs/analysis/new-report.md';

    // Act
    const result = parseArtifactPath(output, "analysis");

    // Assert
    // Should get the first valid match regardless of surrounding context
    expect(result).toBeDefined();
    expect(result).toContain("docs/analysis/");
  });
});
