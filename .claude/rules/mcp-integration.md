# MCP Integration Opportunities

Model Context Protocol (MCP) servers can extend Genie Team with external integrations.

## Recommended MCP Servers

### GitHub Integration
Connect backlog items to GitHub issues and PRs:
```bash
claude mcp add github -- npx -y @anthropic-ai/mcp-server-github
```

**Benefits:**
- `/discover` can pull from GitHub issues
- `/commit` can link to backlog items
- `/discern` can post review comments to PRs

### Filesystem (for documentation)
Enhanced file operations for document management:
```bash
claude mcp add filesystem -- npx -y @anthropic-ai/mcp-server-filesystem /path/to/docs
```

### Slack (team notifications)
Notify team on workflow transitions:
```bash
claude mcp add slack -- npx -y @anthropic-ai/mcp-server-slack
```

**Use cases:**
- Notify on `/discern` APPROVED
- Alert on BLOCKED reviews
- Share `/done` completions

### Linear/Jira (project management)
Sync backlog with project management tools:
```bash
# Example for Linear
claude mcp add linear -- npx -y mcp-server-linear
```

## Configuration Pattern

Add MCP servers to `.claude/settings.json`:
```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@anthropic-ai/mcp-server-github"],
      "env": {
        "GITHUB_TOKEN": "${GITHUB_TOKEN}"
      }
    }
  }
}
```

## Workflow Integration Points

| Genie Command | MCP Integration |
|---------------|-----------------|
| `/discover [topic]` | Pull GitHub issues, fetch external research |
| `/define [input]` | Create/update Linear tickets |
| `/commit [item]` | Create GitHub PR, link to issue |
| `/discern [impl]` | Post review to GitHub PR |
| `/done [item]` | Close GitHub issue, notify Slack |

## Security Considerations

- Store tokens in environment variables, not settings files
- Use project-scoped MCP servers (not global)
- Review MCP server permissions before installing
