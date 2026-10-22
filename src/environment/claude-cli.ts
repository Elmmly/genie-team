import { execa } from "execa";

/** Environment variable that pins the Claude Code executable genies run. */
export const CLAUDE_PATH_ENV = "GENIE_CLAUDE_PATH";

/** Looks a binary up on PATH; resolves to its absolute path or undefined. */
export type WhichFn = (bin: string) => Promise<string | undefined>;

async function whichOnPath(bin: string): Promise<string | undefined> {
  const lookup = process.platform === "win32" ? "where" : "which";
  try {
    const { stdout } = await execa(lookup, [bin]);
    const first = stdout.split(/\r?\n/)[0]?.trim();
    return first || undefined;
  } catch {
    return undefined;
  }
}

/**
 * Resolve the Claude Code executable the SDK should run.
 *
 * Order: GENIE_CLAUDE_PATH, then the `claude` on PATH. Returns undefined
 * when neither is available, in which case the SDK falls back to the copy
 * bundled with the package. Preferring the installed CLI means genies
 * track whatever version the user keeps current with `claude update`
 * instead of the version the SDK happened to ship with.
 */
export async function resolveClaudeExecutable(
  env: NodeJS.ProcessEnv = process.env,
  which: WhichFn = whichOnPath,
): Promise<string | undefined> {
  const pinned = env[CLAUDE_PATH_ENV]?.trim();
  if (pinned) return pinned;
  return which("claude");
}
