import { writeFileSync, readFileSync, renameSync, existsSync } from "node:fs";
import { dirname, join } from "node:path";
import { runDaemonCycle, type DaemonOptions, type DaemonCycleResult } from "./daemon.js";
import { runFinisher, type FinisherResult } from "./finisher.js";

export interface ContinuousDaemonOptions extends DaemonOptions {
  /** Seconds between cycles (default 300). */
  interval?: number;
  /** Stop after N cycles (undefined = unlimited). */
  maxCycles?: number;
  /** Cost budget cap in USD. */
  maxCostUsd?: number;
  /** Path to write daemon status JSON. */
  statusFile?: string;
}

export interface DaemonStatus {
  daemon_pid: number;
  started_at: string;
  current_cycle: number;
  last_cycle_at: string;
  cumulative_cost_usd: number;
  status: "starting" | "scanning" | "running" | "sleeping" | "stopped" | "budget_exceeded";
  next_scan_at: string;
  items_completed: string[];
  items_failed: string[];
  items_stalled: string[];
  totals: {
    completed: number;
    failed: number;
    stalled: number;
    finisher_recovered: number;
  };
}

/**
 * Write daemon status atomically via tmp file + rename.
 */
export function writeDaemonStatus(statusFile: string, status: DaemonStatus): void {
  const tmpFile = statusFile + ".tmp";
  writeFileSync(tmpFile, JSON.stringify(status, null, 2), "utf-8");
  renameSync(tmpFile, statusFile);
}

/**
 * Read daemon status from file. Returns undefined if file does not exist.
 */
export function readDaemonStatus(statusFile: string): DaemonStatus | undefined {
  if (!existsSync(statusFile)) {
    return undefined;
  }
  const raw = readFileSync(statusFile, "utf-8");
  return JSON.parse(raw) as DaemonStatus;
}

/** Sleep for the given number of seconds, checking the stop flag each second. */
async function interruptibleSleep(
  seconds: number,
  shouldStop: () => boolean,
): Promise<void> {
  for (let i = 0; i < seconds; i++) {
    if (shouldStop()) return;
    await new Promise<void>((resolve) => setTimeout(resolve, 1000));
  }
}

/**
 * Run the continuous daemon loop: execute cycles at the configured
 * interval until maxCycles, maxCostUsd, or a signal stops it.
 */
export async function runDaemon(options: ContinuousDaemonOptions): Promise<void> {
  const interval = options.interval ?? 300;
  const statusFile = options.statusFile ?? "daemon-status.json";

  let stopping = false;
  const shouldStop = (): boolean => stopping;

  // Signal handling — set the stopping flag, finish current phase then exit.
  const onSignal = (): void => {
    stopping = true;
  };
  process.on("SIGTERM", onSignal);
  process.on("SIGINT", onSignal);

  const startedAt = new Date().toISOString();
  let currentCycle = 0;
  let cumulativeCost = 0;
  const itemsCompleted: string[] = [];
  const itemsFailed: string[] = [];
  const itemsStalled: string[] = [];
  let finisherRecovered = 0;

  const makeStatus = (
    statusValue: DaemonStatus["status"],
    nextScanAt?: string,
  ): DaemonStatus => ({
    daemon_pid: process.pid,
    started_at: startedAt,
    current_cycle: currentCycle,
    last_cycle_at: new Date().toISOString(),
    cumulative_cost_usd: cumulativeCost,
    status: statusValue,
    next_scan_at: nextScanAt ?? "",
    items_completed: itemsCompleted,
    items_failed: itemsFailed,
    items_stalled: itemsStalled,
    totals: {
      completed: itemsCompleted.length,
      failed: itemsFailed.length,
      stalled: itemsStalled.length,
      finisher_recovered: finisherRecovered,
    },
  });

  try {
    writeDaemonStatus(statusFile, makeStatus("starting"));

    while (!stopping) {
      // Check cycle limit
      if (options.maxCycles !== undefined && currentCycle >= options.maxCycles) {
        break;
      }

      // Check cost limit
      if (options.maxCostUsd !== undefined && cumulativeCost >= options.maxCostUsd) {
        writeDaemonStatus(statusFile, makeStatus("budget_exceeded"));
        break;
      }

      currentCycle++;
      writeDaemonStatus(statusFile, makeStatus("scanning"));

      // Run one daemon cycle
      const cycleResult: DaemonCycleResult = await runDaemonCycle(options);
      cumulativeCost += cycleResult.costUsd;

      // Run finisher pass
      const finisherResult: FinisherResult = await runFinisher({
        throughPhase: options.throughPhase,
        finishMode: options.finishMode,
      });
      finisherRecovered += finisherResult.recovered;
      itemsStalled.push(...finisherResult.stalled);

      // Check cost limit after cycle
      if (options.maxCostUsd !== undefined && cumulativeCost >= options.maxCostUsd) {
        writeDaemonStatus(statusFile, makeStatus("budget_exceeded"));
        break;
      }

      // Check if we've reached maxCycles
      if (options.maxCycles !== undefined && currentCycle >= options.maxCycles) {
        break;
      }

      // Sleep between cycles
      const nextScanAt = new Date(Date.now() + interval * 1000).toISOString();
      writeDaemonStatus(statusFile, makeStatus("sleeping", nextScanAt));
      await interruptibleSleep(interval, shouldStop);
    }
  } finally {
    // Clean up signal handlers
    process.off("SIGTERM", onSignal);
    process.off("SIGINT", onSignal);

    // Write final status unless we already wrote budget_exceeded
    const currentStatus = readDaemonStatus(statusFile);
    if (currentStatus?.status !== "budget_exceeded") {
      writeDaemonStatus(statusFile, makeStatus("stopped"));
    }
  }
}

/**
 * Stop a running daemon by sending SIGTERM to its PID.
 * The daemon's signal handler sets the stopping flag, allowing graceful shutdown.
 */
export async function stopDaemon(statusFile: string): Promise<void> {
  const status = readDaemonStatus(statusFile);
  if (!status) {
    throw new Error(`No daemon status file found: ${statusFile}`);
  }

  const pid = status.daemon_pid;
  if (!pid) {
    throw new Error(`No daemon PID in status file: ${statusFile}`);
  }

  // Check if the process is alive
  try {
    process.kill(pid, 0);
  } catch {
    throw new Error(`Daemon (PID ${pid}) is not running`);
  }

  // Send SIGTERM for graceful shutdown
  process.kill(pid, "SIGTERM");
}
