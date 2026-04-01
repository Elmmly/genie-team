import { build } from "esbuild";
import { chmodSync } from "node:fs";

await build({
  entryPoints: ["src/index.ts"],
  bundle: true,
  platform: "node",
  target: "node20",
  format: "cjs",
  outfile: "dist/cli.cjs",
  banner: { js: "#!/usr/bin/env node" },
  logOverride: { "empty-import-meta": "silent" },
});

chmodSync("dist/cli.cjs", 0o755);
console.log("Built dist/cli.cjs");
