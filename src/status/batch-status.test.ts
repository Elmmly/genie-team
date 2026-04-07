import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";
import { mkdtempSync, writeFileSync, mkdirSync, utimesSync, readFileSync } from "node:fs";
import { join } from "node:path";
import { tmpdir } from "node:os";
import {
  readBatchStatus,
  formatStatusTable,
  formatStatusJson,
  writeBatchManifest,
  readBatchManifest,
  type StatusItem,
  type StatusReport,
  type BatchManifest,
} from "./batch-status.js";

function createTmpLogDir(): string {
  return mkdtempSync(join(tmpdir(), "batch-status-test-"));
}

/** Write a log file and optionally backdate its mtime. */
function writeLog(
  dir: string,
  slug: string,
  content: string,
  opts?: { mtimeMinutesAgo?: number },
): string {
  const filePath = join(dir, `${slug}.log`);
  writeFileSync(filePath, content, "utf-8");
  if (opts?.mtimeMinutesAgo !== undefined) {
    const mtime = new Date(Date.now() - opts.mtimeMinutesAgo * 60_000);
    utimesSync(filePath, mtime, mtime);
  }
  return filePath;
}

describe("readBatchStatus", () => {
  it("AC-1: returns empty report for empty log directory", async () => {
    // ac_id: AC-1
    // Arrange
    const logDir = createTmpLogDir();

    // Act
    const report = await readBatchStatus(logDir);

    // Assert
    expect(report.items).toHaveLength(0);
    expect(report.summary.total).toBe(0);
    expect(report.exitCode).toBe(0);
  });

  it("AC-2: extracts slug from log filename", async () => {
    // ac_id: AC-2
    // Arrange
    const logDir = createTmpLogDir();
    writeLog(logDir, "P1-auth", "=== Phase: deliver ===\nDone.", { mtimeMinutesAgo: 0 });

    // Act
    const report = await readBatchStatus(logDir);

    // Assert
    expect(report.items).toHaveLength(1);
    expect(report.items[0].slug).toBe("P1-auth");
  });

  it("AC-3: parses current phase from log content", async () => {
    // ac_id: AC-3
    // Arrange
    const logDir = createTmpLogDir();
    writeLog(logDir, "P1-auth", "=== Phase: design ===\nworking...\n=== Phase: deliver ===\nstill working", { mtimeMinutesAgo: 0 });

    // Act
    const report = await readBatchStatus(logDir);

    // Assert
    expect(report.items[0].phase).toBe("deliver");
  });

  it("AC-4: detects running status when log recently modified", async () => {
    // ac_id: AC-4
    // Arrange
    const logDir = createTmpLogDir();
    writeLog(logDir, "P1-auth", "=== Phase: deliver ===\nworking...", { mtimeMinutesAgo: 1 });

    // Act
    const report = await readBatchStatus(logDir);

    // Assert
    expect(report.items[0].status).toBe("running");
  });

  it("AC-5: detects stuck status when log not modified beyond threshold", async () => {
    // ac_id: AC-5
    // Arrange
    const logDir = createTmpLogDir();
    writeLog(logDir, "P1-auth", "=== Phase: deliver ===\nworking...", { mtimeMinutesAgo: 15 });

    // Act
    const report = await readBatchStatus(logDir, { stuckMins: 10 });

    // Assert
    expect(report.items[0].status).toBe("stuck");
  });

  it("AC-6: detects done status from log content", async () => {
    // ac_id: AC-6
    // Arrange
    const logDir = createTmpLogDir();
    writeLog(logDir, "P1-auth", "=== Phase: deliver ===\nEXIT_CODE=0", { mtimeMinutesAgo: 30 });

    // Act
    const report = await readBatchStatus(logDir);

    // Assert
    expect(report.items[0].status).toBe("done");
  });

  it("AC-7: detects failed status from non-zero exit code in log", async () => {
    // ac_id: AC-7
    // Arrange
    const logDir = createTmpLogDir();
    writeLog(logDir, "P1-auth", "=== Phase: deliver ===\nEXIT_CODE=1", { mtimeMinutesAgo: 30 });

    // Act
    const report = await readBatchStatus(logDir);

    // Assert
    expect(report.items[0].status).toBe("failed");
  });

  it("AC-8: detects conflict status from batch manifest", async () => {
    // ac_id: AC-8
    // Arrange
    const logDir = createTmpLogDir();
    writeLog(logDir, "P1-auth", "=== Phase: deliver ===\nsome output", { mtimeMinutesAgo: 30 });
    const manifest: BatchManifest = {
      timestamp: new Date().toISOString(),
      succeeded: [],
      failed: [],
      conflicts: ["P1-auth"],
    };
    writeFileSync(join(logDir, "batch-manifest.json"), JSON.stringify(manifest), "utf-8");

    // Act
    const report = await readBatchStatus(logDir);

    // Assert
    expect(report.items[0].status).toBe("conflict");
  });

  it("AC-9: default stuck threshold is 10 minutes", async () => {
    // ac_id: AC-9
    // Arrange
    const logDir = createTmpLogDir();
    writeLog(logDir, "P1-auth", "=== Phase: deliver ===\nworking...", { mtimeMinutesAgo: 11 });

    // Act
    const report = await readBatchStatus(logDir);

    // Assert
    expect(report.items[0].status).toBe("stuck");
  });

  it("AC-10: custom stuck threshold is respected", async () => {
    // ac_id: AC-10
    // Arrange
    const logDir = createTmpLogDir();
    writeLog(logDir, "P1-auth", "=== Phase: deliver ===\nworking...", { mtimeMinutesAgo: 11 });

    // Act
    const report = await readBatchStatus(logDir, { stuckMins: 15 });

    // Assert
    expect(report.items[0].status).toBe("running");
  });

  it("AC-11: summary counts are correct", async () => {
    // ac_id: AC-11
    // Arrange
    const logDir = createTmpLogDir();
    writeLog(logDir, "P1-done", "=== Phase: deliver ===\nEXIT_CODE=0", { mtimeMinutesAgo: 30 });
    writeLog(logDir, "P2-running", "=== Phase: design ===\nworking...", { mtimeMinutesAgo: 1 });
    writeLog(logDir, "P3-stuck", "=== Phase: deliver ===\nworking...", { mtimeMinutesAgo: 15 });
    writeLog(logDir, "P4-failed", "=== Phase: deliver ===\nEXIT_CODE=1", { mtimeMinutesAgo: 30 });

    // Act
    const report = await readBatchStatus(logDir);

    // Assert
    expect(report.summary.total).toBe(4);
    expect(report.summary.done).toBe(1);
    expect(report.summary.running).toBe(1);
    expect(report.summary.stuck).toBe(1);
    expect(report.summary.failed).toBe(1);
  });

  it("AC-12: exit code 0 when all done", async () => {
    // ac_id: AC-12
    // Arrange
    const logDir = createTmpLogDir();
    writeLog(logDir, "P1-done", "=== Phase: deliver ===\nEXIT_CODE=0", { mtimeMinutesAgo: 30 });
    writeLog(logDir, "P2-done", "=== Phase: deliver ===\nEXIT_CODE=0", { mtimeMinutesAgo: 30 });

    // Act
    const report = await readBatchStatus(logDir);

    // Assert
    expect(report.exitCode).toBe(0);
  });

  it("AC-13: exit code 1 when stuck or failed present", async () => {
    // ac_id: AC-13
    // Arrange
    const logDir = createTmpLogDir();
    writeLog(logDir, "P1-done", "=== Phase: deliver ===\nEXIT_CODE=0", { mtimeMinutesAgo: 30 });
    writeLog(logDir, "P2-stuck", "=== Phase: deliver ===\nworking...", { mtimeMinutesAgo: 15 });

    // Act
    const report = await readBatchStatus(logDir);

    // Assert
    expect(report.exitCode).toBe(1);
  });

  it("AC-14: exit code 2 when still running", async () => {
    // ac_id: AC-14
    // Arrange
    const logDir = createTmpLogDir();
    writeLog(logDir, "P1-running", "=== Phase: deliver ===\nworking...", { mtimeMinutesAgo: 1 });

    // Act
    const report = await readBatchStatus(logDir);

    // Assert
    expect(report.exitCode).toBe(2);
  });

  it("AC-14 edge: exit code 1 takes precedence over 2", async () => {
    // ac_id: AC-14
    // Arrange
    const logDir = createTmpLogDir();
    writeLog(logDir, "P1-running", "=== Phase: deliver ===\nworking...", { mtimeMinutesAgo: 1 });
    writeLog(logDir, "P2-failed", "=== Phase: deliver ===\nEXIT_CODE=1", { mtimeMinutesAgo: 30 });

    // Act
    const report = await readBatchStatus(logDir);

    // Assert
    expect(report.exitCode).toBe(1);
  });

  it("edge: ignores non-.log files in log directory", async () => {
    // Arrange
    const logDir = createTmpLogDir();
    writeLog(logDir, "P1-auth", "=== Phase: deliver ===\nEXIT_CODE=0", { mtimeMinutesAgo: 30 });
    writeFileSync(join(logDir, "batch-manifest.json"), "{}", "utf-8");
    writeFileSync(join(logDir, "notes.txt"), "not a log", "utf-8");

    // Act
    const report = await readBatchStatus(logDir);

    // Assert
    expect(report.items).toHaveLength(1);
    expect(report.items[0].slug).toBe("P1-auth");
  });

  it("edge: returns durationSecs for each item", async () => {
    // Arrange
    const logDir = createTmpLogDir();
    writeLog(logDir, "P1-auth", "=== Phase: deliver ===\nworking...", { mtimeMinutesAgo: 5 });

    // Act
    const report = await readBatchStatus(logDir);

    // Assert
    expect(report.items[0].durationSecs).toBeGreaterThan(0);
    expect(typeof report.items[0].durationSecs).toBe("number");
  });

  it("edge: includes logFile path in each item", async () => {
    // Arrange
    const logDir = createTmpLogDir();
    const logFile = writeLog(logDir, "P1-auth", "=== Phase: deliver ===\nEXIT_CODE=0", { mtimeMinutesAgo: 30 });

    // Act
    const report = await readBatchStatus(logDir);

    // Assert
    expect(report.items[0].logFile).toBe(logFile);
  });

  it("edge: phase defaults to 'unknown' when no phase marker found", async () => {
    // Arrange
    const logDir = createTmpLogDir();
    writeLog(logDir, "P1-auth", "some random log output\nno phase here", { mtimeMinutesAgo: 1 });

    // Act
    const report = await readBatchStatus(logDir);

    // Assert
    expect(report.items[0].phase).toBe("unknown");
  });

  it("edge: manifest succeeded items are marked done", async () => {
    // Arrange
    const logDir = createTmpLogDir();
    writeLog(logDir, "P1-auth", "=== Phase: deliver ===\nsome output", { mtimeMinutesAgo: 30 });
    const manifest: BatchManifest = {
      timestamp: new Date().toISOString(),
      succeeded: ["P1-auth"],
      failed: [],
      conflicts: [],
    };
    writeFileSync(join(logDir, "batch-manifest.json"), JSON.stringify(manifest), "utf-8");

    // Act
    const report = await readBatchStatus(logDir);

    // Assert
    expect(report.items[0].status).toBe("done");
  });

  it("edge: manifest failed items are marked failed", async () => {
    // Arrange
    const logDir = createTmpLogDir();
    writeLog(logDir, "P1-auth", "=== Phase: deliver ===\nsome output", { mtimeMinutesAgo: 30 });
    const manifest: BatchManifest = {
      timestamp: new Date().toISOString(),
      succeeded: [],
      failed: ["P1-auth"],
      conflicts: [],
    };
    writeFileSync(join(logDir, "batch-manifest.json"), JSON.stringify(manifest), "utf-8");

    // Act
    const report = await readBatchStatus(logDir);

    // Assert
    expect(report.items[0].status).toBe("failed");
  });
});

