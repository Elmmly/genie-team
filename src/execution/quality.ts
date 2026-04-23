import { join } from "node:path";
import { execa } from "execa";

export const VALIDATORS = [
  "check-crossrefs.sh",
  "check-source-sync.sh",
  "lint-frontmatter-yaml.sh",
  "validate-frontmatter.sh",
] as const;

export interface QualityOptions {
  projectRoot: string;
  files?: string[];
}

export interface ValidatorResult {
  script: string;
  exitCode: number;
  error?: string;
}

export interface QualityResult {
  results: ValidatorResult[];
  exitCode: number;
}

/**
 * Run quality validation scripts from scripts/validate/.
 * Each validator is run independently; failures do not stop subsequent validators.
 */
export async function runQualityChecks(
  options: QualityOptions,
): Promise<QualityResult> {
  const results: ValidatorResult[] = [];
  let hasFailure = false;

  for (const script of VALIDATORS) {
    const scriptPath = join(options.projectRoot, "scripts", "validate", script);
    const args = options.files ?? [];

    try {
      const proc = await execa(scriptPath, args, {
        cwd: options.projectRoot,
        reject: true,
      });
      results.push({
        script,
        exitCode: proc.exitCode ?? 0,
      });
    } catch (err: unknown) {
      hasFailure = true;
      const exitCode = (err as { exitCode?: number }).exitCode ?? 1;
      const message = err instanceof Error ? err.message : String(err);
      results.push({
        script,
        exitCode,
        error: message,
      });
    }
  }

  return {
    results,
    exitCode: hasFailure ? 1 : 0,
  };
}
