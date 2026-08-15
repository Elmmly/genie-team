'use strict';

/**
 * Unit tests for the result posting logic (examples/github-actions/scripts/post-result.js).
 *
 * The post-result step reads the genie output file (if present), formats a comment,
 * and posts it to the triggering issue/PR via the GitHub API.
 *
 * Failure modes are handled visibly (error comment posted), not silently.
 * Comment body always starts with <!-- genie-response ... --> HTML comment.
 * Comment body is truncated at 65,000 chars if the genie output is too large.
 *
 * Uses Node.js built-in test runner (node --test, available since Node 18).
 */

const { test, describe } = require('node:test');
const assert = require('node:assert/strict');

const buildResultComment = require('../../examples/github-actions/scripts/post-result.js');

// ---------------------------------------------------------------------------
// Test helpers
// ---------------------------------------------------------------------------

/**
 * Creates a minimal context object matching what the post-result script needs.
 */
function makeContext({
  phase = 'discover',
  issueNumber = 42,
  actor = 'alice',
  installOk = true,
  exitCode = '0',
  resultContent = null,
  runId = 'run-123',
  serverUrl = 'https://github.com',
  repository = 'myorg/myrepo',
} = {}) {
  return {
    phase,
    issueNumber,
    actor,
    installOk,
    exitCode,
    resultContent,
    runId,
    serverUrl,
    repository,
    maxTurns: '50',
  };
}

// ---------------------------------------------------------------------------
// AC-7: Formatted comment output
// ---------------------------------------------------------------------------

describe('AC-7: Success path — comment posted with genie output', () => {
  test('AC-7: success path posts comment with genie-response header and genie name', () => {
    // ac_id: AC-7

    // Arrange
    const ctx = makeContext({
      phase: 'discover',
      resultContent: 'This is the Scout opportunity snapshot output.',
      exitCode: '0',
      installOk: true,
    });

    // Act
    const body = buildResultComment(ctx);

    // Assert — comment begins with the HTML machine-readable marker
    assert.ok(body.startsWith('<!-- genie-response'), `Expected body to start with <!-- genie-response, got: ${body.slice(0, 80)}`);
    // Contains genie name
    assert.ok(body.includes('Scout'), 'Expected body to include "Scout"');
    // Contains the genie output
    assert.ok(body.includes('This is the Scout opportunity snapshot output.'));
    // Contains triggered-by attribution
    assert.ok(body.includes('@alice'));
  });

  test('AC-7: discern phase posts Critic name and Review Verdict label', () => {
    // ac_id: AC-7

    // Arrange
    const ctx = makeContext({
      phase: 'discern',
      resultContent: 'APPROVED. No issues found.',
      exitCode: '0',
      installOk: true,
    });

    // Act
    const body = buildResultComment(ctx);

    // Assert
    assert.ok(body.includes('Critic'));
    assert.ok(body.includes('Review Verdict'));
    assert.ok(body.includes('APPROVED. No issues found.'));
  });

  test('AC-7: success comment includes workflow run link', () => {
    // ac_id: AC-7

    // Arrange
    const ctx = makeContext({
      phase: 'discover',
      resultContent: 'Some output.',
      exitCode: '0',
      installOk: true,
      runId: 'run-abc-123',
      serverUrl: 'https://github.com',
      repository: 'myorg/myrepo',
    });

    // Act
    const body = buildResultComment(ctx);

    // Assert — workflow run link present
    assert.ok(body.includes('run-abc-123'), 'Expected workflow run ID in comment');
  });
});

describe('AC-7: Install failure → error comment', () => {
  test('AC-7: install_ok=false posts installation failed error comment', () => {
    // ac_id: AC-7

    // Arrange
    const ctx = makeContext({
      phase: 'discover',
      installOk: false,
      exitCode: '',
      resultContent: null,
    });

    // Act
    const body = buildResultComment(ctx);

    // Assert
    assert.ok(body.startsWith('<!-- genie-response'), 'Error comment must also have HTML marker');
    assert.ok(body.includes('installation failed') || body.includes('Installation failed'),
      'Expected installation failure message');
    // Must NOT include genie output (none was produced)
    assert.ok(!body.includes('undefined'));
    assert.ok(!body.includes('null'));
  });
});

describe('AC-7: Claude invocation failure → error comment with run link', () => {
  test('AC-7: exit code 1 posts error comment with workflow run link', () => {
    // ac_id: AC-7

    // Arrange
    const ctx = makeContext({
      phase: 'discover',
      installOk: true,
      exitCode: '1',
      resultContent: null,
      runId: 'run-fail-456',
      serverUrl: 'https://github.com',
      repository: 'myorg/myrepo',
    });

    // Act
    const body = buildResultComment(ctx);

    // Assert
    assert.ok(body.startsWith('<!-- genie-response'));
    // Error must mention the failure
    assert.ok(body.toLowerCase().includes('error') || body.includes('encountered'),
      'Expected error message in body');
    // Must include workflow run link
    assert.ok(body.includes('run-fail-456'), 'Expected workflow run link in error comment');
  });

  test('AC-7 edge: missing result file (exit code 0 but no content) posts error comment', () => {
    // ac_id: AC-7

    // Arrange — edge case: install ok, exit 0, but result file not present
    const ctx = makeContext({
      phase: 'discover',
      installOk: true,
      exitCode: '0',
      resultContent: null, // file not present or empty
    });

    // Act
    const body = buildResultComment(ctx);

    // Assert — should not post empty/broken output; should post an error
    assert.ok(body.startsWith('<!-- genie-response'));
    // Should contain some error indication
    assert.ok(
      body.toLowerCase().includes('error') || body.toLowerCase().includes('exited') || body.toLowerCase().includes('failed'),
      `Expected error indication in body. Got: ${body.slice(0, 200)}`
    );
  });
});

describe('AC-7: Result truncation at 65,000 chars', () => {
  test('AC-7: result exceeding 65000 chars is truncated with truncation notice', () => {
    // ac_id: AC-7

    // Arrange — generate content that exceeds 65,000 characters
    const longContent = 'A'.repeat(66000);
    const ctx = makeContext({
      phase: 'discover',
      installOk: true,
      exitCode: '0',
      resultContent: longContent,
    });

    // Act
    const body = buildResultComment(ctx);

    // Assert — body must be shorter than the full content
    assert.ok(body.length < 66000 + 1000, 'Expected body to be truncated');
    // Must include truncation notice
    assert.ok(
      body.includes('truncated') || body.includes('Truncated'),
      'Expected truncation notice in body'
    );
    // Must NOT end abruptly without notice — check notice is present
    assert.ok(body.includes('truncated'), 'Expected truncation marker');
  });

  test('AC-7 edge: result exactly at 65000 chars is NOT truncated', () => {
    // ac_id: AC-7

    // Arrange
    const exactContent = 'B'.repeat(65000);
    const ctx = makeContext({
      phase: 'discover',
      installOk: true,
      exitCode: '0',
      resultContent: exactContent,
    });

    // Act
    const body = buildResultComment(ctx);

    // Assert — no truncation notice for content at the limit
    // (The content itself is 65000 chars, which is ≤ the limit)
    assert.ok(!body.includes('[Output truncated'), 'Content at 65000 chars should not be truncated');
  });
});
