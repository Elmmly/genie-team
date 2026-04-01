import { Command, InvalidArgumentError } from "commander";
import { readFileSync } from "node:fs";
import { join } from "node:path";
import { loadGenieConfig } from "./config/genie-config.js";
import { formatModelsTable } from "./environment/models.js";
import { runChecks, formatCheckResult } from "./environment/check.js";
import { isValidPhase, type PhaseName } from "./config/phase-config.js";
import { executeSingleItem, type SingleItemOptions } from "./execution/single-item.js";
import { runDaemonCycle, type DaemonOptions } from "./execution/daemon.js";
import { listSessions, sessionCleanup, type FinishMode } from "./git/worktree.js";
import { resolveAuth } from "./environment/auth.js";

function loadVersion(): string {
  try {
    const pkgPath = join(__dirname, "..", "package.json");
    const pkg = JSON.parse(readFileSync(pkgPath, "utf-8"));
    return pkg.version ?? "0.0.0";
  } catch {
    return "0.0.0";
  }
}

export function createCli(): Command {
  const program = new Command();

  program
    .name("genies-core")
    .description("Genie Team — SDK-integrated orchestrator")
    .version(loadVersion());

  program
    .command("check")
    .description(
      "Run environment health checks (Claude CLI, auth, gh, MCP, install, git)"
    )
    .action(async () => {
      console.log("Environment Health Check");
      console.log("─".repeat(60));
      const { results, exitCode } = await runChecks();
      for (const r of results) {
        console.log(formatCheckResult(r));
      }
      console.log("");
      const passed = results.filter((r) => r.status === "pass").length;
      const warned = results.filter((r) => r.status === "warn").length;
      const failed = results.filter((r) => r.status === "fail").length;
      console.log(
        `${passed} passed, ${warned} warnings, ${failed} failed`,
      );
      process.exit(exitCode);
    });

  program
    .command("models")
    .description("Display model tier configuration and per-genie assignments")
    .action(() => {
      const config = loadGenieConfig();
      console.log(formatModelsTable(config));
    });

  function parsePhase(value: string): PhaseName {
    if (!isValidPhase(value)) {
      throw new InvalidArgumentError(
        `Invalid phase "${value}". Valid phases: discover, define, design, deliver, discern, commit, done`,
      );
    }
    return value;
  }

  interface RunOpts {
    from: PhaseName;
    through: PhaseName;
    model?: string;
    turns?: string;
    resume: boolean;
    trunk?: true;
    budget?: string;
    reviewCycles?: string;
    skipPermissions?: true;
    logDir?: string;
    auth?: "oauth" | "apikey";
  }

  program
    .command("run")
    .description("Run a backlog item through PDLC phases")
    .argument("<item>", "Backlog item path or topic string")
    .option("--from <phase>", "Starting phase", parsePhase, "discover" as PhaseName)
    .option("--through <phase>", "Ending phase", parsePhase, "done" as PhaseName)
    .option("--model <model>", "Model override (e.g. claude-sonnet-4-5-20250514)")
    .option("--turns <n>", "Global turn limit override")
    .option("--no-resume", "Start fresh sessions (disable cross-phase resume)")
    .option("--trunk", "Use trunk-based mode (commit to default branch)")
    .option("--budget <usd>", "Max budget in USD per session")
    .option("--review-cycles <n>", "Max deliver↔discern review cycles")
    .option("--skip-permissions", "Bypass permission prompts")
    .option("--log-dir <dir>", "Directory for structured JSON cost logs")
    .option("--auth <mode>", "Auth mode (oauth|apikey)")
    .action(async (item: string, opts: RunOpts) => {
      if (opts.auth) {
        resolveAuth(opts.auth);
      }

      const options: SingleItemOptions = {
        fromPhase: opts.from,
        throughPhase: opts.through,
      };

      if (opts.auth) options.authMode = opts.auth;
      if (opts.model) options.model = opts.model;
      if (opts.turns) options.turnOverrides = { global: parseInt(opts.turns, 10) };
      if (!opts.resume) options.noResume = true;
      if (opts.trunk) options.trunkMode = true;
      if (opts.budget) options.maxBudgetUsd = parseFloat(opts.budget);
      if (opts.reviewCycles) options.reviewCycles = parseInt(opts.reviewCycles, 10);
      if (opts.skipPermissions) options.skipPermissions = true;
      if (opts.logDir) options.logDir = opts.logDir;

      const result = await executeSingleItem(item, options);

      const phaseNames = result.phaseResults.map((r) => r.phase).join(" → ");
      const summary = [
        phaseNames ? `Phases: ${phaseNames}` : "No phases executed",
        `Cost: $${result.totalCostUsd.toFixed(4)}`,
        result.verdict ? `Verdict: ${result.verdict}` : null,
      ]
        .filter(Boolean)
        .join(" | ");

      console.log(summary);
      process.exit(result.exitCode);
    });

  function parseFinishMode(value: string): FinishMode {
    const valid: FinishMode[] = ["pr", "merge", "leave-branch"];
    if (!valid.includes(value as FinishMode)) {
      throw new InvalidArgumentError(
        `Invalid finish mode "${value}". Valid modes: ${valid.join(", ")}`,
      );
    }
    return value as FinishMode;
  }

  interface DaemonOpts {
    through: PhaseName;
    finish: FinishMode;
    parallel?: string;
    priority?: string;
    model?: string;
    trunk?: true;
    skipPermissions?: true;
    budget?: string;
    logDir?: string;
    auth?: "oauth" | "apikey";
  }

  program
    .command("daemon")
    .description("Run one daemon cycle: resolve backlog items and execute batch")
    .option("--through <phase>", "Ending phase", parsePhase, "done" as PhaseName)
    .option("--finish <mode>", "Post-execution integration (pr|merge|leave-branch)", parseFinishMode, "pr" as FinishMode)
    .option("--parallel <n>", "Concurrency limit")
    .option("--priority <level>", "Filter items by priority (e.g. P0)")
    .option("--model <model>", "Model override")
    .option("--trunk", "Use trunk-based mode")
    .option("--skip-permissions", "Bypass permission prompts")
    .option("--budget <usd>", "Max budget in USD per session")
    .option("--log-dir <dir>", "Directory for structured JSON cost logs")
    .option("--auth <mode>", "Auth mode (oauth|apikey)")
    .action(async (opts: DaemonOpts) => {
      if (opts.auth) {
        resolveAuth(opts.auth);
      }

      const options: DaemonOptions = {
        throughPhase: opts.through,
        finishMode: opts.finish,
      };

      if (opts.parallel) options.parallel = parseInt(opts.parallel, 10);
      if (opts.priority) options.priorities = [opts.priority];
      if (opts.model) options.model = opts.model;
      if (opts.trunk) options.trunkMode = true;
      if (opts.skipPermissions) options.skipPermissions = true;
      if (opts.budget) options.maxBudgetUsd = parseFloat(opts.budget);
      if (opts.logDir) options.logDir = opts.logDir;
      if (opts.auth) options.authMode = opts.auth;

      const result = await runDaemonCycle(options);

      const summary = [
        `Completed: ${result.itemsCompleted}`,
        `Failed: ${result.itemsFailed}`,
        `Cost: $${result.costUsd.toFixed(4)}`,
      ].join(" | ");

      console.log(summary);
      process.exit(result.exitCode);
    });

  const session = program
    .command("session")
    .description("Manage git worktree sessions");

  session
    .command("list")
    .description("Show active genie worktree sessions")
    .action(async () => {
      const sessions = await listSessions();
      if (sessions.length === 0) {
        console.log("No active genie sessions.");
        return;
      }
      for (const s of sessions) {
        console.log(`${s.slug}\t${s.branch}\t${s.path}`);
      }
    });

  session
    .command("cleanup [item]")
    .description("Remove stale worktree session(s)")
    .option("--all", "Clean up all genie worktree sessions")
    .action(async (item: string | undefined, opts: { all?: true }) => {
      if (opts.all) {
        const sessions = await listSessions();
        for (const s of sessions) {
          await sessionCleanup(s.slug);
          console.log(`Cleaned up: ${s.slug}`);
        }
        return;
      }
      if (!item) {
        console.error("Provide an item slug or use --all");
        process.exit(3);
        return;
      }
      await sessionCleanup(item);
      console.log(`Cleaned up: ${item}`);
    });

  // Unknown commands exit 127 to signal shell fallback
  program.on("command:*", () => {
    process.exit(127);
  });

  return program;
}
