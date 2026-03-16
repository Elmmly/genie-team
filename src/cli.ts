import { Command } from "commander";
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";
import { loadGenieConfig } from "./config/genie-config.js";
import { formatModelsTable } from "./environment/models.js";
import { runChecks, formatCheckResult } from "./environment/check.js";

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

  // Unknown commands exit 127 to signal shell fallback
  program.on("command:*", () => {
    process.exit(127);
  });

  return program;
}
