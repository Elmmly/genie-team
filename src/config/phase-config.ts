export const PHASES = [
  "discover",
  "define",
  "design",
  "deliver",
  "discern",
  "commit",
  "done",
] as const;

export type PhaseName = (typeof PHASES)[number];

/** Ordered map for fast index lookup */
export const PHASE_ORDER: ReadonlyMap<PhaseName, number> = new Map(
  PHASES.map((p, i) => [p, i]),
);

const DEFAULT_TURNS: Record<PhaseName, number> = {
  discover: 50,
  define: 50,
  design: 50,
  deliver: 100,
  discern: 50,
  commit: 10,
  done: 20,
};

const MIN_TURNS: Record<PhaseName, number> = {
  discover: 0,
  define: 0,
  design: 0,
  deliver: 3,
  discern: 0,
  commit: 0,
  done: 0,
};

const PHASE_TOOLS: Record<PhaseName, string[]> = {
  discover: ["Read", "Grep", "Glob", "WebSearch", "WebFetch", "Task"],
  define: ["Read", "Grep", "Glob", "Write", "Task"],
  design: ["Read", "Grep", "Glob", "Write", "Edit", "Task"],
  deliver: ["Read", "Grep", "Glob", "Write", "Edit", "Bash", "Task"],
  discern: ["Read", "Grep", "Glob", "Bash", "Task"],
  commit: ["Bash"],
  done: ["Read", "Grep", "Glob", "Write", "Edit", "Bash"],
};

export type TurnOverrides = Partial<Record<PhaseName | "global", number>>;

export function isValidPhase(name: string): name is PhaseName {
  return PHASE_ORDER.has(name as PhaseName);
}

export function phaseIndex(name: PhaseName): number {
  return PHASE_ORDER.get(name) ?? -1;
}

/**
 * Resolve max turns: per-phase override > global override > default.
 */
export function getMaxTurns(
  phase: PhaseName,
  overrides?: TurnOverrides,
): number {
  const perPhase = overrides?.[phase];
  if (perPhase !== undefined) return perPhase;

  const global = overrides?.global;
  if (global !== undefined) return global;

  return DEFAULT_TURNS[phase];
}

export function getMinTurns(phase: PhaseName): number {
  return MIN_TURNS[phase];
}

export function getPhaseTools(phase: PhaseName): string[] {
  return PHASE_TOOLS[phase];
}
