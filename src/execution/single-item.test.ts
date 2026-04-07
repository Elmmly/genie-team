import { describe, it, expect, vi, beforeEach } from "vitest";
import {
  executeSingleItem,
  type SingleItemOptions,
  type SingleItemResult,
} from "./single-item.js";
import type { PhaseResult } from "../core/phase-executor.js";

// Mock runPhase
vi.mock("../core/phase-executor.js", () => ({
  runPhase: vi.fn(),
}));

vi.mock("../core/frontmatter.js", () => ({
  getFrontmatterField: vi.fn(),
}));

import { runPhase } from "../core/phase-executor.js";
import { getFrontmatterField } from "../core/frontmatter.js";

function mockPhaseResult(overrides?: Partial<PhaseResult>): PhaseResult {
  return {
    output: "Phase completed successfully.",
    sessionId: "sess-" + Math.random().toString(36).slice(2, 8),
    inputTokens: 500,
    outputTokens: 200,
    costUsd: 0.01,
    numTurns: 5,
    exhausted: false,
    ...overrides,
  };
}

describe("executeSingleItem", () => {
  beforeEach(() => {
    vi.resetAllMocks();
  });

  it("runs phases from discover through done", async () => {
    // Arrange
    vi.mocked(runPhase).mockResolvedValue(mockPhaseResult());

    // Act
    const result = await executeSingleItem("user auth", {
      fromPhase: "discover",
      throughPhase: "done",
    });

    // Assert — should call runPhase for each phase
    expect(vi.mocked(runPhase).mock.calls.length).toBe(7);
    expect(result.exitCode).toBe(0);
  });

  it("respects fromPhase and throughPhase range", async () => {
    // Arrange
    vi.mocked(runPhase).mockResolvedValue(mockPhaseResult());

    // Act
    await executeSingleItem("docs/backlog/P0-item.md", {
      fromPhase: "design",
      throughPhase: "deliver",
    });

    // Assert — only design and deliver
    const phases = vi.mocked(runPhase).mock.calls.map((c) => c[0]);
    expect(phases).toEqual(["design", "deliver"]);
  });

  it("accumulates total cost across phases", async () => {
    // Arrange
    vi.mocked(runPhase)
      .mockResolvedValueOnce(mockPhaseResult({ costUsd: 0.05 }))
      .mockResolvedValueOnce(mockPhaseResult({ costUsd: 0.10 }));

    // Act
    const result = await executeSingleItem("docs/backlog/P0-item.md", {
      fromPhase: "design",
      throughPhase: "deliver",
    });

    // Assert
    expect(result.totalCostUsd).toBeCloseTo(0.15);
  });

  it("passes session IDs for cross-phase resume", async () => {
    // Arrange
    vi.mocked(runPhase)
      .mockResolvedValueOnce(mockPhaseResult({ sessionId: "sess-discover" }))
      .mockResolvedValueOnce(mockPhaseResult({ sessionId: "sess-define" }));

    // Act
    await executeSingleItem("user auth", {
      fromPhase: "discover",
      throughPhase: "define",
    });

    // Assert — second call should get resume from first
    const secondCall = vi.mocked(runPhase).mock.calls[1];
    const opts = secondCall[2];
    expect(opts?.resumeSessionId).toBe("sess-discover");
  });

  it("detects APPROVED verdict from discern phase", async () => {
    // Arrange
    vi.mocked(runPhase).mockResolvedValue(
      mockPhaseResult({
        output: "Review complete. Verdict: APPROVED.",
      }),
    );

    // Act
    const result = await executeSingleItem("docs/backlog/P0-item.md", {
      fromPhase: "discern",
      throughPhase: "discern",
    });

    // Assert
    expect(result.verdict).toBe("APPROVED");
    expect(result.exitCode).toBe(0);
  });

  it("detects BLOCKED verdict and exits 1", async () => {
    // Arrange
    vi.mocked(runPhase).mockResolvedValue(
      mockPhaseResult({
        output: "Critical issues found. Verdict: BLOCKED.",
      }),
    );

    // Act
    const result = await executeSingleItem("docs/backlog/P0-item.md", {
      fromPhase: "discern",
      throughPhase: "discern",
    });

    // Assert
    expect(result.verdict).toBe("BLOCKED");
    expect(result.exitCode).toBe(1);
  });

  it("handles CHANGES_REQUESTED with review cycle", async () => {
    // Arrange — first discern requests changes, deliver fixes, second discern approves
    vi.mocked(runPhase)
      .mockResolvedValueOnce(
        mockPhaseResult({ output: "Verdict: CHANGES REQUESTED. Fix the tests." }),
      )
      .mockResolvedValueOnce(
        mockPhaseResult({ output: "Fixed the tests as requested." }),
      )
      .mockResolvedValueOnce(
        mockPhaseResult({ output: "Verdict: APPROVED." }),
      );

    // Act
    const result = await executeSingleItem("docs/backlog/P0-item.md", {
      fromPhase: "discern",
      throughPhase: "discern",
      reviewCycles: 2,
    });

    // Assert — should have done: discern → deliver → discern
    const phases = vi.mocked(runPhase).mock.calls.map((c) => c[0]);
    expect(phases).toEqual(["discern", "deliver", "discern"]);
    expect(result.verdict).toBe("APPROVED");
  });

  it("stops review cycles at max limit", async () => {
    // Arrange — always requests changes
    vi.mocked(runPhase).mockResolvedValue(
      mockPhaseResult({ output: "Verdict: CHANGES REQUESTED." }),
    );

    // Act
    const result = await executeSingleItem("docs/backlog/P0-item.md", {
      fromPhase: "discern",
      throughPhase: "discern",
      reviewCycles: 1,
    });

    // Assert — discern once, deliver once (review cycle), discern again = 3 calls max
    expect(vi.mocked(runPhase).mock.calls.length).toBeLessThanOrEqual(3);
  });

  it("exits 1 when review cycle results in BLOCKED", async () => {
    // Arrange — discern requests changes, deliver fixes, second discern blocks
    vi.mocked(runPhase)
      .mockResolvedValueOnce(
        mockPhaseResult({ output: "Verdict: CHANGES REQUESTED." }),
      )
      .mockResolvedValueOnce(
        mockPhaseResult({ output: "Attempted fix." }),
      )
      .mockResolvedValueOnce(
        mockPhaseResult({ output: "Verdict: BLOCKED. Critical issues." }),
      );

    // Act
    const result = await executeSingleItem("docs/backlog/P0-item.md", {
      fromPhase: "discern",
      throughPhase: "discern",
      reviewCycles: 2,
    });

    // Assert
    expect(result.verdict).toBe("BLOCKED");
    expect(result.exitCode).toBe(1);
  });

  it("exits 1 when phase exhausts turns", async () => {
    // Arrange
    vi.mocked(runPhase).mockResolvedValue(
      mockPhaseResult({ exhausted: true }),
    );

    // Act
    const result = await executeSingleItem("docs/backlog/P0-item.md", {
      fromPhase: "deliver",
      throughPhase: "deliver",
    });

    // Assert
    expect(result.exitCode).toBe(1);
  });

  it("collects phase results for logging", async () => {
    // Arrange
    vi.mocked(runPhase).mockResolvedValue(mockPhaseResult());

    // Act
    const result = await executeSingleItem("docs/backlog/P0-item.md", {
      fromPhase: "design",
      throughPhase: "deliver",
    });

    // Assert
    expect(result.phaseResults).toHaveLength(2);
    expect(result.phaseResults[0].phase).toBe("design");
    expect(result.phaseResults[1].phase).toBe("deliver");
  });
});

