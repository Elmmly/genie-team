import { runPhase, type PhaseOptions, type PhaseResult, type PhaseHooks, type ToolUseEvent } from "../core/phase-executor.js";
import { SessionTracker } from "../core/session-tracker.js";
import { createCostLogger, createArtifactTracker } from "../hooks/phase-hooks.js";
import { getFrontmatterField } from "../core/frontmatter.js";
import { extractPhaseArtifact } from "../core/artifact.js";
import type { FinishMode } from "../git/worktree.js";
import {
  PHASES,
  phaseIndex,
  getGenieName,
  getMinTurns,
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
  dryRun?: boolean;
  noWorktree?: boolean;
  finishMode?: FinishMode;
  minPhase?: PhaseName;
  continueOnFailure?: boolean;
  cleanupOnFailure?: boolean;
  worktreeSlug?: string;
  useLock?: boolean;
  noPreflight?: boolean;
  deliverMinTurns?: number;
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

function detectVerdictFromText(text: string): Verdict | undefined {
  const upper = text.toUpperCase();
  if (upper.includes("APPROVED")) return "APPROVED";
  if (upper.includes("BLOCKED")) return "BLOCKED";
  if (upper.includes("CHANGES REQUESTED") || upper.includes("CHANGES_REQUESTED"))
    return "CHANGES_REQUESTED";
  return undefined;
}

/**
 * Detect verdict with priority: frontmatter field → output text → undefined.
 */
async function detectVerdict(output: string, itemPath?: string): Promise<Verdict | undefined> {
  // Primary: frontmatter verdict field (most reliable)
  if (itemPath) {
    try {
      const fmVerdict = await getFrontmatterField(itemPath, "verdict");
      if (typeof fmVerdict === "string" && fmVerdict) {
        const normalized = fmVerdict.replace(/_/g, " ").toUpperCase();
        const parsed = detectVerdictFromText(normalized);
        if (parsed) return parsed;
      }
    } catch {
      // File may not exist or be unreadable — fall through
    }
  }

  // Fallback: parse from output text
  return detectVerdictFromText(output);
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
  // Dry-run: return early without executing any phases
  if (options.dryRun) {
    return {
      exitCode: 0,
      totalCostUsd: 0,
      phaseResults: [],
    };
  }

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
              genie: getGenieName(phase),
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
  let verdict: Verdict | undefined;
  let exitCode = 0;
  let currentInput = input;

  async function runAndRecord(phase: PhaseName, phaseInput: string): Promise<PhaseResult> {
    const start = Date.now();
    const result = await runPhase(phase, phaseInput, {
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
    const result = await runAndRecord(phase, currentInput);

    if (result.exhausted) {
      exitCode = 1;
      break;
    }

    // Min-turn enforcement: retry if phase completed too quickly
    const minTurns = phase === "deliver" && options.deliverMinTurns != null
      ? options.deliverMinTurns
      : getMinTurns(phase);
    if (minTurns > 0 && result.numTurns < minTurns) {
      if (options.verbose) {
        console.error(`[${phase}] Anomalous: ${result.numTurns} turns (minimum: ${minTurns}). Retrying with resume.`);
      }
      await runAndRecord(phase, currentInput);
    }

    // Thread artifact paths between phases
    const artifact = extractPhaseArtifact(phase, result.output);
    if (artifact) {
      currentInput = artifact;
    }

    if (phase === "discern") {
      verdict = await detectVerdict(result.output, currentInput);

      if (verdict === "BLOCKED") {
        exitCode = 1;
        break;
      }

      // Review cycle: deliver → discern loop
      let cyclesUsed = 0;
      while (verdict === "CHANGES_REQUESTED" && cyclesUsed < maxReviewCycles) {
        cyclesUsed++;
        await runAndRecord("deliver", currentInput);
        const discernResult = await runAndRecord("discern", currentInput);
        verdict = await detectVerdict(discernResult.output, currentInput);
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
