'use strict';

/**
 * Auth step logic for genie-team.yml.
 *
 * Checks whether the given actor is a member of the given GitHub org.
 * Uses the Octokit REST client (injected for testability).
 *
 * Status semantics (per GitHub API docs):
 *   204 → member (Octokit resolves)
 *   302 → not a member (public org; Octokit throws with status 302)
 *   404 → not a member (private org or user not found; Octokit throws with status 404)
 *   5xx → unexpected error — must propagate (not silently dropped)
 *
 * @param {object} github    - Octokit REST client (github.rest.orgs.checkMembershipForUser)
 * @param {string} actor     - GitHub username to check
 * @param {string} org       - GitHub org name
 * @returns {Promise<{ authorized: boolean }>}
 */
async function checkMembership(github, actor, org) {
  try {
    await github.rest.orgs.checkMembershipForUser({ org, username: actor });
    // Resolved without throwing → 204 (member confirmed)
    return { authorized: true };
  } catch (err) {
    if (err.status === 302 || err.status === 404) {
      // Non-member — silently drop (by design)
      return { authorized: false };
    }
    // Unexpected error (5xx, network failure, etc.) — propagate so it is visible
    throw err;
  }
}

module.exports = checkMembership;