describe("executeSingleItem cost logging", () => {
  beforeEach(() => {
    vi.resetAllMocks();
  });

  it("passes hooks to runPhase when logDir is set", async () => {
    // Arrange
    vi.mocked(runPhase).mockResolvedValue(mockPhaseResult());

    // Act
    await executeSingleItem("docs/backlog/P0-item.md", {
      fromPhase: "deliver",
      throughPhase: "deliver",
      logDir: "/tmp/test-logs",
    });

    // Assert
    const phaseOpts = vi.mocked(runPhase).mock.calls[0][2];
    expect(phaseOpts?.hooks).toBeDefined();
    expect(phaseOpts?.hooks?.onResult).toBeTypeOf("function");
  });

  it("passes onToolUse but not onResult when logDir is absent", async () => {
    // Arrange
    vi.mocked(runPhase).mockResolvedValue(mockPhaseResult());

    // Act
    await executeSingleItem("docs/backlog/P0-item.md", {
      fromPhase: "deliver",
      throughPhase: "deliver",
    });

    // Assert — onToolUse always present (artifact tracking), onResult absent
    const phaseOpts = vi.mocked(runPhase).mock.calls[0][2];
    expect(phaseOpts?.hooks?.onToolUse).toBeTypeOf("function");
    expect(phaseOpts?.hooks?.onResult).toBeUndefined();
  });

  it("passes hooks to review-cycle runPhase calls too", async () => {
    // Arrange — discern returns CHANGES_REQUESTED, then APPROVED
    vi.mocked(runPhase)
      .mockResolvedValueOnce(
        mockPhaseResult({ output: "Verdict: CHANGES REQUESTED." }),
      )
      .mockResolvedValueOnce(mockPhaseResult({ output: "Fixed." }))
      .mockResolvedValueOnce(
        mockPhaseResult({ output: "Verdict: APPROVED." }),
      );

    // Act
    await executeSingleItem("docs/backlog/P0-item.md", {
      fromPhase: "discern",
      throughPhase: "discern",
      reviewCycles: 2,
      logDir: "/tmp/test-logs",
    });

    // Assert — all 3 calls (discern, deliver, discern) should have hooks
    for (const call of vi.mocked(runPhase).mock.calls) {
      const phaseOpts = call[2];
      expect(phaseOpts?.hooks?.onResult).toBeTypeOf("function");
    }
  });
});