describe("formatStatusTable", () => {
  it("AC-15: outputs table with headers and rows", () => {
    // ac_id: AC-15
    // Arrange
    const report: StatusReport = {
      items: [
        { slug: "P1-auth", phase: "deliver", status: "done", durationSecs: 120, logFile: "/tmp/P1-auth.log" },
        { slug: "P2-search", phase: "design", status: "running", durationSecs: 60, logFile: "/tmp/P2-search.log" },
      ],
      summary: { total: 2, done: 1, running: 1, stuck: 0, failed: 0 },
      exitCode: 2,
    };

    // Act
    const table = formatStatusTable(report);

    // Assert
    expect(table).toContain("P1-auth");
    expect(table).toContain("deliver");
    expect(table).toContain("done");
    expect(table).toContain("P2-search");
    expect(table).toContain("running");
  });

  it("AC-15 edge: includes summary line", () => {
    // ac_id: AC-15
    // Arrange
    const report: StatusReport = {
      items: [
        { slug: "P1-auth", phase: "deliver", status: "done", durationSecs: 120, logFile: "/tmp/P1-auth.log" },
      ],
      summary: { total: 1, done: 1, running: 0, stuck: 0, failed: 0 },
      exitCode: 0,
    };

    // Act
    const table = formatStatusTable(report);

    // Assert
    expect(table).toContain("1 done");
  });

  it("edge: empty report produces minimal output", () => {
    // Arrange
    const report: StatusReport = {
      items: [],
      summary: { total: 0, done: 0, running: 0, stuck: 0, failed: 0 },
      exitCode: 0,
    };

    // Act
    const table = formatStatusTable(report);

    // Assert
    expect(table).toContain("No items");
  });
});

