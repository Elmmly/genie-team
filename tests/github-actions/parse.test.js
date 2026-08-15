'use strict';

/**
 * Unit tests for the parse step logic (examples/github-actions/scripts/parse.js).
 *
 * The parse step extracts the phase from a /genie <phase> comment body and
 * validates it against context (issue vs PR). All paths either return a valid
 * result object or a {valid: false} sentinel — they never throw.
 *
 * Uses Node.js built-in test runner (node --test, available since Node 18).
 * No external dependencies required.
 */

const { test, describe } = require('node:test');
const assert = require('node:assert/strict');

// Load the module under test.
// The path is relative to this test file's location.
const parse = require('../../examples/github-actions/scripts/parse.js');

// ---------------------------------------------------------------------------
// AC-1: Comment event parsing
// ---------------------------------------------------------------------------

describe('AC-1: /genie discover on issue', () => {
  test('AC-1: parses /genie discover on issue as valid', () => {
    // ac_id: AC-1

    // Arrange
    const body = '/genie discover';
    const isPR = false;

    // Act
    const result = parse(body, isPR);

    // Assert
    assert.equal(result.valid, true);
    assert.equal(result.phase, 'discover');
    assert.equal(result.is_pr, false);
  });

  test('AC-1 edge: /genie discover with trailing text still parses phase', () => {
    // ac_id: AC-1

    // Arrange
    const body = '/genie discover please run this for me';
    const isPR = false;

    // Act
    const result = parse(body, isPR);

    // Assert
    assert.equal(result.valid, true);
    assert.equal(result.phase, 'discover');
  });
});

describe('AC-1: /genie discern on PR', () => {
  test('AC-1: parses /genie discern on PR as valid', () => {
    // ac_id: AC-1

    // Arrange
    const body = '/genie discern';
    const isPR = true;

    // Act
    const result = parse(body, isPR);

    // Assert
    assert.equal(result.valid, true);
    assert.equal(result.phase, 'discern');
    assert.equal(result.is_pr, true);
  });
});

describe('AC-1: Context mismatch — silently dropped', () => {
  test('AC-1: silently drops /genie discover on a PR', () => {
    // ac_id: AC-1

    // Arrange
    const body = '/genie discover';
    const isPR = true;

    // Act
    const result = parse(body, isPR);

    // Assert
    assert.equal(result.valid, false);
  });

  test('AC-1: silently drops /genie discern on an issue', () => {
    // ac_id: AC-1

    // Arrange
    const body = '/genie discern';
    const isPR = false;

    // Act
    const result = parse(body, isPR);

    // Assert
    assert.equal(result.valid, false);
  });
});

describe('AC-1: Unrecognized or missing phase', () => {
  test('AC-1: silently drops unrecognized phase /genie unknown', () => {
    // ac_id: AC-1

    // Arrange
    const body = '/genie unknown';
    const isPR = false;

    // Act
    const result = parse(body, isPR);

    // Assert
    assert.equal(result.valid, false);
  });

  test('AC-1: no /genie prefix returns invalid', () => {
    // ac_id: AC-1

    // Arrange — plain comment with no slash command
    const body = 'hello world';
    const isPR = false;

    // Act
    const result = parse(body, isPR);

    // Assert
    assert.equal(result.valid, false);
  });

  test('AC-1: genie response body starting with ## Scout returns invalid', () => {
    // ac_id: AC-1

    // Arrange — genie response comment body (should be blocked by workflow if: check
    // before reaching parse, but parse should also handle it defensively)
    const body = '## Scout — Opportunity Snapshot\n\nSome discovery output here...';
    const isPR = false;

    // Act
    const result = parse(body, isPR);

    // Assert
    assert.equal(result.valid, false);
  });

  test('AC-1: genie response body starting with <!-- genie-response returns invalid', () => {
    // ac_id: AC-1

    // Arrange — the HTML comment prefix used on all posted genie comments
    const body = '<!-- genie-response phase="discover" status="ok" -->\n## Scout — Opportunity Snapshot';
    const isPR = false;

    // Act
    const result = parse(body, isPR);

    // Assert
    assert.equal(result.valid, false);
  });

  test('AC-1 edge: empty body returns invalid', () => {
    // ac_id: AC-1

    // Arrange
    const body = '';
    const isPR = false;

    // Act
    const result = parse(body, isPR);

    // Assert
    assert.equal(result.valid, false);
  });

  test('AC-1 edge: /genie with no phase argument returns invalid', () => {
    // ac_id: AC-1

    // Arrange — /genie with nothing after it
    const body = '/genie';
    const isPR = false;

    // Act
    const result = parse(body, isPR);

    // Assert
    assert.equal(result.valid, false);
  });
});

describe('AC-1: Whitespace handling', () => {
  test('AC-1: trims leading whitespace before parsing', () => {
    // ac_id: AC-1

    // Arrange — body with leading whitespace (e.g., from mobile comment UI)
    const body = '  /genie discover';
    const isPR = false;

    // Act
    const result = parse(body, isPR);

    // Assert
    assert.equal(result.valid, true);
    assert.equal(result.phase, 'discover');
  });

  test('AC-1: case-insensitive phase matching', () => {
    // ac_id: AC-1

    // Arrange — some users may type DISCOVER or Discover
    const body = '/genie DISCOVER';
    const isPR = false;

    // Act
    const result = parse(body, isPR);

    // Assert
    assert.equal(result.valid, true);
    assert.equal(result.phase, 'discover');
  });
});