describe("executeSingleItem auth mode", () => {
  beforeEach(() => {
    vi.resetAllMocks();
  });

  it("passes authMode to runPhase when set", async () => {
    // Arrange
    vi.mocked(runPhase).mockResolvedValue(mockPhaseResult());

    // Act
    await executeSingleItem("item.md", {
      fromPhase: "deliver",
      throughPhase: "deliver",
      authMode: "oauth",
    });

    // Assert
    const phaseOpts = vi.mocked(runPhase).mock.calls[0][2];
    expect(phaseOpts?.authMode).toBe("oauth");
  });

  it("does not pass authMode when not set", async () => {
    // Arrange
    vi.mocked(runPhase).mockResolvedValue(mockPhaseResult());

    // Act
    await executeSingleItem("item.md", {
      fromPhase: "deliver",
      throughPhase: "deliver",
    });

    // Assert
    const phaseOpts = vi.mocked(runPhase).mock.calls[0][2];
    expect(phaseOpts?.authMode).toBeUndefined();
  });
});

describe("executeSingleItem artifact tracking", () => {
  beforeEach(() => {
    vi.resetAllMocks();
  });

  it("passes onToolUse hook to runPhase", async () => {
    // Arrange
    vi.mocked(runPhase).mockResolvedValue(mockPhaseResult());

    // Act
    await executeSingleItem("item.md", {
      fromPhase: "deliver",
      throughPhase: "deliver",
    });

    // Assert
    const phaseOpts = vi.mocked(runPhase).mock.calls[0][2];
    expect(phaseOpts?.hooks?.onToolUse).toBeTypeOf("function");
  });

  it("records Write tool_use file paths as artifacts", async () => {
    // Arrange — simulate SDK PostToolUse hook firing
    vi.mocked(runPhase).mockImplementation(async (_phase, _input, opts) => {
      opts?.hooks?.onToolUse?.({
        toolName: "Write",
        toolInput: { file_path: "src/index.ts", content: "..." },
      });
      return mockPhaseResult();
    });

    // Act
    const result = await executeSingleItem("item.md", {
      fromPhase: "deliver",
      throughPhase: "deliver",
    });

    // Assert
    expect(result.artifacts).toContain("src/index.ts");
  });

  it("records Edit tool_use file paths as artifacts", async () => {
    // Arrange
    vi.mocked(runPhase).mockImplementation(async (_phase, _input, opts) => {
      opts?.hooks?.onToolUse?.({
        toolName: "Edit",
        toolInput: { file_path: "src/cli.ts", old_string: "a", new_string: "b" },
      });
      return mockPhaseResult();
    });

    // Act
    const result = await executeSingleItem("item.md", {
      fromPhase: "deliver",
      throughPhase: "deliver",
    });

    // Assert
    expect(result.artifacts).toContain("src/cli.ts");
  });

  it("deduplicates artifacts across phases", async () => {
    // Arrange
    vi.mocked(runPhase).mockImplementation(async (_phase, _input, opts) => {
      opts?.hooks?.onToolUse?.({
        toolName: "Write",
        toolInput: { file_path: "src/index.ts", content: "..." },
      });
      return mockPhaseResult();
    });

    // Act
    const result = await executeSingleItem("item.md", {
      fromPhase: "design",
      throughPhase: "deliver",
    });

    // Assert — both phases write same file, should be deduplicated
    const indexCount = result.artifacts?.filter((a) => a === "src/index.ts").length;
    expect(indexCount).toBe(1);
  });

  it("ignores non-Write/Edit tool uses", async () => {
    // Arrange
    vi.mocked(runPhase).mockImplementation(async (_phase, _input, opts) => {
      opts?.hooks?.onToolUse?.({
        toolName: "Bash",
        toolInput: { command: "ls" },
      });
      opts?.hooks?.onToolUse?.({
        toolName: "Read",
        toolInput: { file_path: "src/index.ts" },
      });
      return mockPhaseResult();
    });

    // Act
    const result = await executeSingleItem("item.md", {
      fromPhase: "deliver",
      throughPhase: "deliver",
    });

    // Assert
    expect(result.artifacts).toBeUndefined();
  });

  it("coexists with cost logger hooks", async () => {
    // Arrange
    vi.mocked(runPhase).mockImplementation(async (_phase, _input, opts) => {
      opts?.hooks?.onToolUse?.({
        toolName: "Write",
        toolInput: { file_path: "src/new.ts", content: "..." },
      });
      return mockPhaseResult();
    });

    // Act
    const result = await executeSingleItem("item.md", {
      fromPhase: "deliver",
      throughPhase: "deliver",
      logDir: "/tmp/logs",
    });

    // Assert — both hooks should fire: artifacts tracked AND cost logger wired
    expect(result.artifacts).toContain("src/new.ts");
    const phaseOpts = vi.mocked(runPhase).mock.calls[0][2];
    expect(phaseOpts?.hooks?.onResult).toBeTypeOf("function");
    expect(phaseOpts?.hooks?.onToolUse).toBeTypeOf("function");
  });
});

