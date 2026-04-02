import { readFile, writeFile, mkdir } from "node:fs/promises";
import { dirname, join } from "node:path";
import { exec } from "node:child_process";
import { promisify } from "node:util";
import { glob } from "glob";
import type { Tool, ToolExecutor } from "./llm-types.js";

const execAsync = promisify(exec);

const TOOL_DEFINITIONS: Tool[] = [
  {
    name: "Read",
    description: "Read the contents of a file.",
    inputSchema: {
      type: "object",
      properties: {
        file_path: { type: "string", description: "Absolute path to the file." },
      },
      required: ["file_path"],
    },
  },
  {
    name: "Write",
    description: "Write content to a file, creating it if it doesn't exist.",
    inputSchema: {
      type: "object",
      properties: {
        file_path: { type: "string", description: "Absolute path to the file." },
        content: { type: "string", description: "Content to write." },
      },
      required: ["file_path", "content"],
    },
  },
  {
    name: "Edit",
    description: "Replace a string in a file.",
    inputSchema: {
      type: "object",
      properties: {
        file_path: { type: "string", description: "Absolute path to the file." },
        old_string: { type: "string", description: "Text to find." },
        new_string: { type: "string", description: "Replacement text." },
      },
      required: ["file_path", "old_string", "new_string"],
    },
  },
  {
    name: "Bash",
    description: "Execute a shell command.",
    inputSchema: {
      type: "object",
      properties: {
        command: { type: "string", description: "Command to execute." },
      },
      required: ["command"],
    },
  },
  {
    name: "Glob",
    description: "Find files matching a glob pattern.",
    inputSchema: {
      type: "object",
      properties: {
        pattern: { type: "string", description: "Glob pattern." },
        path: { type: "string", description: "Directory to search in." },
      },
      required: ["pattern"],
    },
  },
  {
    name: "Grep",
    description: "Search file contents for a pattern.",
    inputSchema: {
      type: "object",
      properties: {
        pattern: { type: "string", description: "Search pattern (regex)." },
        path: { type: "string", description: "Directory to search in." },
      },
      required: ["pattern"],
    },
  },
];

/**
 * Executes tools locally using Node.js APIs.
 *
 * Used by LLMApiExecutor (Tier 2) when the LLM requests tool calls.
 * Each tool is a thin wrapper around filesystem or shell operations.
 */
export class LocalToolExecutor implements ToolExecutor {
  constructor(private readonly cwd: string) {}

  availableTools(): Tool[] {
    return TOOL_DEFINITIONS;
  }

  async execute(name: string, input: Record<string, unknown>): Promise<string> {
    try {
      switch (name) {
        case "Read":
          return await this.read(input.file_path as string);
        case "Write":
          return await this.write(input.file_path as string, input.content as string);
        case "Edit":
          return await this.edit(
            input.file_path as string,
            input.old_string as string,
            input.new_string as string,
          );
        case "Bash":
          return await this.bash(input.command as string);
        case "Glob":
          return await this.globSearch(input.pattern as string, input.path as string | undefined);
        case "Grep":
          return await this.grep(input.pattern as string, input.path as string | undefined);
        default:
          return `Error: Unknown tool "${name}"`;
      }
    } catch (err) {
      return `Error: ${err instanceof Error ? err.message : String(err)}`;
    }
  }

  private async read(filePath: string): Promise<string> {
    return await readFile(filePath, "utf-8");
  }

  private async write(filePath: string, content: string): Promise<string> {
    await mkdir(dirname(filePath), { recursive: true });
    await writeFile(filePath, content, "utf-8");
    return `Wrote ${filePath}`;
  }

  private async edit(filePath: string, oldString: string, newString: string): Promise<string> {
    const content = await readFile(filePath, "utf-8");
    if (!content.includes(oldString)) {
      return `Error: old_string not found in ${filePath}`;
    }
    const updated = content.replace(oldString, newString);
    await writeFile(filePath, updated, "utf-8");
    return `Edited ${filePath}`;
  }

  private async bash(command: string): Promise<string> {
    try {
      const { stdout, stderr } = await execAsync(command, { cwd: this.cwd, timeout: 30000 });
      return stdout || stderr;
    } catch (err) {
      const execErr = err as { stderr?: string; message: string };
      return `Error: ${execErr.stderr || execErr.message}`;
    }
  }

  private async globSearch(pattern: string, path?: string): Promise<string> {
    const cwd = path ?? this.cwd;
    const matches = await glob(pattern, { cwd });
    return matches.join("\n") || "No matches found";
  }

  private async grep(pattern: string, path?: string): Promise<string> {
    const searchDir = path ?? this.cwd;
    try {
      const { stdout } = await execAsync(
        `grep -rn "${pattern.replace(/"/g, '\\"')}" "${searchDir}" --include="*" 2>/dev/null || true`,
        { cwd: this.cwd, timeout: 15000 },
      );
      return stdout.trim() || "No matches found";
    } catch {
      return "No matches found";
    }
  }
}
