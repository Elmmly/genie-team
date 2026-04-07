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
});