describe("executeSingleItem hasContextDir", () => {
  beforeEach(() => {
    vi.resetAllMocks();
  });

  it("passes hasContextDir to runPhase when set", async () => {
    // Arrange
    vi.mocked(runPhase).mockResolvedValue(mockPhaseResult());

    // Act
    await executeSingleItem("item.md", {
      fromPhase: "deliver",
      throughPhase: "deliver",
      hasContextDir: true,
    });

    // Assert
    const phaseOpts = vi.mocked(runPhase).mock.calls[0][2];
    expect(phaseOpts?.hasContextDir).toBe(true);
  });

  it("does not set hasContextDir when not provided", async () => {
    // Arrange
    vi.mocked(runPhase).mockResolvedValue(mockPhaseResult());

    // Act
    await executeSingleItem("item.md", {
      fromPhase: "deliver",
      throughPhase: "deliver",
    });

    // Assert
    const phaseOpts = vi.mocked(runPhase).mock.calls[0][2];
    expect(phaseOpts?.hasContextDir).toBeUndefined();
  });
});

describe("detectVerdict enhanced", () => {
  beforeEach(() => {
    vi.resetAllMocks();
  });

  it("detects verdict from frontmatter field when item path exists", async () => {
    // Arrange — discern returns ambiguous output but frontmatter has verdict
    vi.mocked(runPhase).mockImplementation(async (phase: string) => {
      if (phase === "discern") {
        return mockPhaseResult({ output: "Review complete, see backlog item." });
      }
      return mockPhaseResult();
    });

    // Mock readFrontmatter to return a verdict field
    const { getFrontmatterField } = await import("../core/frontmatter.js");
    vi.mocked(getFrontmatterField).mockResolvedValue("APPROVED");

    // Act
    const result = await executeSingleItem("docs/backlog/P1-item.md", {
      fromPhase: "discern",
      throughPhase: "discern",
    });

    // Assert
    expect(result.verdict).toBe("APPROVED");
  });

  it("falls back to output text when frontmatter has no verdict", async () => {
    // Arrange
    vi.mocked(runPhase).mockResolvedValue(
      mockPhaseResult({ output: "Verdict: BLOCKED — security concern" }),
    );
    const { getFrontmatterField } = await import("../core/frontmatter.js");
    vi.mocked(getFrontmatterField).mockResolvedValue(undefined);

    // Act
    const result = await executeSingleItem("docs/backlog/P1-item.md", {
      fromPhase: "discern",
      throughPhase: "discern",
    });

    // Assert
    expect(result.verdict).toBe("BLOCKED");
  });
});

