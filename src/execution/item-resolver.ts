import { readdir } from "node:fs/promises";
import { join, basename } from "node:path";
import { readFrontmatter } from "../core/frontmatter.js";
import type { PhaseName } from "../config/phase-config.js";
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
}

/**
 * Scan docs/backlog/ for actionable items and map each to its starting phase.
 */
export async function resolveItems(
  projectRoot: string,
  options?: ResolveOptions,
): Promise<BatchItem[]> {
  const backlogDir = join(projectRoot, "docs", "backlog");
  let files: string[];

  try {
    const entries = await readdir(backlogDir);
    files = entries.filter((f) => f.endsWith(".md"));
  } catch {
    return [];
  }

  const items: BatchItem[] = [];

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
    items.push({ slug, input: filePath, phase });
  }

  return items;
}
