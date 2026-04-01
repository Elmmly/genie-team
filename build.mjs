import { build } from "esbuild";
import { writeFileSync, readFileSync, chmodSync } from "node:fs";

await build({
  entryPoints: ["src/index.ts"],
  bundle: true,
  platform: "node",
  target: "node20",
  format: "cjs",
  outfile: "dist/cli.cjs",
  logOverride: { "empty-import-meta": "silent" },
});

// Prepend shebang (esbuild banner + CJS can double-emit)
const code = readFileSync("dist/cli.cjs", "utf-8");
writeFileSync("dist/cli.cjs", `#!/usr/bin/env node\n${code}`);
chmodSync("dist/cli.cjs", 0o755);

console.log("Built dist/cli.cjs");
