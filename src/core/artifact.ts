/**
 * Extract artifact paths from phase output text.
 * Matches patterns like docs/analysis/... or docs/backlog/...
 */
export function parseArtifactPath(
  output: string,
  type: "analysis" | "backlog",
): string | undefined {
  const regex = new RegExp(`docs/${type}/[^ )"']+`, "g");
  const match = regex.exec(output);
  return match ? match[0] : undefined;
}

/**
 * Map phase → expected artifact type for threading.
 * discover produces analysis docs, define produces backlog items.
 */
const PHASE_ARTIFACT_TYPE: Record<string, "analysis" | "backlog" | undefined> = {
  discover: "analysis",
  define: "backlog",
};

/**
 * Extract the artifact path from a phase's output for threading to the next phase.
 */
export function extractPhaseArtifact(
  phase: string,
  output: string,
): string | undefined {
  const type = PHASE_ARTIFACT_TYPE[phase];
  if (!type) return undefined;
  return parseArtifactPath(output, type);
}
