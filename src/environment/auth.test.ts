import { describe, it, expect, beforeEach, afterEach } from "vitest";
import { detectAuth, resolveAuth } from "./auth.js";

describe("detectAuth", () => {
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

  it("returns apikey mode when ANTHROPIC_API_KEY is set", () => {
    // Arrange
    process.env.ANTHROPIC_API_KEY = "sk-ant-test-key";

    // Act
    const result = detectAuth();

    // Assert
    expect(result.mode).toBe("apikey");
    expect(result.hasApiKey).toBe(true);
  });

  it("returns oauth mode when no API key", () => {
    // Arrange
    delete process.env.ANTHROPIC_API_KEY;

    // Act
    const result = detectAuth();

    // Assert
    expect(result.mode).toBe("oauth");
    expect(result.hasApiKey).toBe(false);
  });

  it("returns oauth for empty API key string", () => {
    // Arrange
    process.env.ANTHROPIC_API_KEY = "";

    // Act
    const result = detectAuth();

    // Assert
    expect(result.mode).toBe("oauth");
    expect(result.hasApiKey).toBe(false);
  });

  it("includes billing note for apikey mode", () => {
    // Arrange
    process.env.ANTHROPIC_API_KEY = "sk-ant-test-key";

    // Act
    const result = detectAuth();

    // Assert
    expect(result.billingNote).toContain("API key");
  });

  it("includes billing note for oauth mode", () => {
    // Arrange
    delete process.env.ANTHROPIC_API_KEY;

    // Act
    const result = detectAuth();

    // Assert
    expect(result.billingNote).toContain("OAuth");
  });
});

describe("resolveAuth", () => {
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

  it("no override uses detectAuth", () => {
    // Arrange
    process.env.ANTHROPIC_API_KEY = "sk-ant-test";

    // Act
    const result = resolveAuth();

    // Assert
    expect(result.mode).toBe("apikey");
  });

  it("--auth oauth returns oauth mode even with API key present", () => {
    // Arrange
    process.env.ANTHROPIC_API_KEY = "sk-ant-test";

    // Act
    const result = resolveAuth("oauth");

    // Assert
    expect(result.mode).toBe("oauth");
  });

  it("--auth oauth notes ignored API key", () => {
    // Arrange
    process.env.ANTHROPIC_API_KEY = "sk-ant-test";

    // Act
    const result = resolveAuth("oauth");

    // Assert
    expect(result.billingNote).toContain("--auth oauth");
    expect(result.hasApiKey).toBe(true);
  });

  it("--auth apikey succeeds when API key present", () => {
    // Arrange
    process.env.ANTHROPIC_API_KEY = "sk-ant-test";

    // Act
    const result = resolveAuth("apikey");

    // Assert
    expect(result.mode).toBe("apikey");
  });

  it("--auth apikey throws when no API key", () => {
    // Arrange
    delete process.env.ANTHROPIC_API_KEY;

    // Act & Assert
    expect(() => resolveAuth("apikey")).toThrow("ANTHROPIC_API_KEY");
  });
});
