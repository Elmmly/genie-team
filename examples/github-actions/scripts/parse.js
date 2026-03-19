'use strict';

/**
 * Parse step logic for genie-slash.yml.
 *
 * Extracts the genie phase from a comment body and validates it against the
 * comment context (issue vs PR). This is the pure logic extracted from the
 * actions/github-script step for testability.
 *
 * @param {string} body      - The raw comment body (may have leading whitespace)
 * @param {boolean} isPR     - True if the comment is on a PR, false if on an issue
 * @returns {{ valid: false } | { valid: true, phase: string, is_pr: boolean }}
 */
function parse(body, isPR) {
  // Trim to handle leading whitespace from mobile UIs or copy-paste
  const trimmed = (body || '').trim();

  // Extract phase from "/genie <phase>" — case-insensitive match
  const match = trimmed.match(/^\/genie\s+(\w+)/i);
  if (!match) {
    return { valid: false };
  }

  const phase = match[1].toLowerCase();

  // Only recognized phases in v1
  const validPhases = ['discover', 'discern'];
  if (!validPhases.includes(phase)) {
    return { valid: false };
  }

  // Phase/context validation:
  //   discover → issues only (not PRs)
  //   discern  → PRs only (not issues)
  if (phase === 'discover' && isPR) {
    return { valid: false };
  }
  if (phase === 'discern' && !isPR) {
    return { valid: false };
  }

  return { valid: true, phase, is_pr: isPR };
}

module.exports = parse;
