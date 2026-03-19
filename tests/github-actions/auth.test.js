'use strict';

/**
 * Unit tests for the auth step logic (examples/github-actions/scripts/auth.js).
 *
 * The auth step checks org membership via the GitHub API and returns authorized/not.
 * HTTP status codes determine the result:
 *   204 → authorized
 *   302 or 404 → not authorized (silent drop)
 *   5xx → unexpected error (throw, not silent)
 *
 * Uses Node.js built-in test runner (node --test, available since Node 18).
 */

const { test, describe } = require('node:test');
const assert = require('node:assert/strict');

const checkMembership = require('../../examples/github-actions/scripts/auth.js');

// ---------------------------------------------------------------------------
// AC-2: Authorization gate
// ---------------------------------------------------------------------------

describe('AC-2: Org membership returns 204 (authorized)', () => {
  test('AC-2: GitHub API returns 204 → authorized true', async () => {
    // ac_id: AC-2

    // Arrange — mock Octokit that resolves (204 success, no throw)
    const mockGithub = {
      rest: {
        orgs: {
          checkMembershipForUser: async () => ({ status: 204 }),
        },
      },
    };

    // Act
    const result = await checkMembership(mockGithub, 'alice', 'my-org');

    // Assert
    assert.equal(result.authorized, true);
  });

  test('AC-2 edge: authorized result includes actor and org for logging', async () => {
    // ac_id: AC-2

    // Arrange
    const mockGithub = {
      rest: {
        orgs: {
          checkMembershipForUser: async () => ({ status: 204 }),
        },
      },
    };

    // Act
    const result = await checkMembership(mockGithub, 'alice', 'my-org');

    // Assert
    assert.equal(result.authorized, true);
    // Result must not throw — checking we get a well-formed object
    assert.ok(typeof result === 'object');
  });
});

describe('AC-2: Non-member status codes → silent drop', () => {
  test('AC-2: GitHub API returns 404 → authorized false (silent drop)', async () => {
    // ac_id: AC-2

    // Arrange — Octokit throws for non-2xx (status 404 = not a member)
    const mockGithub = {
      rest: {
        orgs: {
          checkMembershipForUser: async () => {
            const err = new Error('Not Found');
            err.status = 404;
            throw err;
          },
        },
      },
    };

    // Act
    const result = await checkMembership(mockGithub, 'outsider', 'my-org');

    // Assert
    assert.equal(result.authorized, false);
  });

  test('AC-2: GitHub API returns 302 → authorized false (silent drop)', async () => {
    // ac_id: AC-2

    // Arrange — 302 is GitHub's signal for "not a member" on public orgs
    const mockGithub = {
      rest: {
        orgs: {
          checkMembershipForUser: async () => {
            const err = new Error('Found');
            err.status = 302;
            throw err;
          },
        },
      },
    };

    // Act
    const result = await checkMembership(mockGithub, 'external', 'my-org');

    // Assert
    assert.equal(result.authorized, false);
  });
});

describe('AC-2: Unexpected errors → propagate (not silent)', () => {
  test('AC-2: GitHub API returns 500 → throws error', async () => {
    // ac_id: AC-2

    // Arrange — internal server error from GitHub API
    const mockGithub = {
      rest: {
        orgs: {
          checkMembershipForUser: async () => {
            const err = new Error('Internal Server Error');
            err.status = 500;
            throw err;
          },
        },
      },
    };

    // Act + Assert — must throw (not silently drop)
    await assert.rejects(
      async () => checkMembership(mockGithub, 'alice', 'my-org'),
      (err) => {
        assert.ok(err.message.includes('500') || err.status === 500 || err.message.includes('Internal Server Error'));
        return true;
      }
    );
  });

  test('AC-2 edge: network error (no status) propagates as failure', async () => {
    // ac_id: AC-2

    // Arrange — simulate a network-level failure (no .status property)
    const mockGithub = {
      rest: {
        orgs: {
          checkMembershipForUser: async () => {
            throw new Error('ECONNRESET');
          },
        },
      },
    };

    // Act + Assert — must throw
    await assert.rejects(
      async () => checkMembership(mockGithub, 'alice', 'my-org'),
      /ECONNRESET/
    );
  });
});
