#!/usr/bin/env node
import { createCli } from "./cli.js";

// Known TypeScript subcommands. Everything else falls back to shell.
const HANDLED_COMMANDS = new Set(["check", "models", "run", "daemon", "session"]);
// Global flags handled by genies-core directly
const GLOBAL_FLAGS = new Set(["--version", "-V"]);

const subcommand = process.argv[2];

// No args or unknown subcommand = not handled, fall back to shell.
// --help falls through to shell (shell has the complete help text).
if (
  !subcommand ||
  (!HANDLED_COMMANDS.has(subcommand) && !GLOBAL_FLAGS.has(subcommand))
) {
  process.exit(127);
}

const cli = createCli();
cli.parse(process.argv);
