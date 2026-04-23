/**
 * Convert a string to a git-ref-safe slug.
 * Matches the behavior of the bash sanitize_slug() function.
 */
export function sanitizeSlug(raw: string): string {
  return raw
    .toLowerCase()
    .replace(/[^a-z0-9._-]/g, "-")
    .replace(/-{2,}/g, "-")
    .replace(/^-/, "")
    .replace(/-$/, "")
    .slice(0, 60);
}
