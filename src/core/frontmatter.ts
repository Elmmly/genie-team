import yaml from "js-yaml";
import { readFile, writeFile, rename } from "node:fs/promises";
import { join, dirname, basename } from "node:path";
import { randomBytes } from "node:crypto";

export type Frontmatter = Record<string, unknown>;

export interface ParsedDocument {
  frontmatter: Frontmatter;
  body: string;
}

const DELIMITER = "---";

/**
 * Parse markdown string into frontmatter + body.
 */
export function parseFrontmatter(content: string): ParsedDocument {
  if (!content.startsWith(`${DELIMITER}\n`)) {
    return { frontmatter: {}, body: content };
  }

  const endIndex = content.indexOf(`\n${DELIMITER}\n`, DELIMITER.length);
  if (endIndex === -1) {
    return { frontmatter: {}, body: content };
  }

  const yamlBlock = content.slice(DELIMITER.length + 1, endIndex);
  const body = content.slice(endIndex + DELIMITER.length + 2);

  const parsed = yaml.load(yamlBlock);
  const frontmatter =
    parsed && typeof parsed === "object"
      ? (parsed as Frontmatter)
      : {};

  return { frontmatter, body };
}

/**
 * Serialize ParsedDocument back to markdown string.
 */
export function stringifyFrontmatter(doc: ParsedDocument): string {
  const hasFields = Object.keys(doc.frontmatter).length > 0;
  const yamlStr = hasFields
    ? yaml.dump(doc.frontmatter, { lineWidth: -1 }).trimEnd() + "\n"
    : "";

  return `${DELIMITER}\n${yamlStr}${DELIMITER}\n${doc.body}`;
}

/**
 * Read and parse a markdown file.
 */
export async function readFrontmatter(
  filePath: string,
): Promise<ParsedDocument> {
  const content = await readFile(filePath, "utf-8");
  return parseFrontmatter(content);
}

/**
 * Write atomically: temp file in same directory + rename.
 */
export async function writeFrontmatter(
  filePath: string,
  doc: ParsedDocument,
): Promise<void> {
  const content = stringifyFrontmatter(doc);
  const tmpName = `.${basename(filePath)}.${randomBytes(6).toString("hex")}.tmp`;
  const tmpPath = join(dirname(filePath), tmpName);

  await writeFile(tmpPath, content, "utf-8");
  await rename(tmpPath, filePath);
}

/**
 * Read a single frontmatter field.
 */
export async function getFrontmatterField(
  filePath: string,
  field: string,
): Promise<unknown> {
  const doc = await readFrontmatter(filePath);
  return doc.frontmatter[field];
}

/**
 * Update a single frontmatter field atomically.
 */
export async function setFrontmatterField(
  filePath: string,
  field: string,
  value: unknown,
): Promise<void> {
  const doc = await readFrontmatter(filePath);
  doc.frontmatter[field] = value;
  await writeFrontmatter(filePath, doc);
}
