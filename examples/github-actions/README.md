# Genie Slash Commands — GitHub Actions

On-demand genie invocations from GitHub issue and PR comments.

## What This Does

| Comment | Where | Result |
|---------|-------|--------|
| `/genie discover` | Issue | Scout runs, posts Opportunity Snapshot |
| `/genie discern` | PR | Critic runs, posts Review Verdict |

Comments from bots and genie response comments are silently filtered. Only org members may trigger invocations.

## Setup

### Step 1: Copy the workflow file

Copy `genie-slash.yml` to `.github/workflows/genie-slash.yml` in your repository.

```bash
curl -fsSL \
  "https://raw.githubusercontent.com/Elmmly/genie-team/main/examples/github-actions/genie-slash.yml" \
  -o .github/workflows/genie-slash.yml
```

### Step 2: Add auth secrets (one path required)

Go to your repository **Settings → Secrets and variables → Actions → New repository secret**.

Choose one:

**Option A — API key** (simplest, per-token billing):
- `ANTHROPIC_API_KEY` — Your Anthropic API key from [console.anthropic.com](https://console.anthropic.com)

**Option B — OAuth subscription token** (uses your Claude Max/Pro subscription, no per-token cost):
- `CLAUDE_CODE_OAUTH_TOKEN` — from `claude setup-token`
- `CLAUDE_REFRESH_TOKEN` — from `claude setup-token`
- `CLAUDE_EXPIRES_AT` — from `claude setup-token`
- `SECRETS_ADMIN_PAT` — GitHub PAT with `secrets:write` scope (enables auto-rotation)

When OAuth secrets are present, they are used automatically. `ANTHROPIC_API_KEY` is used only when OAuth secrets are absent. You do not need both.

To generate the OAuth token bundle:
```bash
claude setup-token
# Follow prompts, then copy the three output values to repo secrets
```

### Step 3: Commit and push

```bash
git add .github/workflows/genie-slash.yml
git commit -m "feat: add genie slash command GitHub Action"
git push
```

### Step 4: Test it

Open any issue in your repository and comment `/genie discover`. Scout should respond within 3-5 minutes.


## Configuring Max Turns

The default `--max-turns` limit is 50. To change it, trigger the workflow manually via GitHub Actions UI (Actions → Genie Slash Commands → Run workflow) and specify a different value.

To change the default permanently, edit `genie-slash.yml`:
```yaml
env:
  MAX_TURNS: ${{ inputs.max_turns || '75' }}  # change 75 to your preferred default
```

## Troubleshooting

**No response after commenting `/genie discover`**
- Check the Actions tab for workflow runs. If no run appears, the `if:` filter blocked execution.
- Verify the comment actor is not a bot account (actor ending in `[bot]`).
- Verify the actor is an org member (non-members are silently dropped).
- Verify the comment starts with `/genie ` (space after "genie" is required).

**Workflow runs but posts an error comment**
- Click the workflow run link in the error comment for the full log.
- Install failures (step 4): npm install or curl may have timed out. Re-run the workflow.
- Claude failures (exit code 1): Verify your auth secret is set correctly (`ANTHROPIC_API_KEY` for API key path, or all four OAuth secrets for OAuth path).

**`/genie discover` on a PR gets no response**
- By design: `discover` is for issues only. Use `discern` on PRs.

**`/genie discern` on an issue gets no response**
- By design: `discern` is for PRs only. Use `discover` on issues.

## Security Notes

- **Prompt injection:** Issue and PR content is passed to Claude in XML-delimited context blocks. This reduces but does not eliminate prompt injection risk. All genie invocations are read-only — no write operations are performed.
- **Org membership:** Only members of the org that owns the repo may trigger invocations. This check uses `GITHUB_TOKEN` (no additional secret required).
- **SHA pinning:** For production use, pin the `install.sh` curl URL to a specific commit SHA rather than `main`:
  ```
  https://raw.githubusercontent.com/Elmmly/genie-team/<SHA>/install.sh
  ```
- **SECRETS_ADMIN_PAT:** This is a high-privilege secret. Grant it only `secrets:write` scope on the specific repository, not organization-wide.

## Architecture

This workflow uses `issue_comment` as a single event trigger for both issues and PRs (see ADR-006). The `issue.pull_request` field distinguishes PR comments from issue comments.

Auth strategy follows ADR-007: implicit dual-path with OAuth preferred when configured.

See `docs/backlog/P2-github-actions-slash-commands.md` and `docs/specs/platform/github-actions-integration.md` in the genie-team repo for full design and acceptance criteria.
