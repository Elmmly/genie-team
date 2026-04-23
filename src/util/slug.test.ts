import { describe, it, expect } from "vitest";
import { sanitizeSlug } from "./slug.js";

describe("sanitizeSlug", () => {
  it("lowercases input", () => {
    // Arrange
    const input = "My-Feature";

    // Act
    const result = sanitizeSlug(input);

    // Assert
    expect(result).toBe("my-feature");
  });

  it("replaces non-alphanumeric characters with hyphens", () => {
    // Arrange
    const input = "hello world! foo@bar";

    // Act
    const result = sanitizeSlug(input);

    // Assert
    expect(result).toBe("hello-world-foo-bar");
  });

  it("collapses consecutive hyphens", () => {
    // Arrange
    const input = "foo---bar";

    // Act
    const result = sanitizeSlug(input);

    // Assert
    expect(result).toBe("foo-bar");
  });

  it("strips leading and trailing hyphens", () => {
    // Arrange
    const input = "-foo-bar-";

    // Act
    const result = sanitizeSlug(input);

    // Assert
    expect(result).toBe("foo-bar");
  });

  it("preserves dots and underscores", () => {
    // Arrange
    const input = "file_name.v2";

    // Act
    const result = sanitizeSlug(input);

    // Assert
    expect(result).toBe("file_name.v2");
  });

  it("truncates to 60 characters", () => {
    // Arrange
    const input = "a".repeat(80);

    // Act
    const result = sanitizeSlug(input);

    // Assert
    expect(result).toHaveLength(60);
  });

  it("handles empty string", () => {
    // Arrange
    const input = "";

    // Act
    const result = sanitizeSlug(input);

    // Assert
    expect(result).toBe("");
  });

  it("handles all-special-character input", () => {
    // Arrange
    const input = "!@#$%^&*()";

    // Act
    const result = sanitizeSlug(input);

    // Assert
    expect(result).toBe("");
  });
});
