#!/usr/bin/env node
import { createCli } from "./cli.js";

// Known TypeScript subcommands. Everything else falls back to shell.
const HANDLED_COMMANDS = new Set(["check", "models"]);

const subcommand = process.argv[2];

// No args or unknown subcommand = not handled, fall back to shell
if (!subcommand || !HANDLED_COMMANDS.has(subcommand)) {
  process.exit(127);
}

const cli = createCli();
cli.parse(process.argv);
