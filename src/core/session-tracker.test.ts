import { describe, it, expect } from "vitest";
import { SessionTracker } from "./session-tracker.js";

describe("SessionTracker", () => {
  it("stores session ID for a phase", () => {
    // Arrange
    const tracker = new SessionTracker();

    // Act
    tracker.record("discover", "sess-001");

    // Assert
    expect(tracker.getSessionId("discover")).toBe("sess-001");
  });

  it("returns undefined for unrecorded phase", () => {
    // Arrange
    const tracker = new SessionTracker();

    // Act & Assert
    expect(tracker.getSessionId("discover")).toBeUndefined();
  });

  it("returns last session ID as resume candidate", () => {
    // Arrange
    const tracker = new SessionTracker();
    tracker.record("discover", "sess-001");
    tracker.record("define", "sess-002");

    // Act & Assert
    expect(tracker.lastSessionId()).toBe("sess-002");
  });

  it("returns undefined when no sessions recorded", () => {
    // Arrange
    const tracker = new SessionTracker();

    // Act & Assert
    expect(tracker.lastSessionId()).toBeUndefined();
  });

  it("getResumeId returns last session when resume enabled", () => {
    // Arrange
    const tracker = new SessionTracker();
    tracker.record("discover", "sess-001");

    // Act & Assert
    expect(tracker.getResumeId()).toBe("sess-001");
  });

  it("getResumeId returns undefined when noResume is set", () => {
    // Arrange
    const tracker = new SessionTracker({ noResume: true });
    tracker.record("discover", "sess-001");

    // Act & Assert
    expect(tracker.getResumeId()).toBeUndefined();
  });

  it("tracks all phases in order", () => {
    // Arrange
    const tracker = new SessionTracker();
    tracker.record("discover", "sess-001");
    tracker.record("define", "sess-002");
    tracker.record("design", "sess-003");

    // Act
    const all = tracker.allSessions();

    // Assert
    expect(all).toEqual([
      { phase: "discover", sessionId: "sess-001" },
      { phase: "define", sessionId: "sess-002" },
      { phase: "design", sessionId: "sess-003" },
    ]);
  });
});
