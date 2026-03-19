'use strict';

/**
 * Result posting logic for genie-slash.yml.
 *
 * Builds the formatted Markdown comment body based on the genie invocation result.
 * This is the pure logic extracted from the actions/github-script step for testability.
 *
 * The caller (workflow step) is responsible for the actual GitHub API call.
 * This module only builds and returns the comment body string.
 *
 * @param {object} ctx
 * @param {string}  ctx.phase          - 'discover' or 'discern'
 * @param {number}  ctx.issueNumber    - Issue or PR number
 * @param {string}  ctx.actor          - GitHub username who triggered the command
 * @param {boolean} ctx.installOk      - Whether the install step succeeded
 * @param {string}  ctx.exitCode       - Exit code from the claude invocation ('0', '1', etc.)
 * @param {string|null} ctx.resultContent - Raw genie output string, or null if not available
 * @param {string}  ctx.runId          - GitHub Actions run ID for the workflow run link
 * @param {string}  ctx.serverUrl      - GitHub server URL (e.g., 'https://github.com')
 * @param {string}  ctx.repository     - Repository full name (e.g., 'myorg/myrepo')
 * @param {string}  [ctx.maxTurns='50'] - Max turns used in the invocation
 * @returns {string} - The formatted comment body
 */
function buildResultComment(ctx) {
  const {
    phase,
    actor,
    installOk,
    exitCode,
    resultContent,
    runId,
    serverUrl,
    repository,
    maxTurns = '50',
  } = ctx;

  const genieNames = { discover: 'Scout', discern: 'Critic' };
  const phaseLabels = { discover: 'Opportunity Snapshot', discern: 'Review Verdict' };

  const genieName = genieNames[phase] || 'Genie';
  const phaseLabel = phaseLabels[phase] || phase;
  const runUrl = `${serverUrl}/${repository}/actions/runs/${runId}`;

  // --- Install failure path ---
  if (!installOk) {
    return [
      `<!-- genie-response phase="${phase}" status="error" -->`,
      `## ${genieName} — ${phaseLabel}`,
      '',
      '**Error:** Genie installation failed. Check the workflow run for details.',
      '',
      `[Workflow run](${runUrl})`,
      '',
      `> Triggered by @${actor} via \`/genie ${phase}\``,
    ].join('\n');
  }

  // --- Claude invocation failure path ---
  // Failure if: exit code is not '0', OR result content is null/empty
  const succeeded = exitCode === '0' && resultContent !== null && resultContent !== undefined;

  if (!succeeded) {
    let errorNote;
    if (exitCode === '1') {
      errorNote = 'The genie encountered an error during execution.';
    } else if (exitCode === '0' && !resultContent) {
      errorNote = 'The genie exited successfully but produced no output.';
    } else {
      errorNote = `The genie exited with code \`${exitCode}\`. This may indicate the session hit the \`--max-turns\` limit (${maxTurns}).`;
    }

    return [
      `<!-- genie-response phase="${phase}" status="error" -->`,
      `## ${genieName} — ${phaseLabel}`,
      '',
      `**Error:** ${errorNote}`,
      '',
      `Check the [workflow run](${runUrl}) for the full log.`,
      '',
      `> Triggered by @${actor} via \`/genie ${phase}\``,
    ].join('\n');
  }

  // --- Success path ---
  // Truncate at 65,000 chars — GitHub comment limit is 65,536 bytes
  const MAX_COMMENT = 65000;
  const displayResult = resultContent.length > MAX_COMMENT
    ? resultContent.slice(0, MAX_COMMENT) + '\n\n*[Output truncated — see workflow run for full output]*'
    : resultContent;

  return [
    `<!-- genie-response phase="${phase}" status="ok" -->`,
    `## ${genieName} — ${phaseLabel}`,
    '',
    displayResult,
    '',
    '---',
    `> Triggered by @${actor} via \`/genie ${phase}\` | [Workflow run](${runUrl})`,
  ].join('\n');
}

module.exports = buildResultComment;
