import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";
import { acquireLock, isLocked, type LockOptions } from "./lockfile.js";
import * as fs from "node:fs";
import * as path from "node:path";

vi.mock("node:fs");

const mockFs = vi.mocked(fs);

describe("acquireLock", () => {
  beforeEach(() => {
    vi.restoreAllMocks();
    vi.useFakeTimers();
    vi.setSystemTime(new Date("2026-04-07T12:00:00Z"));
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it("acquires lock when no lock file exists", async () => {
    // Arrange
    mockFs.existsSync.mockReturnValue(false);
    mockFs.writeFileSync.mockReturnValue(undefined);
    mockFs.mkdirSync.mockReturnValue(undefined);

    // Act
    const handle = await acquireLock("my-item", { lockDir: "/tmp/locks" });

    // Assert
    expect(mockFs.writeFileSync).toHaveBeenCalledWith(
      "/tmp/locks/.genies-my-item.lock",
      expect.stringContaining(`"pid":${process.pid}`),
    );
    expect(handle).toHaveProperty("release");
  });

  it("throws when lock is held by a live process", async () => {
    // Arrange
    const lockContent = JSON.stringify({
      pid: 99999,
      timestamp: new Date("2026-04-07T11:30:00Z").toISOString(),
      slug: "my-item",
    });
    mockFs.existsSync.mockReturnValue(true);
    mockFs.readFileSync.mockReturnValue(lockContent);
    mockFs.mkdirSync.mockReturnValue(undefined);

    const originalKill = process.kill;
    process.kill = vi.fn().mockImplementation((pid: number, signal?: string | number) => {
      if (signal === 0 && pid === 99999) return true; // process alive
      return originalKill.call(process, pid, signal);
    }) as typeof process.kill;

    // Act + Assert
    await expect(acquireLock("my-item", { lockDir: "/tmp/locks" })).rejects.toThrow(
      /locked/i,
    );

    process.kill = originalKill;
  });

  it("acquires when lock is stale (timestamp exceeds staleHours)", async () => {
    // Arrange
    const staleTimestamp = new Date("2026-04-07T07:00:00Z").toISOString(); // 5 hours ago
    const lockContent = JSON.stringify({
      pid: 99999,
      timestamp: staleTimestamp,
      slug: "my-item",
    });
    mockFs.existsSync.mockReturnValue(true);
    mockFs.readFileSync.mockReturnValue(lockContent);
    mockFs.writeFileSync.mockReturnValue(undefined);
    mockFs.unlinkSync.mockReturnValue(undefined);
    mockFs.mkdirSync.mockReturnValue(undefined);

    // Act
    const handle = await acquireLock("my-item", { lockDir: "/tmp/locks", staleHours: 4 });

    // Assert
    expect(handle).toHaveProperty("release");
    expect(mockFs.writeFileSync).toHaveBeenCalled();
  });

  it("acquires when lock PID is dead", async () => {
    // Arrange
    const lockContent = JSON.stringify({
      pid: 99999,
      timestamp: new Date("2026-04-07T11:30:00Z").toISOString(),
      slug: "my-item",
    });
    mockFs.existsSync.mockReturnValue(true);
    mockFs.readFileSync.mockReturnValue(lockContent);
    mockFs.writeFileSync.mockReturnValue(undefined);
    mockFs.unlinkSync.mockReturnValue(undefined);
    mockFs.mkdirSync.mockReturnValue(undefined);

    const originalKill = process.kill;
    process.kill = vi.fn().mockImplementation((pid: number, signal?: string | number) => {
      if (signal === 0 && pid === 99999) throw new Error("ESRCH");
      return originalKill.call(process, pid, signal);
    }) as typeof process.kill;

    // Act
    const handle = await acquireLock("my-item", { lockDir: "/tmp/locks" });

    // Assert
    expect(handle).toHaveProperty("release");
    expect(mockFs.writeFileSync).toHaveBeenCalled();

    process.kill = originalKill;
  });

  it("release removes the lock file", async () => {
    // Arrange
    mockFs.existsSync.mockReturnValue(false);
    mockFs.writeFileSync.mockReturnValue(undefined);
    mockFs.unlinkSync.mockReturnValue(undefined);
    mockFs.mkdirSync.mockReturnValue(undefined);

    const handle = await acquireLock("my-item", { lockDir: "/tmp/locks" });

    // Act
    await handle.release();

    // Assert
    expect(mockFs.unlinkSync).toHaveBeenCalledWith(
      "/tmp/locks/.genies-my-item.lock",
    );
  });

  it("uses process.cwd() as default lockDir", async () => {
    // Arrange
    mockFs.existsSync.mockReturnValue(false);
    mockFs.writeFileSync.mockReturnValue(undefined);
    mockFs.mkdirSync.mockReturnValue(undefined);

    // Act
    await acquireLock("test-slug");

    // Assert
    const expectedPath = path.join(process.cwd(), ".genies-test-slug.lock");
    expect(mockFs.writeFileSync).toHaveBeenCalledWith(
      expectedPath,
      expect.any(String),
    );
  });

  it("defaults staleHours to 4", async () => {
    // Arrange — lock created 3 hours ago (under 4-hour default)
    const recentTimestamp = new Date("2026-04-07T09:30:00Z").toISOString(); // 2.5 hours ago
    const lockContent = JSON.stringify({
      pid: 99999,
      timestamp: recentTimestamp,
      slug: "my-item",
    });
    mockFs.existsSync.mockReturnValue(true);
    mockFs.readFileSync.mockReturnValue(lockContent);
    mockFs.mkdirSync.mockReturnValue(undefined);

    const originalKill = process.kill;
    process.kill = vi.fn().mockImplementation((pid: number, signal?: string | number) => {
      if (signal === 0 && pid === 99999) return true; // alive
      return originalKill.call(process, pid, signal);
    }) as typeof process.kill;

    // Act + Assert — should throw because lock is fresh AND process alive
    await expect(acquireLock("my-item", { lockDir: "/tmp/locks" })).rejects.toThrow(
      /locked/i,
    );

    process.kill = originalKill;
  });
});

describe("isLocked", () => {
  beforeEach(() => {
    vi.restoreAllMocks();
    vi.useFakeTimers();
    vi.setSystemTime(new Date("2026-04-07T12:00:00Z"));
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it("returns false when no lock file exists", () => {
    // Arrange
    mockFs.existsSync.mockReturnValue(false);

    // Act
    const result = isLocked("my-item", { lockDir: "/tmp/locks" });

    // Assert
    expect(result).toBe(false);
  });

  it("returns true when lock is held by live process", () => {
    // Arrange
    const lockContent = JSON.stringify({
      pid: 99999,
      timestamp: new Date("2026-04-07T11:30:00Z").toISOString(),
      slug: "my-item",
    });
    mockFs.existsSync.mockReturnValue(true);
    mockFs.readFileSync.mockReturnValue(lockContent);

    const originalKill = process.kill;
    process.kill = vi.fn().mockImplementation((pid: number, signal?: string | number) => {
      if (signal === 0 && pid === 99999) return true;
      return originalKill.call(process, pid, signal);
    }) as typeof process.kill;

    // Act
    const result = isLocked("my-item", { lockDir: "/tmp/locks" });

    // Assert
    expect(result).toBe(true);

    process.kill = originalKill;
  });

  it("returns false when lock PID is dead", () => {
    // Arrange
    const lockContent = JSON.stringify({
      pid: 99999,
      timestamp: new Date("2026-04-07T11:30:00Z").toISOString(),
      slug: "my-item",
    });
    mockFs.existsSync.mockReturnValue(true);
    mockFs.readFileSync.mockReturnValue(lockContent);

    const originalKill = process.kill;
    process.kill = vi.fn().mockImplementation((pid: number, signal?: string | number) => {
      if (signal === 0 && pid === 99999) throw new Error("ESRCH");
      return originalKill.call(process, pid, signal);
    }) as typeof process.kill;

    // Act
    const result = isLocked("my-item", { lockDir: "/tmp/locks" });

    // Assert
    expect(result).toBe(false);

    process.kill = originalKill;
  });

  it("returns false when lock is stale", () => {
    // Arrange
    const staleTimestamp = new Date("2026-04-07T07:00:00Z").toISOString(); // 5 hours ago
    const lockContent = JSON.stringify({
      pid: 99999,
      timestamp: staleTimestamp,
      slug: "my-item",
    });
    mockFs.existsSync.mockReturnValue(true);
    mockFs.readFileSync.mockReturnValue(lockContent);

    // Act
    const result = isLocked("my-item", { lockDir: "/tmp/locks", staleHours: 4 });

    // Assert
    expect(result).toBe(false);
  });
});