describe("formatStatusJson", () => {
  it("AC-16: outputs valid JSON with items and summary", () => {
    // ac_id: AC-16
    // Arrange
    const report: StatusReport = {
      items: [
        { slug: "P1-auth", phase: "deliver", status: "done", durationSecs: 120, logFile: "/tmp/P1-auth.log" },
      ],
      summary: { total: 1, done: 1, running: 0, stuck: 0, failed: 0 },
      exitCode: 0,
    };

    // Act
    const json = formatStatusJson(report);

    // Assert
    const parsed = JSON.parse(json);
    expect(parsed.items).toHaveLength(1);
    expect(parsed.items[0].slug).toBe("P1-auth");
    expect(parsed.summary.total).toBe(1);
    expect(parsed.exitCode).toBe(0);
  });

  it("edge: JSON is pretty-printed with 2-space indent", () => {
    // Arrange
    const report: StatusReport = {
      items: [],
      summary: { total: 0, done: 0, running: 0, stuck: 0, failed: 0 },
      exitCode: 0,
    };

    // Act
    const json = formatStatusJson(report);

    // Assert
    expect(json).toBe(JSON.stringify(report, null, 2));
  });
});

describe("writeBatchManifest", () => {
  it("AC-17: writes batch-manifest.json to log directory", async () => {
    // ac_id: AC-17
    // Arrange
    const logDir = createTmpLogDir();
    const manifest: BatchManifest = {
      timestamp: "2026-04-07T00:00:00.000Z",
      succeeded: ["P1-auth"],
      failed: ["P2-search"],
      conflicts: ["P3-data"],
    };

    // Act
    await writeBatchManifest(logDir, manifest);

    // Assert
    const content = readFileSync(join(logDir, "batch-manifest.json"), "utf-8");
    const parsed = JSON.parse(content);
    expect(parsed.timestamp).toBe("2026-04-07T00:00:00.000Z");
    expect(parsed.succeeded).toEqual(["P1-auth"]);
    expect(parsed.failed).toEqual(["P2-search"]);
    expect(parsed.conflicts).toEqual(["P3-data"]);
  });
});