describe("artifact path threading", () => {
  beforeEach(() => {
    vi.resetAllMocks();
  });

  it("threads discover output artifact as define input", async () => {
    // Arrange — discover produces an analysis doc, define should receive it
    let callCount = 0;
    vi.mocked(runPhase).mockImplementation(async () => {
      callCount++;
      if (callCount === 1) {
        // discover phase output mentions an analysis path
        return mockPhaseResult({
          output: "Created docs/analysis/20260401_auth-discovery.md",
        });
      }
      return mockPhaseResult();
    });

    // Act
    const result = await executeSingleItem("auth improvements", {
      fromPhase: "discover",
      throughPhase: "define",
    });

    // Assert — define phase should have been called with the artifact path
    expect(runPhase).toHaveBeenCalledTimes(2);
    // The second call (define) should use the artifact from discover
    const defineInput = vi.mocked(runPhase).mock.calls[1][1];
    expect(defineInput).toBe("docs/analysis/20260401_auth-discovery.md");
  });

  it("threads define output artifact as design input", async () => {
    // Arrange
    let callCount = 0;
    vi.mocked(runPhase).mockImplementation(async () => {
      callCount++;
      if (callCount === 1) {
        return mockPhaseResult({
          output: "Shaped contract at docs/backlog/P1-auth-improvements.md",
        });
      }
      return mockPhaseResult();
    });

    // Act
    await executeSingleItem("docs/analysis/auth-discovery.md", {
      fromPhase: "define",
      throughPhase: "design",
    });

    // Assert
    const designInput = vi.mocked(runPhase).mock.calls[1][1];
    expect(designInput).toBe("docs/backlog/P1-auth-improvements.md");
  });

  it("uses original input when no artifact is extracted", async () => {
    // Arrange
    vi.mocked(runPhase).mockResolvedValue(
      mockPhaseResult({ output: "Phase completed successfully" }),
    );

    // Act
    await executeSingleItem("docs/backlog/P1-item.md", {
      fromPhase: "discover",
      throughPhase: "define",
    });

    // Assert — define should receive the original input
    const defineInput = vi.mocked(runPhase).mock.calls[1][1];
    expect(defineInput).toBe("docs/backlog/P1-item.md");
  });
});

describe("min-turn enforcement", () => {
  beforeEach(() => {
    vi.resetAllMocks();
  });

  it("retries deliver phase when turns below minimum", async () => {
    // Arrange — first deliver returns with only 1 turn (below min of 3)
    let deliverCalls = 0;
    vi.mocked(runPhase).mockImplementation(async (phase: string) => {
      if (phase === "deliver") {
        deliverCalls++;
        if (deliverCalls === 1) {
          return mockPhaseResult({ numTurns: 1, sessionId: "sess-1" });
        }
        return mockPhaseResult({ numTurns: 10 });
      }
      return mockPhaseResult();
    });

    // Act
    await executeSingleItem("item.md", {
      fromPhase: "deliver",
      throughPhase: "deliver",
    });

    // Assert — deliver should have been called twice (original + retry)
    expect(deliverCalls).toBe(2);
  });

  it("does not retry when turns meet minimum", async () => {
    // Arrange
    vi.mocked(runPhase).mockResolvedValue(mockPhaseResult({ numTurns: 10 }));

    // Act
    await executeSingleItem("item.md", {
      fromPhase: "deliver",
      throughPhase: "deliver",
    });

    // Assert — only one deliver call
    expect(runPhase).toHaveBeenCalledTimes(1);
  });

  it("uses deliverMinTurns override when provided", async () => {
    // Arrange — min turns overridden to 15, phase returns 10 turns
    let deliverCalls = 0;
    vi.mocked(runPhase).mockImplementation(async (phase: string) => {
      if (phase === "deliver") {
        deliverCalls++;
        if (deliverCalls === 1) {
          return mockPhaseResult({ numTurns: 10, sessionId: "sess-1" });
        }
        return mockPhaseResult({ numTurns: 20 });
      }
      return mockPhaseResult();
    });

    // Act
    await executeSingleItem("item.md", {
      fromPhase: "deliver",
      throughPhase: "deliver",
      deliverMinTurns: 15,
    });

    // Assert — retried because 10 < 15
    expect(deliverCalls).toBe(2);
  });
});

describe("dry-run mode", () => {
  beforeEach(() => {
    vi.resetAllMocks();
  });

  it("does not call runPhase when dryRun is true", async () => {
    // Arrange — no mock needed since runPhase should never be called

    // Act
    const result = await executeSingleItem("item.md", {
      fromPhase: "discover",
      throughPhase: "done",
      dryRun: true,
    });

    // Assert
    expect(runPhase).not.toHaveBeenCalled();
    expect(result.exitCode).toBe(0);
    expect(result.phaseResults).toEqual([]);
  });
});
