import { describe, it, expect, afterEach } from "vitest";
import { mkdtemp, rm, readFile, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import {
  parseFrontmatter,
  stringifyFrontmatter,
  readFrontmatter,
  writeFrontmatter,
  getFrontmatterField,
  setFrontmatterField,
  type ParsedDocument,
} from "./frontmatter.js";

describe("parseFrontmatter", () => {
  it("extracts YAML frontmatter from markdown", () => {
    // Arrange
    const content =
      "---\ntitle: Hello\nstatus: draft\n---\n# Body\n\nSome text.\n";

    // Act
    const result = parseFrontmatter(content);

    // Assert
    expect(result.frontmatter).toEqual({ title: "Hello", status: "draft" });
    expect(result.body).toBe("# Body\n\nSome text.\n");
  });

  it("returns empty frontmatter when no delimiters", () => {
    // Arrange
    const content = "# Just a heading\n\nNo frontmatter here.\n";

    // Act
    const result = parseFrontmatter(content);

    // Assert
    expect(result.frontmatter).toEqual({});
    expect(result.body).toBe(content);
  });

  it("handles empty frontmatter block", () => {
    // Arrange
    const content = "---\n---\n# Body after empty frontmatter\n";

    // Act
    const result = parseFrontmatter(content);

    // Assert
    expect(result.frontmatter).toEqual({});
    expect(result.body).toBe("# Body after empty frontmatter\n");
  });

  it("preserves body content exactly", () => {
    // Arrange
    const body =
      "# Title\n\nParagraph with `code`, *bold*\n\n- list item\n  - nested\n\n```yaml\nkey: value\n```\n";
    const content = `---\ntitle: test\n---\n${body}`;

    // Act
    const result = parseFrontmatter(content);

    // Assert
    expect(result.body).toBe(body);
  });

  it("handles nested objects and arrays", () => {
    // Arrange
    const content = [
      "---",
      "acceptance_criteria:",
      "  - id: AC-1",
      "    status: pending",
      "  - id: AC-2",
      "    status: met",
      "metadata:",
      "  tags:",
      "    - feature",
      "    - p0",
      "---",
      "# Body",
      "",
    ].join("\n");

    // Act
    const result = parseFrontmatter(content);

    // Assert
    expect(result.frontmatter.acceptance_criteria).toEqual([
      { id: "AC-1", status: "pending" },
      { id: "AC-2", status: "met" },
    ]);
    expect(result.frontmatter.metadata).toEqual({ tags: ["feature", "p0"] });
  });

  it("handles quoted strings with colons", () => {
    // Arrange
    const content =
      '---\ntitle: "Step 1: Configure"\nurl: "https://example.com"\n---\n# Body\n';

    // Act
    const result = parseFrontmatter(content);

    // Assert
    expect(result.frontmatter.title).toBe("Step 1: Configure");
    expect(result.frontmatter.url).toBe("https://example.com");
  });
});

describe("stringifyFrontmatter", () => {
  it("round-trips parse/stringify", () => {
    // Arrange
    const original =
      "---\ntitle: Hello\nstatus: draft\n---\n# Body\n\nSome text.\n";
    const parsed = parseFrontmatter(original);

    // Act
    const result = stringifyFrontmatter(parsed);
    const reparsed = parseFrontmatter(result);

    // Assert
    expect(reparsed.frontmatter).toEqual(parsed.frontmatter);
    expect(reparsed.body).toBe(parsed.body);
  });

  it("handles empty frontmatter", () => {
    // Arrange
    const doc: ParsedDocument = { frontmatter: {}, body: "# Just body\n" };

    // Act
    const result = stringifyFrontmatter(doc);

    // Assert
    expect(result).toBe("---\n---\n# Just body\n");
  });
});

describe("readFrontmatter", () => {
  let tmpDir: string;

  afterEach(async () => {
    if (tmpDir) await rm(tmpDir, { recursive: true, force: true });
  });

  it("reads file from disk", async () => {
    // Arrange
    tmpDir = await mkdtemp(join(tmpdir(), "fm-test-"));
    const filePath = join(tmpDir, "test.md");
    await writeFile(
      filePath,
      "---\ntitle: Disk Test\n---\n# Body from disk\n",
    );

    // Act
    const result = await readFrontmatter(filePath);

    // Assert
    expect(result.frontmatter.title).toBe("Disk Test");
    expect(result.body).toBe("# Body from disk\n");
  });
});

describe("writeFrontmatter", () => {
  let tmpDir: string;

  afterEach(async () => {
    if (tmpDir) await rm(tmpDir, { recursive: true, force: true });
  });

  it("writes atomically (temp + rename)", async () => {
    // Arrange
    tmpDir = await mkdtemp(join(tmpdir(), "fm-test-"));
    const filePath = join(tmpDir, "output.md");
    const doc: ParsedDocument = {
      frontmatter: { title: "Written", status: "active" },
      body: "# Written body\n",
    };

    // Act
    await writeFrontmatter(filePath, doc);

    // Assert
    const content = await readFile(filePath, "utf-8");
    const parsed = parseFrontmatter(content);
    expect(parsed.frontmatter.title).toBe("Written");
    expect(parsed.body).toBe("# Written body\n");
  });

  it("preserves body on field update", async () => {
    // Arrange
    tmpDir = await mkdtemp(join(tmpdir(), "fm-test-"));
    const filePath = join(tmpDir, "preserve.md");
    const body = "# Complex body\n\nWith **markdown** and `code`.\n\n- list\n";
    await writeFile(filePath, `---\ntitle: Original\nstatus: draft\n---\n${body}`);

    // Act
    const doc = await readFrontmatter(filePath);
    doc.frontmatter.status = "active";
    await writeFrontmatter(filePath, doc);

    // Assert
    const result = await readFrontmatter(filePath);
    expect(result.frontmatter.status).toBe("active");
    expect(result.body).toBe(body);
  });
});

describe("getFrontmatterField", () => {
  let tmpDir: string;

  afterEach(async () => {
    if (tmpDir) await rm(tmpDir, { recursive: true, force: true });
  });

  it("returns single field value", async () => {
    // Arrange
    tmpDir = await mkdtemp(join(tmpdir(), "fm-test-"));
    const filePath = join(tmpDir, "field.md");
    await writeFile(
      filePath,
      "---\ntitle: Field Test\nstatus: pending\n---\n# Body\n",
    );

    // Act
    const result = await getFrontmatterField(filePath, "status");

    // Assert
    expect(result).toBe("pending");
  });

  it("returns undefined for missing field", async () => {
    // Arrange
    tmpDir = await mkdtemp(join(tmpdir(), "fm-test-"));
    const filePath = join(tmpDir, "field.md");
    await writeFile(filePath, "---\ntitle: Test\n---\n# Body\n");

    // Act
    const result = await getFrontmatterField(filePath, "nonexistent");

    // Assert
    expect(result).toBeUndefined();
  });
});

describe("setFrontmatterField", () => {
  let tmpDir: string;

  afterEach(async () => {
    if (tmpDir) await rm(tmpDir, { recursive: true, force: true });
  });

  it("updates single field atomically", async () => {
    // Arrange
    tmpDir = await mkdtemp(join(tmpdir(), "fm-test-"));
    const filePath = join(tmpDir, "update.md");
    await writeFile(
      filePath,
      "---\ntitle: Original\nstatus: draft\n---\n# Body\n",
    );

    // Act
    await setFrontmatterField(filePath, "status", "active");

    // Assert
    const result = await readFrontmatter(filePath);
    expect(result.frontmatter.status).toBe("active");
    expect(result.frontmatter.title).toBe("Original");
  });

  it("adds new field to existing frontmatter", async () => {
    // Arrange
    tmpDir = await mkdtemp(join(tmpdir(), "fm-test-"));
    const filePath = join(tmpDir, "add.md");
    await writeFile(filePath, "---\ntitle: Existing\n---\n# Body\n");

    // Act
    await setFrontmatterField(filePath, "priority", "P0");

    // Assert
    const result = await readFrontmatter(filePath);
    expect(result.frontmatter.priority).toBe("P0");
    expect(result.frontmatter.title).toBe("Existing");
  });

  it("adds field to file with no frontmatter", async () => {
    // Arrange
    tmpDir = await mkdtemp(join(tmpdir(), "fm-test-"));
    const filePath = join(tmpDir, "nofm.md");
    await writeFile(filePath, "# Just a heading\n\nSome content.\n");

    // Act
    await setFrontmatterField(filePath, "status", "new");

    // Assert
    const result = await readFrontmatter(filePath);
    expect(result.frontmatter.status).toBe("new");
    expect(result.body).toBe("# Just a heading\n\nSome content.\n");
  });
});
