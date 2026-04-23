import { readdir, readFile, writeFile, stat } from "node:fs/promises";
import { join, basename } from "node:path";

export interface StatusItem {
  slug: string;
  phase: string;
  status: "done" | "running" | "stuck" | "failed" | "conflict";
  durationSecs: number;
  logFile: string;
}

export interface StatusReport {
  items: StatusItem[];
  summary: { total: number; done: number; running: number; stuck: number; failed: number };
  exitCode: number;
}

export interface BatchManifest {
  timestamp: string;
  succeeded: string[];
  failed: string[];
  conflicts: string[];
}

const DEFAULT_STUCK_MINS = 10;
const PHASE_PATTERN = /^=== Phase: (\S+) ===/;
const EXIT_CODE_PATTERN = /EXIT_CODE=(\d+)/;

/**
 * Parse the most recent phase from log content.
 * Returns "unknown" if no phase marker is found.
 */
function parsePhase(content: string): string {
  let lastPhase = "unknown";
  for (const line of content.split("\n")) {
    const match = PHASE_PATTERN.exec(line);
    if (match) {
      lastPhase = match[1];
    }
  }
  return lastPhase;
}

/**
 * Parse the exit code from log content.
 * Returns undefined if no EXIT_CODE marker is found.
 */
function parseExitCode(content: string): number | undefined {
  let lastCode: number | undefined;
  for (const line of content.split("\n")) {
    const match = EXIT_CODE_PATTERN.exec(line);
    if (match) {
      lastCode = parseInt(match[1], 10);
    }
  }
  return lastCode;
}

/**
 * Determine item status based on log content, file mtime, and manifest data.
 */
function determineStatus(
  content: string,
  mtimeMs: number,
  stuckThresholdMs: number,
  manifestStatus?: "succeeded" | "failed" | "conflict",
): StatusItem["status"] {
  // Manifest overrides take precedence
  if (manifestStatus === "conflict") return "conflict";
  if (manifestStatus === "succeeded") return "done";
  if (manifestStatus === "failed") return "failed";

  // Check log content for exit code
  const exitCode = parseExitCode(content);
  if (exitCode !== undefined) {
    return exitCode === 0 ? "done" : "failed";
  }

  // No exit code — check if still active via mtime
  const ageMs = Date.now() - mtimeMs;
  if (ageMs > stuckThresholdMs) {
    return "stuck";
  }
  return "running";
}

/**
 * Compute the report-level exit code from item statuses.
 * 0 = all done, 1 = stuck/failed, 2 = still running.
 */
function computeExitCode(summary: StatusReport["summary"]): number {
  if (summary.stuck > 0 || summary.failed > 0) return 1;
  if (summary.running > 0) return 2;
  return 0;
}

/**
 * Read batch status from a log directory.
 * Scans .log files, parses phase/exit markers, checks mtime for liveness.
 */
export async function readBatchStatus(
  logDir: string,
  opts?: { stuckMins?: number },
): Promise<StatusReport> {
  const stuckMins = opts?.stuckMins ?? DEFAULT_STUCK_MINS;
  const stuckThresholdMs = stuckMins * 60_000;

  const manifest = await readBatchManifest(logDir);

  // Build manifest lookup for slug -> status
  const manifestLookup = new Map<string, "succeeded" | "failed" | "conflict">();
  if (manifest) {
    for (const slug of manifest.succeeded) manifestLookup.set(slug, "succeeded");
    for (const slug of manifest.failed) manifestLookup.set(slug, "failed");
    for (const slug of manifest.conflicts) manifestLookup.set(slug, "conflict");
  }

  let entries: string[];
  try {
    entries = await readdir(logDir);
  } catch {
    entries = [];
  }

  const logFiles = entries.filter((f) => f.endsWith(".log")).sort();
  const items: StatusItem[] = [];

  for (const filename of logFiles) {
    const filePath = join(logDir, filename);
    const slug = basename(filename, ".log");
    const [content, fileStat] = await Promise.all([
      readFile(filePath, "utf-8"),
      stat(filePath),
    ]);

    const phase = parsePhase(content);
    const status = determineStatus(
      content,
      fileStat.mtimeMs,
      stuckThresholdMs,
      manifestLookup.get(slug),
    );
    const durationSecs = Math.round((Date.now() - fileStat.birthtimeMs) / 1000);

    items.push({
      slug,
      phase,
      status,
      durationSecs,
      logFile: filePath,
    });
  }

  const summary = {
    total: items.length,
    done: items.filter((i) => i.status === "done").length,
    running: items.filter((i) => i.status === "running").length,
    stuck: items.filter((i) => i.status === "stuck").length,
    failed: items.filter((i) => i.status === "failed").length,
  };

  return {
    items,
    summary,
    exitCode: computeExitCode(summary),
  };
}

