import type { PhaseName } from "../config/phase-config.js";

interface SessionEntry {
  phase: PhaseName;
  sessionId: string;
}

interface SessionTrackerOptions {
  noResume?: boolean;
}

/**
 * Tracks Claude session IDs across phases for multi-phase continuity.
 *
 * Each phase produces a session ID. The next phase can resume the
 * previous session to maintain context, unless --no-resume is set.
 */
export class SessionTracker {
  private sessions: SessionEntry[] = [];
  private noResume: boolean;

  constructor(options?: SessionTrackerOptions) {
    this.noResume = options?.noResume ?? false;
  }

  record(phase: PhaseName, sessionId: string): void {
    this.sessions.push({ phase, sessionId });
  }

  getSessionId(phase: PhaseName): string | undefined {
    return this.sessions.find((s) => s.phase === phase)?.sessionId;
  }

  lastSessionId(): string | undefined {
    return this.sessions.at(-1)?.sessionId;
  }

  /**
   * Returns the session ID to use for resuming, or undefined if
   * resume is disabled or no sessions have been recorded.
   */
  getResumeId(): string | undefined {
    if (this.noResume) return undefined;
    return this.lastSessionId();
  }

  allSessions(): SessionEntry[] {
    return [...this.sessions];
  }
}
