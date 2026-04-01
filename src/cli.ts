import { Command, InvalidArgumentError } from "commander";
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";
import { loadGenieConfig } from "./config/genie-config.js";
import { formatModelsTable } from "./environment/models.js";
import { runChecks, formatCheckResult } from "./environment/check.js";
import { isValidPhase, type PhaseName } from "./config/phase-config.js";
import { executeSingleItem } from "./execution/single-item.js";

function loadVersion(): string {
  const __filename = fileURLToPath(import.meta.url);
  const __dirname = dirname(__filename);
  const pkgPath = join(__dirname, "..", "package.json");
  try {
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

  program
    .command("run")
    .description("Run a backlog item through PDLC phases")
    .argument("<item>", "Backlog item path or topic string")
    .option("--from <phase>", "Starting phase", parsePhase, "discover" as PhaseName)
    .option("--through <phase>", "Ending phase", parsePhase, "done" as PhaseName)
    .action(async (item: string, opts: { from: PhaseName; through: PhaseName }) => {
      const result = await executeSingleItem(item, {
        fromPhase: opts.from,
        throughPhase: opts.through,
      });

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

  // Unknown commands exit 127 to signal shell fallback
  program.on("command:*", () => {
    process.exit(127);
  });

  return program;
}
