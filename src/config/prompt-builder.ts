import type { PhaseName } from "./phase-config.js";

export interface PromptOptions {
  trunkMode?: boolean;
  hasContextDir?: boolean;
}

/**
 * Build the prompt string for a phase invocation.
 *
 * Format: [context note] [git-mode prefix] /<phase> <input>
 */
export function buildPhasePrompt(
  phase: PhaseName,
  input: string,
  options?: PromptOptions,
): string {
  const parts: string[] = [];

  if (options?.hasContextDir) {
    parts.push(
      "Strategic context in docs/context/ — read relevant files before proceeding.",
    );
  }

  if (options?.trunkMode) {
    parts.push(`git-mode: trunk. /${phase} ${input}`);
  } else {
    parts.push(`/${phase} ${input}`);
  }

  return parts.join(" ");
}
