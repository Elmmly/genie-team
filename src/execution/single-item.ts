import { runPhase, type PhaseOptions, type PhaseResult, type PhaseHooks, type ToolUseEvent } from "../core/phase-executor.js";
import { SessionTracker } from "../core/session-tracker.js";
import { createCostLogger, createArtifactTracker } from "../hooks/phase-hooks.js";
import {
  PHASES,
  phaseIndex,
  type PhaseName,
  type TurnOverrides,
} from "../config/phase-config.js";

/** Shared execution options threaded from CLI through daemon → batch → single-item → runPhase. */
export interface ExecutionOptions {
  model?: string;
  cwd?: string;
  skipPermissions?: boolean;
  trunkMode?: boolean;
  noResume?: boolean;
  turnOverrides?: TurnOverrides;
  reviewCycles?: number;
  maxBudgetUsd?: number;
  logDir?: string;
  authMode?: "oauth" | "apikey";
  hasContextDir?: boolean;
  verbose?: boolean;
}

export interface SingleItemOptions extends ExecutionOptions {
  fromPhase: PhaseName;
  throughPhase: PhaseName;
}

export interface PhaseRecord {
  phase: PhaseName;
  result: PhaseResult;
  durationMs: number;
}

export type Verdict = "APPROVED" | "BLOCKED" | "CHANGES_REQUESTED";

export interface SingleItemResult {
  exitCode: number;
  verdict?: Verdict;
  totalCostUsd: number;
  phaseResults: PhaseRecord[];
  artifacts?: string[];
}

function detectVerdict(output: string): Verdict | undefined {
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

  const costLogger = options.logDir ? createCostLogger(options.logDir) : undefined;
  const artifactTracker = createArtifactTracker();

  function buildHooks(phase: PhaseName): PhaseHooks {
    const startTime = Date.now();
    return {
      onToolUse: (event: ToolUseEvent) => {
        if (event.toolName === "Write" || event.toolName === "Edit") {
          const filePath = event.toolInput.file_path as string | undefined;
          if (filePath) artifactTracker.recordWrite(filePath);
        }
      },
      onResult: costLogger
        ? (result: PhaseResult) => {
            costLogger.log({
              phase,
              genie: phase, // TODO: resolve actual genie name from phase-to-genie mapping
              turns: result.numTurns,
              inputTokens: result.inputTokens,
              outputTokens: result.outputTokens,
              costUsd: result.costUsd,
              durationMs: Date.now() - startTime,
            });
          }
        : undefined,
    };
  }

  const basePhaseOpts: Omit<PhaseOptions, "resumeSessionId" | "hooks"> = {
    model: options.model,
    cwd: options.cwd,
    skipPermissions: options.skipPermissions,
    trunkMode: options.trunkMode,
    hasContextDir: options.hasContextDir,
    turnOverrides: options.turnOverrides,
    maxBudgetUsd: options.maxBudgetUsd,
    authMode: options.authMode,
    verbose: options.verbose,
  };

  const phaseResults: PhaseRecord[] = [];
  let totalCostUsd = 0;
  let verdict: Verdict;
  let exitCode = 0;

  async function runAndRecord(phase: PhaseName): Promise<PhaseResult> {
    const start = Date.now();
    const result = await runPhase(phase, input, {
      ...basePhaseOpts,
      resumeSessionId: tracker.getResumeId(),
      hooks: buildHooks(phase),
    });
    const durationMs = Date.now() - start;

    tracker.record(phase, result.sessionId);
    phaseResults.push({ phase, result, durationMs });
    totalCostUsd += result.costUsd;
    return result;
  }

  for (let i = fromIdx; i <= throughIdx; i++) {
    const phase = PHASES[i];
    if (options.verbose) {
      console.error(`\n=== Phase: ${phase} ===`);
    }
    const result = await runAndRecord(phase);

    if (result.exhausted) {
      exitCode = 1;
      break;
    }

    if (phase === "discern") {
      verdict = detectVerdict(result.output);

      if (verdict === "BLOCKED") {
        exitCode = 1;
        break;
      }

      // Review cycle: deliver → discern loop
      let cyclesUsed = 0;
      while (verdict === "CHANGES_REQUESTED" && cyclesUsed < maxReviewCycles) {
        cyclesUsed++;
        await runAndRecord("deliver");
        const discernResult = await runAndRecord("discern");
        verdict = detectVerdict(discernResult.output);
      }

      if (verdict === "BLOCKED") {
        exitCode = 1;
        break;
      }
    }
  }

  const tracked = artifactTracker.getArtifacts();

  return {
    exitCode,
    verdict,
    totalCostUsd,
    phaseResults,
    artifacts: tracked.length > 0 ? tracked.map((a) => a.path) : undefined,
  };
}
