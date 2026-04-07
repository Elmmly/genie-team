import { Command, InvalidArgumentError } from "commander";
import { existsSync, readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";
import { loadGenieConfig } from "./config/genie-config.js";
import { formatModelsTable } from "./environment/models.js";
import { runChecks, formatCheckResult } from "./environment/check.js";
import { isValidPhase, type PhaseName } from "./config/phase-config.js";
import { executeSingleItem, type ExecutionOptions, type SingleItemOptions } from "./execution/single-item.js";
import { runDaemonCycle, type DaemonOptions } from "./execution/daemon.js";
import { runDaemon, stopDaemon, readDaemonStatus, type ContinuousDaemonOptions } from "./execution/daemon-loop.js";
import { listSessions, sessionCleanup, type FinishMode } from "./git/worktree.js";
import { resolveAuth } from "./environment/auth.js";
import { readBatchStatus, formatStatusTable, formatStatusJson } from "./status/batch-status.js";
import { runRecovery, type RecoveryOptions } from "./execution/recovery.js";
import { runQualityChecks } from "./execution/quality.js";
import { acquireLock } from "./execution/lockfile.js";

function loadVersion(): string {
  try {
    const __filename = fileURLToPath(import.meta.url);
    const __dirname = dirname(__filename);
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
    .name("genies")
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

  /** Raw CLI flags shared by run and daemon commands. */
  interface SharedCliOpts {
    model?: string;
    turns?: string;
    resume: boolean;
    trunk?: true;
    budget?: string;
    reviewCycles?: string;
    skipPermissions?: true;
    logDir?: string;
    auth?: "oauth" | "apikey";
    verbose?: true;
    dryRun?: true;
    worktree: boolean;
    finishMode?: string;
    minPhase?: PhaseName;
    continueOnFailure?: true;
    cleanupOnFailure?: true;
    slug?: string;
    lock?: true;
    preflight: boolean;
    discoverTurns?: string;
    defineTurns?: string;
    designTurns?: string;
    deliverTurns?: string;
    discernTurns?: string;
    commitTurns?: string;
    doneTurns?: string;
    deliverMinTurns?: string;
  }

  function parseIntArg(value: string, name: string): number {
    const n = parseInt(value, 10);
    if (Number.isNaN(n) || n <= 0) {
      throw new InvalidArgumentError(`${name} must be a positive integer, got "${value}"`);
    }
    return n;
  }

  function parseFloatArg(value: string, name: string): number {
    const n = parseFloat(value);
    if (Number.isNaN(n) || n <= 0) {
      throw new InvalidArgumentError(`${name} must be a positive number, got "${value}"`);
    }
    return n;
  }

  function parseFinishMode(value: string): FinishMode {
    const valid: FinishMode[] = ["pr", "merge", "leave-branch"];
    if (!valid.includes(value as FinishMode)) {
      throw new InvalidArgumentError(
        `Invalid finish mode "${value}". Valid modes: ${valid.join(", ")}`,
      );
    }
    return value as FinishMode;
  }

  /** Convert raw CLI strings to typed ExecutionOptions. */
  function parseExecutionOpts(opts: SharedCliOpts): ExecutionOptions {
    // Validate auth config early (throws if --auth apikey without ANTHROPIC_API_KEY)
    if (opts.auth) resolveAuth(opts.auth);

    const exec: ExecutionOptions = {
      hasContextDir: existsSync(join(process.cwd(), "docs", "context")) || undefined,
    };
    if (opts.auth) exec.authMode = opts.auth;
    if (opts.model) exec.model = opts.model;
    if (!opts.resume) exec.noResume = true;
    if (opts.trunk) exec.trunkMode = true;
    if (opts.budget) exec.maxBudgetUsd = parseFloatArg(opts.budget, "--budget");
    if (opts.reviewCycles) exec.reviewCycles = parseIntArg(opts.reviewCycles, "--review-cycles");
    if (opts.skipPermissions) exec.skipPermissions = true;
    if (opts.logDir) exec.logDir = opts.logDir;
    if (opts.verbose) exec.verbose = true;
    if (opts.dryRun) exec.dryRun = true;
    if (!opts.worktree) exec.noWorktree = true;
    if (opts.finishMode) exec.finishMode = parseFinishMode(opts.finishMode);
    if (opts.minPhase) exec.minPhase = opts.minPhase;
    if (opts.continueOnFailure) exec.continueOnFailure = true;
    if (opts.cleanupOnFailure) exec.cleanupOnFailure = true;
    if (opts.slug) exec.worktreeSlug = opts.slug;
    if (opts.lock) exec.useLock = true;
    if (!opts.preflight) exec.noPreflight = true;
    if (opts.deliverMinTurns) exec.deliverMinTurns = parseIntArg(opts.deliverMinTurns, "--deliver-min-turns");

    // Build turn overrides: global + per-phase
    const turnOverrides: Record<string, number> = {};
    if (opts.turns) turnOverrides.global = parseIntArg(opts.turns, "--turns");
    if (opts.discoverTurns) turnOverrides.discover = parseIntArg(opts.discoverTurns, "--discover-turns");
    if (opts.defineTurns) turnOverrides.define = parseIntArg(opts.defineTurns, "--define-turns");
    if (opts.designTurns) turnOverrides.design = parseIntArg(opts.designTurns, "--design-turns");
    if (opts.deliverTurns) turnOverrides.deliver = parseIntArg(opts.deliverTurns, "--deliver-turns");
    if (opts.discernTurns) turnOverrides.discern = parseIntArg(opts.discernTurns, "--discern-turns");
    if (opts.commitTurns) turnOverrides.commit = parseIntArg(opts.commitTurns, "--commit-turns");
    if (opts.doneTurns) turnOverrides.done = parseIntArg(opts.doneTurns, "--done-turns");
    if (Object.keys(turnOverrides).length > 0) exec.turnOverrides = turnOverrides;

    return exec;
  }

  /** Add shared execution flags to a commander command. */
  function addExecutionFlags(cmd: Command): Command {
    return cmd
      .option("--model <model>", "Model override (e.g. claude-sonnet-4-5-20250514)")
      .option("--turns <n>", "Global turn limit override")
      .option("--no-resume", "Start fresh sessions (disable cross-phase resume)")
      .option("--trunk", "Use trunk-based mode (commit to default branch)")
      .option("--budget <usd>", "Max budget in USD per session")
      .option("--review-cycles <n>", "Max deliver↔discern review cycles")
      .option("--skip-permissions", "Bypass permission prompts")
      .option("--log-dir <dir>", "Directory for structured JSON cost logs")
      .option("--auth <mode>", "Auth mode (oauth|apikey)")
      .option("--verbose", "Show phase progress on stderr")
      .option("--dry-run", "Preview matching items without executing")
      .option("--no-worktree", "Disable worktree isolation")
      .option("--finish-mode <mode>", "Worktree finish mode (pr|merge|leave-branch)")
      .option("--min-phase <phase>", "Batch floor: never start earlier than this phase", parsePhase)
      .option("--continue-on-failure", "Don't stop on first failure")
      .option("--cleanup-on-failure", "Remove worktree on failure")
      .option("--slug <slug>", "Custom worktree slug")
      .option("--lock", "Enable lockfile")
      .option("--no-preflight", "Skip environment validation before execution")
      .option("--discover-turns <n>", "Turn limit for discover phase")
      .option("--define-turns <n>", "Turn limit for define phase")
      .option("--design-turns <n>", "Turn limit for design phase")
      .option("--deliver-turns <n>", "Turn limit for deliver phase")
      .option("--discern-turns <n>", "Turn limit for discern phase")
      .option("--commit-turns <n>", "Turn limit for commit phase")
      .option("--done-turns <n>", "Turn limit for done phase")
      .option("--deliver-min-turns <n>", "Minimum turns for deliver phase");
  }

  interface RunOpts extends SharedCliOpts {
    from: PhaseName;
    through: PhaseName;
  }

  addExecutionFlags(
    program
      .command("run")
      .description("Run a backlog item through PDLC phases")
      .argument("<item>", "Backlog item path or topic string")
      .option("--from <phase>", "Starting phase", parsePhase, "discover" as PhaseName)
      .option("--through <phase>", "Ending phase", parsePhase, "done" as PhaseName),
  ).action(async (item: string, opts: RunOpts) => {
      const options: SingleItemOptions = {
        ...parseExecutionOpts(opts),
        fromPhase: opts.from,
        throughPhase: opts.through,
      };

      // Preflight: run environment checks unless --no-preflight
      if (!options.noPreflight) {
        const { exitCode } = await runChecks();
        if (exitCode !== 0) {
          console.error("Preflight checks failed. Use --no-preflight to skip.");
          process.exit(exitCode);
          return;
        }
      }

      // Lock: acquire before execution, release after
      let lockHandle: { release: () => Promise<void> } | undefined;
      if (options.useLock) {
        const slug = options.worktreeSlug ?? item.replace(/[^a-z0-9._-]/gi, "-");
        lockHandle = await acquireLock(slug, { lockDir: options.logDir });
      }

      try {
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
      } finally {
        await lockHandle?.release();
      }
    });

  interface DaemonOpts extends SharedCliOpts {
    through: PhaseName;
    finish: FinishMode;
    parallel?: string;
    priority?: string;
  }

  const daemon = program
    .command("daemon")
    .description("Daemon: one-shot cycle or continuous loop with subcommands");

  // Default action (no subcommand) — one-shot cycle for backward compatibility
  addExecutionFlags(
    daemon
      .option("--through <phase>", "Ending phase", parsePhase, "done" as PhaseName)
      .option("--finish <mode>", "Post-execution integration (pr|merge|leave-branch)", parseFinishMode, "pr" as FinishMode)
      .option("--parallel <n>", "Concurrency limit")
      .option("--priority <level>", "Filter items by priority (e.g. P0)"),
  ).action(async (opts: DaemonOpts) => {
      const options: DaemonOptions = {
        ...parseExecutionOpts(opts),
        throughPhase: opts.through,
        finishMode: opts.finish,
      };

      if (opts.parallel) options.parallel = parseIntArg(opts.parallel, "--parallel");
      if (opts.priority) options.priorities = [opts.priority];

      const result = await runDaemonCycle(options);

      const summary = [
        `Completed: ${result.itemsCompleted}`,
        `Failed: ${result.itemsFailed}`,
        `Cost: $${result.costUsd.toFixed(4)}`,
      ].join(" | ");

      console.log(summary);
      process.exit(result.exitCode);
    });

  interface DaemonStartOpts extends DaemonOpts {
    interval?: string;
    maxCycles?: string;
    maxCost?: string;
    statusFile?: string;
  }

  addExecutionFlags(
    daemon
      .command("start")
      .description("Start continuous daemon loop")
      .option("--through <phase>", "Ending phase", parsePhase, "done" as PhaseName)
      .option("--finish <mode>", "Post-execution integration (pr|merge|leave-branch)", parseFinishMode, "pr" as FinishMode)
      .option("--parallel <n>", "Concurrency limit")
      .option("--priority <level>", "Filter items by priority (e.g. P0)")
      .option("--interval <seconds>", "Seconds between cycles (default 300)")
      .option("--max-cycles <n>", "Stop after N cycles")
      .option("--max-cost <usd>", "Cost budget cap in USD")
      .option("--status-file <path>", "Path to write daemon status JSON"),
  ).action(async (opts: DaemonStartOpts) => {
      const options: ContinuousDaemonOptions = {
        ...parseExecutionOpts(opts),
        throughPhase: opts.through,
        finishMode: opts.finish,
      };

      if (opts.parallel) options.parallel = parseIntArg(opts.parallel, "--parallel");
      if (opts.priority) options.priorities = [opts.priority];
      if (opts.interval) options.interval = parseIntArg(opts.interval, "--interval");
      if (opts.maxCycles) options.maxCycles = parseIntArg(opts.maxCycles, "--max-cycles");
      if (opts.maxCost) options.maxCostUsd = parseFloatArg(opts.maxCost, "--max-cost");
      if (opts.statusFile) options.statusFile = opts.statusFile;

      await runDaemon(options);
    });

  daemon
    .command("stop")
    .description("Stop a running daemon")
    .option("--status-file <path>", "Path to daemon status JSON", "daemon-status.json")
    .action(async (opts: { statusFile: string }) => {
      try {
        await stopDaemon(opts.statusFile);
        console.log("Shutdown signal sent. Daemon will finish current phase and exit.");
      } catch (err) {
        console.error(String((err as Error).message));
        process.exit(1);
      }
    });

  daemon
    .command("status")
    .description("Show daemon status")
    .option("--status-file <path>", "Path to daemon status JSON", "daemon-status.json")
    .action((opts: { statusFile: string }) => {
      const status = readDaemonStatus(opts.statusFile);
      if (!status) {
        console.log("No daemon status found.");
        return;
      }
      const lines = [
        `Status: ${status.status}`,
        `PID: ${status.daemon_pid}`,
        `Cycle: ${status.current_cycle}`,
        `Cost: $${status.cumulative_cost_usd.toFixed(4)}`,
        `Completed: ${status.totals.completed} | Failed: ${status.totals.failed} | Stalled: ${status.totals.stalled}`,
        `Finisher recovered: ${status.totals.finisher_recovered}`,
      ];
      console.log(lines.join("\n"));
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

  program
    .command("status")
    .description("Show batch execution status from log directory")
    .option("--log-dir <dir>", "Log directory path")
    .option("--stuck-mins <n>", "Minutes before marking as stuck")
    .option("--json", "Output as JSON instead of table")
    .action(async (opts: { logDir?: string; stuckMins?: string; json?: true }) => {
      const logDir = opts.logDir ?? process.env.LOG_DIR;
      if (!logDir) {
        console.error("No log directory specified. Use --log-dir or set LOG_DIR env var.");
        process.exit(3);
        return;
      }

      const statusOpts: { stuckMins?: number } = {};
      if (opts.stuckMins) {
        statusOpts.stuckMins = parseIntArg(opts.stuckMins, "--stuck-mins");
      }

      const report = await readBatchStatus(logDir, statusOpts);

      if (opts.json) {
        console.log(formatStatusJson(report));
      } else {
        console.log(formatStatusTable(report));
      }

      process.exit(report.exitCode);
    });

  interface RecoverOpts {
    priority?: string;
    trunk?: true;
    finishMode?: string;
  }

  program
    .command("recover")
    .description("Recover orphaned genie/* branches by integrating them")
    .option("--priority <level>", "Filter branches by priority (e.g. P1)")
    .option("--trunk", "Use trunk-based integration (merge instead of PR)")
    .option("--finish-mode <mode>", "Integration mode (pr|merge|leave-branch)", parseFinishMode)
    .action(async (opts: RecoverOpts) => {
      // List genie/* branches via git
      const { execa } = await import("execa");
      const { stdout } = await execa("git", [
        "branch",
        "--list",
        "genie/*",
        "--format=%(refname:short)",
      ]);

      const branches = stdout
        .split("\n")
        .map((b) => b.trim().replace("genie/", ""))
        .filter(Boolean);

      const finishMode = opts.finishMode
        ? parseFinishMode(opts.finishMode)
        : opts.trunk
          ? ("merge" as FinishMode)
          : ("pr" as FinishMode);

      const recoveryOpts: RecoveryOptions = {
        branches,
        finishMode,
        trunkMode: opts.trunk ?? false,
        priorities: opts.priority ? [opts.priority] : undefined,
      };

      const result = await runRecovery(recoveryOpts);

      if (result.recovered.length === 0 && result.failed.length === 0) {
        console.log("No genie/* branches found. Nothing to recover.");
        return;
      }

      for (const r of result.recovered) {
        console.log(`Recovered: ${r}`);
      }
      for (const f of result.failed) {
        console.error(`Failed: ${f}`);
      }

      const summary = `Recovery complete: ${result.recovered.length} integrated, ${result.failed.length} failed`;
      console.log(summary);

      process.exit(result.failed.length > 0 ? 1 : 0);
    });

  program
    .command("quality")
    .description("Run quality validation checks (crossrefs, source sync, frontmatter)")
    .argument("[files...]", "Specific files to validate (default: all)")
    .action(async (files: string[]) => {
      const result = await runQualityChecks({
        projectRoot: process.cwd(),
        files: files.length > 0 ? files : undefined,
      });

      for (const r of result.results) {
        const status = r.exitCode === 0 ? "PASS" : "FAIL";
        console.log(`${status}  ${r.script}`);
        if (r.error) {
          console.error(`  ${r.error}`);
        }
      }

      const passed = result.results.filter((r) => r.exitCode === 0).length;
      const failed = result.results.filter((r) => r.exitCode !== 0).length;
      console.log(`\n${passed} passed, ${failed} failed`);

      process.exit(result.exitCode);
    });

  // Unknown commands exit 127 to signal shell fallback
  program.on("command:*", () => {
    process.exit(127);
  });

  return program;
}