/**
 * Format a status report as a human-readable table.
 */
export function formatStatusTable(report: StatusReport): string {
  if (report.items.length === 0) {
    return "No items found.";
  }

  const lines: string[] = [];

  // Header
  const cols = ["SLUG", "PHASE", "STATUS", "DURATION"];
  const widths = [
    Math.max(cols[0].length, ...report.items.map((i) => i.slug.length)),
    Math.max(cols[1].length, ...report.items.map((i) => i.phase.length)),
    Math.max(cols[2].length, ...report.items.map((i) => i.status.length)),
    Math.max(cols[3].length, 8),
  ];

  const header = cols.map((c, idx) => c.padEnd(widths[idx])).join("  ");
  lines.push(header);
  lines.push(widths.map((w) => "─".repeat(w)).join("  "));

  // Rows
  for (const item of report.items) {
    const durStr = formatDuration(item.durationSecs);
    lines.push(
      [
        item.slug.padEnd(widths[0]),
        item.phase.padEnd(widths[1]),
        item.status.padEnd(widths[2]),
        durStr.padEnd(widths[3]),
      ].join("  "),
    );
  }

  // Summary
  lines.push("");
  const parts: string[] = [];
  if (report.summary.done > 0) parts.push(`${report.summary.done} done`);
  if (report.summary.running > 0) parts.push(`${report.summary.running} running`);
  if (report.summary.stuck > 0) parts.push(`${report.summary.stuck} stuck`);
  if (report.summary.failed > 0) parts.push(`${report.summary.failed} failed`);
  lines.push(parts.length > 0 ? parts.join(", ") : "0 items");

  return lines.join("\n");
}

function formatDuration(secs: number): string {
  if (secs < 60) return `${secs}s`;
  const mins = Math.floor(secs / 60);
  const remSecs = secs % 60;
  return remSecs > 0 ? `${mins}m${remSecs}s` : `${mins}m`;
}

/**
 * Format a status report as pretty-printed JSON.
 */
export function formatStatusJson(report: StatusReport): string {
  return JSON.stringify(report, null, 2);
}

/**
 * Write a batch manifest to the log directory.
 */
export async function writeBatchManifest(
  logDir: string,
  manifest: BatchManifest,
): Promise<void> {
  const filePath = join(logDir, "batch-manifest.json");
  await writeFile(filePath, JSON.stringify(manifest, null, 2), "utf-8");
}

/**
 * Read a batch manifest from the log directory.
 * Returns undefined if the file does not exist or is malformed.
 */
export async function readBatchManifest(
  logDir: string,
): Promise<BatchManifest | undefined> {
  const filePath = join(logDir, "batch-manifest.json");
  try {
    const content = await readFile(filePath, "utf-8");
    const parsed = JSON.parse(content);
    // Validate minimal shape
    if (
      !Array.isArray(parsed.succeeded) ||
      !Array.isArray(parsed.failed) ||
      !Array.isArray(parsed.conflicts)
    ) {
      return undefined;
    }
    return parsed as BatchManifest;
  } catch {
    return undefined;
  }
}
