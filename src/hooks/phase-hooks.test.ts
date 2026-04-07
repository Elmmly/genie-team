import { describe, it, expect, afterEach } from "vitest";
import { mkdtemp, rm, readFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import {
  createCostLogger,
  createArtifactTracker,
  type ArtifactRecord,
} from "./phase-hooks.js";

describe("createCostLogger", () => {
  let tmpDir: string;

  afterEach(async () => {
    if (tmpDir) await rm(tmpDir, { recursive: true, force: true });
  });

  it("appends JSONL entry for a phase", async () => {
    // Arrange
    tmpDir = await mkdtemp(join(tmpdir(), "hook-test-"));
    const logger = createCostLogger(tmpDir);

    // Act
    await logger.log({
      phase: "deliver",
      genie: "crafter",
      turns: 42,
      inputTokens: 5000,
      outputTokens: 2000,
      costUsd: 0.05,
      durationMs: 30000,
    });

    // Assert
    const content = await readFile(join(tmpDir, "run-pdlc.jsonl"), "utf-8");
    const entry = JSON.parse(content.trim());
    expect(entry.phase).toBe("deliver");
    expect(entry.turns).toBe(42);
    expect(entry.cost_usd).toBe(0.05);
    expect(entry.timestamp).toBeDefined();
  });

  it("appends multiple entries", async () => {
    // Arrange
    tmpDir = await mkdtemp(join(tmpdir(), "hook-test-"));
    const logger = createCostLogger(tmpDir);

    // Act
    await logger.log({
      phase: "discover",
      genie: "scout",
      turns: 10,
      inputTokens: 1000,
      outputTokens: 500,
      costUsd: 0.01,
      durationMs: 5000,
    });
    await logger.log({
      phase: "define",
      genie: "shaper",
      turns: 15,
      inputTokens: 2000,
      outputTokens: 800,
      costUsd: 0.02,
      durationMs: 8000,
    });

    // Assert
    const content = await readFile(join(tmpDir, "run-pdlc.jsonl"), "utf-8");
    const lines = content.trim().split("\n");
    expect(lines).toHaveLength(2);
  });

  it("is a no-op when logDir is empty", async () => {
    // Arrange
    const logger = createCostLogger("");

    // Act & Assert — should not throw
    await logger.log({
      phase: "deliver",
      genie: "crafter",
      turns: 1,
      inputTokens: 0,
      outputTokens: 0,
      costUsd: 0,
      durationMs: 0,
    });
  });
});

describe("createArtifactTracker", () => {
  it("records write operations", () => {
    // Arrange
    const tracker = createArtifactTracker();

    // Act
    tracker.recordWrite("docs/analysis/discovery.md");
    tracker.recordWrite("docs/backlog/P0-item.md");

    // Assert
    expect(tracker.getArtifacts()).toEqual([
      { path: "docs/analysis/discovery.md", type: "write" },
      { path: "docs/backlog/P0-item.md", type: "write" },
    ]);
  });

  it("deduplicates paths", () => {
    // Arrange
    const tracker = createArtifactTracker();

    // Act
    tracker.recordWrite("docs/backlog/P0-item.md");
    tracker.recordWrite("docs/backlog/P0-item.md");

    // Assert
    expect(tracker.getArtifacts()).toHaveLength(1);
  });

  it("finds artifact by type prefix", () => {
    // Arrange
    const tracker = createArtifactTracker();
    tracker.recordWrite("docs/analysis/discovery.md");
    tracker.recordWrite("docs/backlog/P0-item.md");

    // Act
    const analysis = tracker.findByPrefix("docs/analysis/");
    const backlog = tracker.findByPrefix("docs/backlog/");

    // Assert
    expect(analysis).toBe("docs/analysis/discovery.md");
    expect(backlog).toBe("docs/backlog/P0-item.md");
  });

  it("returns undefined when no match found", () => {
    // Arrange
    const tracker = createArtifactTracker();

    // Act & Assert
    expect(tracker.findByPrefix("docs/analysis/")).toBeUndefined();
  });
});
