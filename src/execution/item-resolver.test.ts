import { describe, it, expect, afterEach } from "vitest";
import { mkdtemp, rm, mkdir, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { resolveItems } from "./item-resolver.js";

describe("resolveItems", () => {
  let tmpDir: string;

  afterEach(async () => {
    if (tmpDir) await rm(tmpDir, { recursive: true, force: true });
  });

  it("resolves shaped items to design phase", async () => {
    // Arrange
    tmpDir = await mkdtemp(join(tmpdir(), "resolve-test-"));
    await mkdir(join(tmpDir, "docs", "backlog"), { recursive: true });
    await writeFile(
      join(tmpDir, "docs", "backlog", "P1-auth.md"),
      "---\nstatus: shaped\npriority: P1\ntitle: Auth\n---\n# Auth\n",
    );

    // Act
    const items = await resolveItems(tmpDir);

    // Assert
    expect(items).toHaveLength(1);
    expect(items[0].phase).toBe("design");
    expect(items[0].slug).toBe("P1-auth");
  });

  it("resolves designed items to deliver phase", async () => {
    // Arrange
    tmpDir = await mkdtemp(join(tmpdir(), "resolve-test-"));
    await mkdir(join(tmpDir, "docs", "backlog"), { recursive: true });
    await writeFile(
      join(tmpDir, "docs", "backlog", "P2-search.md"),
      "---\nstatus: designed\npriority: P2\ntitle: Search\n---\n",
    );

    // Act
    const items = await resolveItems(tmpDir);

    // Assert
    expect(items[0].phase).toBe("deliver");
  });

  it("resolves implemented items to discern phase", async () => {
    // Arrange
    tmpDir = await mkdtemp(join(tmpdir(), "resolve-test-"));
    await mkdir(join(tmpDir, "docs", "backlog"), { recursive: true });
    await writeFile(
      join(tmpDir, "docs", "backlog", "P1-item.md"),
      "---\nstatus: implemented\npriority: P1\ntitle: Item\n---\n",
    );

    // Act
    const items = await resolveItems(tmpDir);

    // Assert
    expect(items[0].phase).toBe("discern");
  });

  it("skips done and abandoned items", async () => {
    // Arrange
    tmpDir = await mkdtemp(join(tmpdir(), "resolve-test-"));
    await mkdir(join(tmpDir, "docs", "backlog"), { recursive: true });
    await writeFile(
      join(tmpDir, "docs", "backlog", "P1-done.md"),
      "---\nstatus: done\npriority: P1\ntitle: Done\n---\n",
    );
    await writeFile(
      join(tmpDir, "docs", "backlog", "P1-abandoned.md"),
      "---\nstatus: abandoned\npriority: P1\ntitle: Abandoned\n---\n",
    );

    // Act
    const items = await resolveItems(tmpDir);

    // Assert
    expect(items).toHaveLength(0);
  });

  it("filters by priority when specified", async () => {
    // Arrange
    tmpDir = await mkdtemp(join(tmpdir(), "resolve-test-"));
    await mkdir(join(tmpDir, "docs", "backlog"), { recursive: true });
    await writeFile(
      join(tmpDir, "docs", "backlog", "P0-critical.md"),
      "---\nstatus: shaped\npriority: P0\ntitle: Critical\n---\n",
    );
    await writeFile(
      join(tmpDir, "docs", "backlog", "P2-nice.md"),
      "---\nstatus: shaped\npriority: P2\ntitle: Nice\n---\n",
    );

    // Act
    const items = await resolveItems(tmpDir, { priorities: ["P0"] });

    // Assert
    expect(items).toHaveLength(1);
    expect(items[0].slug).toBe("P0-critical");
  });

  it("returns empty array when no backlog directory", async () => {
    // Arrange
    tmpDir = await mkdtemp(join(tmpdir(), "resolve-test-"));

    // Act
    const items = await resolveItems(tmpDir);

    // Assert
    expect(items).toHaveLength(0);
  });

  // --- Topics support ---

  it("resolves pending topics from docs/topics/ with discover phase", async () => {
    // Arrange
    tmpDir = await mkdtemp(join(tmpdir(), "resolve-test-"));
    await mkdir(join(tmpDir, "docs", "topics"), { recursive: true });
    await writeFile(
      join(tmpDir, "docs", "topics", "explore-auth.md"),
      "---\nstatus: pending\ntype: topic\ntitle: Explore Auth\n---\n# Explore Auth\n",
    );

    // Act
    const items = await resolveItems(tmpDir);

    // Assert
    expect(items).toHaveLength(1);
    expect(items[0].phase).toBe("discover");
    expect(items[0].slug).toBe("explore-auth");
    expect(items[0].input).toBe(join(tmpDir, "docs", "topics", "explore-auth.md"));
  });

  it("skips non-pending topics", async () => {
    // Arrange
    tmpDir = await mkdtemp(join(tmpdir(), "resolve-test-"));
    await mkdir(join(tmpDir, "docs", "topics"), { recursive: true });
    await writeFile(
      join(tmpDir, "docs", "topics", "done-topic.md"),
      "---\nstatus: processing\ntype: topic\ntitle: Done Topic\n---\n",
    );

    // Act
    const items = await resolveItems(tmpDir);

    // Assert
    expect(items).toHaveLength(0);
  });

  it("resolves both backlog items and topics together", async () => {
    // Arrange
    tmpDir = await mkdtemp(join(tmpdir(), "resolve-test-"));
    await mkdir(join(tmpDir, "docs", "backlog"), { recursive: true });
    await mkdir(join(tmpDir, "docs", "topics"), { recursive: true });
    await writeFile(
      join(tmpDir, "docs", "backlog", "P1-auth.md"),
      "---\nstatus: shaped\npriority: P1\ntitle: Auth\n---\n",
    );
    await writeFile(
      join(tmpDir, "docs", "topics", "explore-search.md"),
      "---\nstatus: pending\ntype: topic\ntitle: Explore Search\n---\n",
    );

    // Act
    const items = await resolveItems(tmpDir);

    // Assert
    expect(items).toHaveLength(2);
    const phases = items.map((i) => i.phase);
    expect(phases).toContain("design");
    expect(phases).toContain("discover");
  });

  it("returns empty when docs/topics/ does not exist", async () => {
    // Arrange
    tmpDir = await mkdtemp(join(tmpdir(), "resolve-test-"));
    // No backlog or topics dirs

    // Act
    const items = await resolveItems(tmpDir);

    // Assert
    expect(items).toHaveLength(0);
  });

  // --- Topics file support ---

  it("reads topics from --topicsFile, one per line", async () => {
    // Arrange
    tmpDir = await mkdtemp(join(tmpdir(), "resolve-test-"));
    const topicsFilePath = join(tmpDir, "topics.txt");
    await writeFile(topicsFilePath, "explore authentication\nexplore search\n");

    // Act
    const items = await resolveItems(tmpDir, { topicsFile: topicsFilePath });

    // Assert
    expect(items).toHaveLength(2);
    expect(items[0].phase).toBe("discover");
    expect(items[0].input).toBe("explore authentication");
    expect(items[0].slug).toBe("explore-authentication");
    expect(items[1].input).toBe("explore search");
    expect(items[1].slug).toBe("explore-search");
  });

  it("skips blank lines and comments in topics file", async () => {
    // Arrange
    tmpDir = await mkdtemp(join(tmpdir(), "resolve-test-"));
    const topicsFilePath = join(tmpDir, "topics.txt");
    await writeFile(topicsFilePath, "# comment\n\nexplore auth\n  \n");

    // Act
    const items = await resolveItems(tmpDir, { topicsFile: topicsFilePath });

    // Assert
    expect(items).toHaveLength(1);
    expect(items[0].input).toBe("explore auth");
  });

  // --- minPhase support ---

  it("applies --minPhase floor to effective start phase", async () => {
    // Arrange
    tmpDir = await mkdtemp(join(tmpdir(), "resolve-test-"));
    await mkdir(join(tmpDir, "docs", "backlog"), { recursive: true });
    // shaped -> design, but minPhase is deliver, so should bump to deliver
    await writeFile(
      join(tmpDir, "docs", "backlog", "P1-auth.md"),
      "---\nstatus: shaped\npriority: P1\ntitle: Auth\n---\n",
    );

    // Act
    const items = await resolveItems(tmpDir, { minPhase: "deliver" });

    // Assert
    expect(items).toHaveLength(1);
    expect(items[0].phase).toBe("deliver");
  });

  it("does not lower phase when item is already past minPhase", async () => {
    // Arrange
    tmpDir = await mkdtemp(join(tmpdir(), "resolve-test-"));
    await mkdir(join(tmpDir, "docs", "backlog"), { recursive: true });
    // implemented -> discern, minPhase is design, discern > design so no change
    await writeFile(
      join(tmpDir, "docs", "backlog", "P1-item.md"),
      "---\nstatus: implemented\npriority: P1\ntitle: Item\n---\n",
    );

    // Act
    const items = await resolveItems(tmpDir, { minPhase: "design" });

    // Assert
    expect(items[0].phase).toBe("discern");
  });

  it("topics always start from discover regardless of minPhase", async () => {
    // Arrange
    tmpDir = await mkdtemp(join(tmpdir(), "resolve-test-"));
    await mkdir(join(tmpDir, "docs", "topics"), { recursive: true });
    await writeFile(
      join(tmpDir, "docs", "topics", "explore-auth.md"),
      "---\nstatus: pending\ntype: topic\ntitle: Explore Auth\n---\n",
    );

    // Act
    const items = await resolveItems(tmpDir, { minPhase: "deliver" });

    // Assert
    expect(items).toHaveLength(1);
    expect(items[0].phase).toBe("discover");
  });

  it("topics from topicsFile always start from discover regardless of minPhase", async () => {
    // Arrange
    tmpDir = await mkdtemp(join(tmpdir(), "resolve-test-"));
    const topicsFilePath = join(tmpDir, "topics.txt");
    await writeFile(topicsFilePath, "explore auth\n");

    // Act
    const items = await resolveItems(tmpDir, {
      topicsFile: topicsFilePath,
      minPhase: "deliver",
    });

    // Assert
    expect(items).toHaveLength(1);
    expect(items[0].phase).toBe("discover");
  });

  it("applies priority filter to topics from docs/topics/", async () => {
    // Arrange
    tmpDir = await mkdtemp(join(tmpdir(), "resolve-test-"));
    await mkdir(join(tmpDir, "docs", "topics"), { recursive: true });
    await writeFile(
      join(tmpDir, "docs", "topics", "p0-topic.md"),
      "---\nstatus: pending\ntype: topic\npriority: P0\ntitle: P0 Topic\n---\n",
    );
    await writeFile(
      join(tmpDir, "docs", "topics", "p2-topic.md"),
      "---\nstatus: pending\ntype: topic\npriority: P2\ntitle: P2 Topic\n---\n",
    );

    // Act
    const items = await resolveItems(tmpDir, { priorities: ["P0"] });

    // Assert
    expect(items).toHaveLength(1);
    expect(items[0].slug).toBe("p0-topic");
  });
});
