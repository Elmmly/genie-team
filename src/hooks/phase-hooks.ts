import { appendFile, mkdir } from "node:fs/promises";
import { join } from "node:path";

export interface PhaseLogEntry {
  phase: string;
  genie: string;
  turns: number;
  inputTokens: number;
  outputTokens: number;
  costUsd: number;
  durationMs: number;
}

export interface CostLogger {
  log(entry: PhaseLogEntry): Promise<void>;
}

/**
 * Creates a JSONL cost logger that appends phase metrics to a log file.
 * No-op when logDir is empty.
 */
export function createCostLogger(logDir: string): CostLogger {
  return {
    async log(entry: PhaseLogEntry): Promise<void> {
      if (!logDir) return;

      await mkdir(logDir, { recursive: true });

      const record = {
        timestamp: new Date().toISOString(),
        phase: entry.phase,
        genie: entry.genie,
        turns: entry.turns,
        input_tokens: entry.inputTokens,
        output_tokens: entry.outputTokens,
        cost_usd: entry.costUsd,
        duration_ms: entry.durationMs,
      };

      const line = JSON.stringify(record) + "\n";
      await appendFile(join(logDir, "run-pdlc.jsonl"), line, "utf-8");
    },
  };
}

export interface ArtifactRecord {
  path: string;
  type: "write";
}

export interface ArtifactTracker {
  recordWrite(path: string): void;
  getArtifacts(): ArtifactRecord[];
  findByPrefix(prefix: string): string | undefined;
}

/**
 * Tracks file artifacts created during phase execution.
 * Used to resolve artifact paths for inter-phase routing
 * (e.g., discover writes analysis → define reads it).
 */
export function createArtifactTracker(): ArtifactTracker {
  const seen = new Set<string>();
  const artifacts: ArtifactRecord[] = [];

  return {
    recordWrite(path: string): void {
      if (seen.has(path)) return;
      seen.add(path);
      artifacts.push({ path, type: "write" });
    },

    getArtifacts(): ArtifactRecord[] {
      return [...artifacts];
    },

    findByPrefix(prefix: string): string | undefined {
      return artifacts.find((a) => a.path.startsWith(prefix))?.path;
    },
  };
}
