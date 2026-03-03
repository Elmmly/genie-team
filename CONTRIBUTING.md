# Contributing to Genie Team

Thanks for your interest in contributing! Genie Team is an experiment in structured human-AI collaboration, and contributions that extend that exploration are welcome.

## Getting Started

1. Fork the repo and clone your fork
2. Run the installer to set up your local environment:
   ```bash
   ./install.sh global
   ```
3. Start a Claude Code session and load context:
   ```bash
   claude
   > /context:load
   ```

## What You'll Need

- **[Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code)** (v1.0.33+)
- **[`gh` CLI](https://cli.github.com/)** (for PR workflows)
- A text editor (this is a prompt engineering project — the primary artifacts are markdown files)

## Project Structure

This is a **prompt engineering** project. The primary artifacts are markdown and YAML prompt definitions — there is no build step. See the [README](README.md#structure) for the full directory layout.

Key directories for contributions:
- `commands/` — Slash command definitions
- `agents/` — Genie (specialist) definitions
- `skills/` — Automatic behavior skills
- `rules/` — Always-on constraints
- `schemas/` — Document format schemas

## How to Contribute

### Reporting Issues

Open an issue on GitHub with:
- A clear description of the problem or suggestion
- Steps to reproduce (for bugs)
- Expected vs actual behavior
- Which genie or command is involved

### Submitting Changes

1. Create a feature branch from `main`
2. Make your changes following the conventions below
3. Test your changes by running the relevant commands in a Claude Code session
4. Submit a PR with a clear description of what and why

### Conventions

- **Vocabulary**: Use "genie" / "genies" in all user-facing text (not "agent"). The `.claude/agents/` path is a platform implementation detail.
- **Commit messages**: Follow [Conventional Commits](https://www.conventionalcommits.org/) (`feat:`, `fix:`, `docs:`, `refactor:`, etc.)
- **Document trail**: All project knowledge lives in `docs/` under git. See [CLAUDE.md](CLAUDE.md) for the directory layout.
- **Testing**: Run `make test` to validate schemas and prompt structure.

### What Makes a Good Contribution

- Bug fixes with clear reproduction steps
- New skills or command improvements with documented behavior
- Schema improvements that maintain backward compatibility
- Documentation improvements
- Workflow enhancements that follow the 7 D's lifecycle pattern

## Code of Conduct

This project follows the [Contributor Covenant Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code.

## License

By contributing, you agree that your contributions will be licensed under the [MIT License](LICENSE).