describe("readBatchManifest", () => {
  it("AC-18: reads existing batch-manifest.json", async () => {
    // ac_id: AC-18
    // Arrange
    const logDir = createTmpLogDir();
    const manifest: BatchManifest = {
      timestamp: "2026-04-07T00:00:00.000Z",
      succeeded: ["P1-auth"],
      failed: [],
      conflicts: [],
    };
    writeFileSync(join(logDir, "batch-manifest.json"), JSON.stringify(manifest), "utf-8");

    // Act
    const result = await readBatchManifest(logDir);

    // Assert
    expect(result).toBeDefined();
    expect(result!.succeeded).toEqual(["P1-auth"]);
  });

  it("AC-19: returns undefined when manifest does not exist", async () => {
    // ac_id: AC-19
    // Arrange
    const logDir = createTmpLogDir();

    // Act
    const result = await readBatchManifest(logDir);

    // Assert
    expect(result).toBeUndefined();
  });

  it("edge: returns undefined for malformed JSON", async () => {
    // Arrange
    const logDir = createTmpLogDir();
    writeFileSync(join(logDir, "batch-manifest.json"), "not valid json{{{", "utf-8");

    // Act
    const result = await readBatchManifest(logDir);

    // Assert
    expect(result).toBeUndefined();
  });
});
