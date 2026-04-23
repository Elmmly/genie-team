import { readdir, readFile } from "node:fs/promises";
import { join, basename } from "node:path";
import { readFrontmatter } from "../core/frontmatter.js";
import { phaseIndex, type PhaseName } from "../config/phase-config.js";
import { sanitizeSlug } from "../util/slug.js";
import type { BatchItem } from "./batch-executor.js";

const STATUS_TO_PHASE: Record<string, PhaseName | null> = {
  defined: "design",
  shaped: "design",
  designed: "deliver",
  implemented: "discern",
  reviewed: null,
  done: null,
  abandoned: null,
};

export interface ResolveOptions {
  priorities?: string[];
  topicsFile?: string;
  minPhase?: PhaseName;
}

/**
 * Apply minPhase floor: if the status-derived phase is earlier than minPhase,
 * bump it up to minPhase.
 */
function applyMinPhase(phase: PhaseName, minPhase?: PhaseName): PhaseName {
  if (!minPhase) return phase;
  const phaseIdx = phaseIndex(phase);
  const minIdx = phaseIndex(minPhase);
  return phaseIdx < minIdx ? minPhase : phase;
}

/**
 * Convert a topic string to a git-ref-safe slug.
 */
function topicToSlug(topic: string): string {
  return sanitizeSlug(topic.trim());
}

/**
 * Scan docs/backlog/ and docs/topics/ for actionable items and map each
 * to its starting phase. Supports topics file and minPhase floor.
 */
export async function resolveItems(
  projectRoot: string,
  options?: ResolveOptions,
): Promise<BatchItem[]> {
  const items: BatchItem[] = [];

  // If topicsFile is provided, read topics from file and return them
  // (topics file mode does not scan backlog or topics directories)
  if (options?.topicsFile) {
    const content = await readFile(options.topicsFile, "utf-8");
    const lines = content.split("\n");
    for (const line of lines) {
      const trimmed = line.trim();
      if (!trimmed || trimmed.startsWith("#")) continue;
      items.push({
        slug: topicToSlug(trimmed),
        input: trimmed,
        phase: "discover", // topics always start from discover
      });
    }
    return items;
  }

  // Scan docs/backlog/ for actionable items
  const backlogDir = join(projectRoot, "docs", "backlog");
  try {
    const entries = await readdir(backlogDir);
    const files = entries.filter((f) => f.endsWith(".md"));

    for (const file of files) {
      const filePath = join(backlogDir, file);
      const { frontmatter } = await readFrontmatter(filePath);

      const status = frontmatter.status as string | undefined;
      if (!status) continue;

      const phase = STATUS_TO_PHASE[status];
      if (!phase) continue;

      const priority = frontmatter.priority as string | undefined;
      if (options?.priorities && priority) {
        if (!options.priorities.includes(priority)) continue;
      }

      const slug = basename(file, ".md");
      items.push({
        slug,
        input: filePath,
        phase: applyMinPhase(phase, options?.minPhase),
      });
    }
  } catch {
    // backlog directory doesn't exist — skip
  }

  // Scan docs/topics/ for pending intake items
  // Topics always enter at discover phase — minPhase does not apply
  const topicsDir = join(projectRoot, "docs", "topics");
  try {
    const entries = await readdir(topicsDir);
    const files = entries.filter((f) => f.endsWith(".md"));

    for (const file of files) {
      const filePath = join(topicsDir, file);
      const { frontmatter } = await readFrontmatter(filePath);

      const status = frontmatter.status as string | undefined;
      if (status !== "pending") continue;

      const priority = frontmatter.priority as string | undefined;
      if (options?.priorities && priority) {
        if (!options.priorities.includes(priority)) continue;
      }

      const slug = basename(file, ".md");
      items.push({
        slug,
        input: filePath,
        phase: "discover", // topics always start from discover
      });
    }
  } catch {
    // topics directory doesn't exist — skip
  }

  return items;
}
