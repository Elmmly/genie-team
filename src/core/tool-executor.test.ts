import { describe, it, expect, beforeEach, afterEach } from "vitest";
import { mkdtemp, rm, writeFile, readFile, mkdir } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { LocalToolExecutor } from "./tool-executor.js";

describe("LocalToolExecutor", () => {
  let tmpDir: string;
  let executor: LocalToolExecutor;

  beforeEach(async () => {
    tmpDir = await mkdtemp(join(tmpdir(), "tool-test-"));
    executor = new LocalToolExecutor(tmpDir);
  });

  afterEach(async () => {
    await rm(tmpDir, { recursive: true, force: true });
  });

  describe("Read", () => {
    it("reads file contents", async () => {
      // Arrange
      await writeFile(join(tmpDir, "test.txt"), "hello world");

      // Act
      const result = await executor.execute("Read", { file_path: join(tmpDir, "test.txt") });

      // Assert
      expect(result).toContain("hello world");
    });

    it("returns error for missing file", async () => {
      // Act
      const result = await executor.execute("Read", { file_path: join(tmpDir, "missing.txt") });

      // Assert
      expect(result).toContain("Error");
    });
  });

  describe("Write", () => {
    it("writes file contents", async () => {
      // Arrange
      const filePath = join(tmpDir, "output.txt");

      // Act
      await executor.execute("Write", { file_path: filePath, content: "new content" });

      // Assert
      const written = await readFile(filePath, "utf-8");
      expect(written).toBe("new content");
    });

    it("creates parent directories", async () => {
      // Arrange
      const filePath = join(tmpDir, "sub", "dir", "file.txt");

      // Act
      await executor.execute("Write", { file_path: filePath, content: "nested" });

      // Assert
      const written = await readFile(filePath, "utf-8");
      expect(written).toBe("nested");
    });
  });

  describe("Edit", () => {
    it("replaces string in file", async () => {
      // Arrange
      const filePath = join(tmpDir, "edit.txt");
      await writeFile(filePath, "hello world");

      // Act
      await executor.execute("Edit", {
        file_path: filePath,
        old_string: "world",
        new_string: "genie",
      });

      // Assert
      const edited = await readFile(filePath, "utf-8");
      expect(edited).toBe("hello genie");
    });

    it("returns error when old_string not found", async () => {
      // Arrange
      const filePath = join(tmpDir, "edit.txt");
      await writeFile(filePath, "hello world");

      // Act
      const result = await executor.execute("Edit", {
        file_path: filePath,
        old_string: "missing",
        new_string: "replacement",
      });

      // Assert
      expect(result).toContain("not found");
    });
  });

  describe("Bash", () => {
    it("executes command and returns stdout", async () => {
      // Act
      const result = await executor.execute("Bash", { command: "echo hello" });

      // Assert
      expect(result.trim()).toBe("hello");
    });

    it("returns stderr on failure", async () => {
      // Act
      const result = await executor.execute("Bash", { command: "ls /nonexistent_path_xyz" });

      // Assert
      expect(result).toContain("Error");
    });
  });

  describe("Glob", () => {
    it("finds files matching pattern", async () => {
      // Arrange
      await writeFile(join(tmpDir, "a.ts"), "");
      await writeFile(join(tmpDir, "b.ts"), "");
      await writeFile(join(tmpDir, "c.js"), "");

      // Act
      const result = await executor.execute("Glob", { pattern: "*.ts", path: tmpDir });

      // Assert
      expect(result).toContain("a.ts");
      expect(result).toContain("b.ts");
      expect(result).not.toContain("c.js");
    });
  });

  describe("Grep", () => {
    it("finds lines matching pattern", async () => {
      // Arrange
      await writeFile(join(tmpDir, "search.txt"), "line one\nfind me\nline three\n");

      // Act
      const result = await executor.execute("Grep", { pattern: "find", path: tmpDir });

      // Assert
      expect(result).toContain("find me");
    });
  });

  describe("availableTools", () => {
    it("returns tool definitions for all supported tools", () => {
      // Act
      const tools = executor.availableTools();

      // Assert
      const names = tools.map((t) => t.name);
      expect(names).toContain("Read");
      expect(names).toContain("Write");
      expect(names).toContain("Edit");
      expect(names).toContain("Bash");
      expect(names).toContain("Glob");
      expect(names).toContain("Grep");
    });
  });

  describe("unknown tool", () => {
    it("returns error for unrecognized tool", async () => {
      // Act
      const result = await executor.execute("UnknownTool", {});

      // Assert
      expect(result).toContain("Unknown tool");
    });
  });
});
