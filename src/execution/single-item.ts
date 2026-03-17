import { runPhase, type PhaseOptions, type PhaseResult } from "../core/phase-executor.js";
import { SessionTracker } from "../core/session-tracker.js";
import {
  PHASES,
  phaseIndex,
  type PhaseName,
  type TurnOverrides,
} from "../config/phase-config.js";

export interface SingleItemOptions {
  fromPhase: PhaseName;
  throughPhase: PhaseName;
  model?: string;
  cwd?: string;
  skipPermissions?: boolean;
  trunkMode?: boolean;
  hasContextDir?: boolean;
  noResume?: boolean;
  turnOverrides?: TurnOverrides;
  reviewCycles?: number;
  maxBudgetUsd?: number;
  logDir?: string;
}

export interface PhaseRecord {
  phase: PhaseName;
  result: PhaseResult;
  durationMs: number;
}

export interface SingleItemResult {
  exitCode: number;
  verdict?: string;
  totalCostUsd: number;
  phaseResults: PhaseRecord[];
}

type Verdict = "APPROVED" | "BLOCKED" | "CHANGES_REQUESTED" | undefined;

function detectVerdict(output: string): Verdict {
  const upper = output.toUpperCase();
  if (upper.includes("APPROVED")) return "APPROVED";
  if (upper.includes("BLOCKED")) return "BLOCKED";
  if (upper.includes("CHANGES REQUESTED") || upper.includes("CHANGES_REQUESTED"))
    return "CHANGES_REQUESTED";
  return undefined;
}

/**
 * Execute a single backlog item through a range of PDLC phases.
 *
 * Orchestrates: phase loop → runPhase → session tracking → verdict
 * detection → review cycles (deliver ↔ discern).
 */
export async function executeSingleItem(
  input: string,
  options: SingleItemOptions,
): Promise<SingleItemResult> {
  const fromIdx = phaseIndex(options.fromPhase);
  const throughIdx = phaseIndex(options.throughPhase);
  const tracker = new SessionTracker({ noResume: options.noResume });
  const maxReviewCycles = options.reviewCycles ?? 1;

  const phaseResults: PhaseRecord[] = [];
  let totalCostUsd = 0;
  let verdict: Verdict;
  let exitCode = 0;

  for (let i = fromIdx; i <= throughIdx; i++) {
    const phase = PHASES[i];
    const start = Date.now();

    const phaseOpts: PhaseOptions = {
      model: options.model,
      cwd: options.cwd,
      skipPermissions: options.skipPermissions,
      trunkMode: options.trunkMode,
      hasContextDir: options.hasContextDir,
      turnOverrides: options.turnOverrides,
      maxBudgetUsd: options.maxBudgetUsd,
      resumeSessionId: tracker.getResumeId(),
    };

    const result = await runPhase(phase, input, phaseOpts);
    const durationMs = Date.now() - start;

    tracker.record(phase, result.sessionId);
    phaseResults.push({ phase, result, durationMs });
    totalCostUsd += result.costUsd;

    // Turn exhaustion = failure
    if (result.exhausted) {
      exitCode = 1;
      break;
    }

    // Verdict detection on discern phase
    if (phase === "discern") {
      verdict = detectVerdict(result.output);

      if (verdict === "BLOCKED") {
        exitCode = 1;
        break;
      }

      if (verdict === "CHANGES_REQUESTED") {
        // Review cycle: deliver → discern loop
        let cyclesUsed = 0;
        while (verdict === "CHANGES_REQUESTED" && cyclesUsed < maxReviewCycles) {
          cyclesUsed++;

          // Re-run deliver
          const deliverStart = Date.now();
          const deliverResult = await runPhase("deliver", input, {
            ...phaseOpts,
            resumeSessionId: tracker.getResumeId(),
          });
          tracker.record("deliver", deliverResult.sessionId);
          phaseResults.push({
            phase: "deliver",
            result: deliverResult,
            durationMs: Date.now() - deliverStart,
          });
          totalCostUsd += deliverResult.costUsd;

          // Re-run discern
          const discernStart = Date.now();
          const discernResult = await runPhase("discern", input, {
            ...phaseOpts,
            resumeSessionId: tracker.getResumeId(),
          });
          tracker.record("discern", discernResult.sessionId);
          phaseResults.push({
            phase: "discern",
            result: discernResult,
            durationMs: Date.now() - discernStart,
          });
          totalCostUsd += discernResult.costUsd;

          verdict = detectVerdict(discernResult.output);
        }

        if (verdict === "BLOCKED") {
          exitCode = 1;
          break;
        }
      }
    }
  }

  return {
    exitCode,
    verdict,
    totalCostUsd,
    phaseResults,
  };
}
