---
type: discover
topic: "Claude Code Autonomous Execution and Orchestration Features (March 2026)"
reasoning_mode: deep
status: active
created: "2026-03-30"
---

# Opportunity Snapshot: Claude Code Autonomous Execution and Orchestration Features

## 1. Discovery Question

**Original:** Research the latest Claude Code features for headless/autonomous execution and orchestration -- Dispatch, Remote Control, Channels, /loop, Computer Use, and mobile integration.

**Reframed:** What new autonomous execution and orchestration primitives has Claude Code shipped in early 2026, and how do they technically work? What do these capabilities mean for genie-team's execution model?

## 2. Feature Inventory

### 2.1 Remote Control

**Released:** February 2026 (v2.1.51+)
**Availability:** All plans (Pro, Max, Team, Enterprise). Team/Enterprise requires admin toggle.
**Auth:** claude.ai OAuth only. API keys NOT supported.

**What it does:** Connects claude.ai/code or the Claude mobile app (iOS/Android) to a Claude Code session running on your local machine. Start a task at your desk, pick it up from your phone.

**Technical architecture:**
- Your local Claude Code session makes **outbound HTTPS requests only** -- never opens inbound ports
- On start, it **registers with the Anthropic API and polls for work**
- When you connect from another device, the Anthropic server **routes messages between the web/mobile client and local session** over a streaming connection
- All traffic over TLS through Anthropic API. Multiple **short-lived credentials**, each scoped to a single purpose and expiring independently
- Works behind NAT, corporate firewalls, home routers -- no port forwarding or VPN needed
- **Files and MCP servers never leave your machine** -- only chat messages and tool results flow through the encrypted bridge

**Three modes of starting:**

1. **Server mode:** `claude remote-control` -- dedicated server, waits for remote connections
   - `--name "My Project"` -- custom session title
   - `--spawn <mode>` -- `same-dir` (default) or `worktree` (git worktree per session)
   - `--capacity <N>` -- max concurrent sessions (default 32)
   - `--sandbox / --no-sandbox` -- filesystem/network isolation
   - `--verbose` -- detailed logging
2. **Interactive + Remote:** `claude --remote-control` (or `--rc`) -- normal interactive session also available remotely
3. **From existing session:** `/remote-control` (or `/rc`) command inside a running session

**Connecting from another device:**
- Open session URL in browser
- Scan QR code (press spacebar in server mode to toggle)
- Find by name in claude.ai/code or Claude mobile app (green dot = online)

**Persistence:** Can enable for all sessions via `/config`. Session reconnects automatically if laptop sleeps or network drops. Times out after ~10 minutes of no network.

**Limitations:**
- One remote session per interactive process (use server mode + `--spawn` for multiple)
- Terminal must stay open (local process)
- 10-minute network outage timeout

---

### 2.2 Dispatch

**Released:** March 17, 2026 (research preview)
**Availability:** Pro and Max plans only. NOT available on Team or Enterprise.
**Requirement:** Claude Desktop app must be running on macOS.

**What it does:** A persistent conversation with Claude that lives in the Cowork tab of the Desktop app. You message Dispatch a task from your phone, and it decides how to handle it. If the task is development work, Dispatch spawns a Code session in the Desktop app automatically.

**How it works:**
- Task routing is automatic: "fix the login bug" -> spawns Code session. "Research X topic" -> stays in Cowork
- Code sessions appear in the Code tab sidebar with a **Dispatch badge**
- Push notification sent to phone when session finishes or needs approval
- If Computer Use is enabled, Dispatch-spawned sessions can use it too (app approvals expire after 30 minutes vs full session for regular sessions)
- **Your computer must stay on** -- if laptop sleeps or app closes, Dispatch stops. It is remote control, not cloud computing.

**Setup:** Pair Claude mobile app with Desktop app via [Dispatch help article](https://support.claude.com/en/articles/13947068).

**Success rate:** Community testing indicates ~50% on complex tasks, higher on simple tasks (file search, summaries).

---

### 2.3 Channels

**Released:** March 2026 (research preview, v2.1.80+)
**Availability:** All plans. Team/Enterprise requires admin to enable `channelsEnabled`.
**Auth:** claude.ai login required. Console and API key NOT supported.

**What it does:** An MCP server that **pushes events into your running Claude Code session**. Claude reacts to messages while you're not at the terminal. Two-way: Claude reads the event and replies back through the same channel.

**Supported platforms:** Telegram, Discord, iMessage (research preview). Custom channels can be built.

**Technical architecture:**
- Channel = MCP server plugin
- Installed via `/plugin install <channel>@claude-plugins-official`
- Enabled per-session with `--channels` flag: `claude --channels plugin:telegram@claude-plugins-official`
- Being in `.mcp.json` is NOT enough -- server must also be named in `--channels`
- Telegram: polls for messages via bot token
- Discord: WebSocket connection via bot token
- iMessage: reads `~/Library/Messages/chat.db` directly, sends via AppleScript (macOS only, requires Full Disk Access)
- Requires [Bun](https://bun.sh) runtime

**Security model:**
- Sender allowlist per channel -- only paired IDs can push messages
- Telegram/Discord: pairing code flow (message bot -> get code -> `/telegram:access pair <code>`)
- iMessage: self-chat bypasses automatically; add others with `/imessage:access allow +15551234567`
- Policy lockdown: `/telegram:access policy allowlist`
- Allowlist also gates permission relay (channel senders who can approve/deny tool use)

**Enterprise controls:**
- `channelsEnabled` -- master switch (managed setting)
- `allowedChannelPlugins` -- restrict which plugins can register (replaces Anthropic default allowlist)

**Building custom channels:** Full reference at `/en/channels-reference`. Example: webhook receiver for CI failures, deploy pipelines, error trackers.

**Key distinction from other features:**
- Remote Control = you drive the session remotely
- Channels = external events are pushed INTO the session
- Dispatch = phone -> Desktop app session spawning

---

### 2.4 /loop (Scheduled Tasks)

**Released:** v2.1.72+ (CLI), plus Desktop and Cloud variants
**Availability:** All plans

**What it does:** Runs a prompt automatically on an interval within a session. Three tiers of scheduling exist:

#### Tier 1: `/loop` (session-scoped, CLI)

**Syntax:**
```
/loop 5m check if the deployment finished and tell me what happened
/loop check the build every 2 hours
/loop 20m /review-pr 1234     # can invoke other commands/skills
```

**Interval syntax:** `s` (seconds), `m` (minutes), `h` (hours), `d` (days). Seconds rounded up to nearest minute (cron granularity). Default: every 10 minutes.

**Under the hood:** Claude parses interval, converts to cron expression, schedules via internal tools:
- `CronCreate` -- schedule a task (5-field cron expression, prompt, recur flag)
- `CronList` -- list all tasks with IDs, schedules, prompts
- `CronDelete` -- cancel by 8-character ID
- Max 50 tasks per session

**Execution model:**
- Fires between your turns, not during mid-response
- Scheduler checks every second for due tasks, enqueues at low priority
- Jitter: recurring tasks fire up to 10% of period late (capped 15 min); one-shot tasks up to 90 seconds early
- **3-day expiry** on recurring tasks -- fires one final time then self-deletes
- All times in local timezone

**One-time reminders:** Natural language: `remind me at 3pm to push the release branch`

**Limitations:**
- Session-scoped only -- gone when you exit
- No catch-up for missed fires
- No persistence across restarts

**Disable:** `CLAUDE_CODE_DISABLE_CRON=1` environment variable

#### Tier 2: Desktop Scheduled Tasks (persistent, local)

- Created from Schedule page in Desktop app or by asking Claude in a session
- **Persistent across restarts** -- survives app close
- Task stored at `~/.claude/scheduled-tasks/<task-name>/SKILL.md` (YAML frontmatter + prompt body)
- Frequency options: Manual, Hourly, Daily, Weekdays, Weekly (custom via Claude)
- Runs while desktop app is open and computer awake
- Each task gets its own session with configurable permission mode
- Worktree toggle available for Git isolation
- Missed run catch-up: on wake, runs once for most recently missed time (up to 7 days back)
- `Keep computer awake` setting in Desktop to prevent idle-sleep

#### Tier 3: Cloud Scheduled Tasks (persistent, cloud)

- Run on Anthropic-managed cloud infrastructure
- Work against a fresh clone of your repo (no local file access)
- Continue even if computer is off
- Minimum interval: 1 hour
- Configured via `/schedule` in CLI
- Connectors configured per task

**Comparison table (from official docs):**

| Attribute | Cloud | Desktop | `/loop` |
|-----------|-------|---------|---------|
| Runs on | Anthropic cloud | Your machine | Your machine |
| Requires machine on | No | Yes | Yes |
| Requires open session | No | No | Yes |
| Persistent across restarts | Yes | Yes | No |
| Access to local files | No (fresh clone) | Yes | Yes |
| MCP servers | Connectors per task | Config files + connectors | Inherits from session |
| Minimum interval | 1 hour | 1 minute | 1 minute |

---

### 2.5 Computer Use (Desktop App)

**Released:** March 24, 2026 (research preview)
**Availability:** Pro and Max plans only. NOT Team or Enterprise. macOS only.
**Requirement:** Claude Desktop app running.

**What it does:** Claude opens apps, controls your screen, and works directly on your machine -- mouse, keyboard, browser, everything. Used when CLI tools, connectors, and browser extensions aren't available.

**Tool hierarchy (precision-first):**
1. Connectors (Slack, Google Calendar, etc.) -- most precise
2. Bash commands
3. Claude in Chrome extension
4. Computer Use -- broadest, slowest, last resort

**Permission tiers per app category (fixed, not configurable):**

| Tier | What Claude can do | Applies to |
|------|-------------------|------------|
| View only | See in screenshots | Browsers, trading platforms |
| Click only | Click and scroll, no typing | Terminals, IDEs |
| Full control | Click, type, drag, keyboard shortcuts | Everything else |

**Setup:**
1. Enable in Settings > Desktop app > General > Computer use toggle
2. Grant macOS permissions: Accessibility (click/type/scroll) + Screen Recording (see screen)
3. Per-app approval prompts on first use (session-scoped or 30 min for Dispatch sessions)

**Safety:**
- Automatic scanning of activations for prompt injection detection
- User can stop at any time
- Some apps blocked by default (sensitive data)
- Extra warning for high-reach apps (Terminal, Finder, System Settings)
- Windows hidden while Claude works, restored when done

**Limitations:** macOS only. Slower than direct integrations. "Still early -- Claude can make mistakes."

---

### 2.6 Auto Mode

**Released:** March 24, 2026 (research preview)
**Availability:** Team plans now, Enterprise rolling out. Requires Claude Sonnet 4.6 or Opus 4.6.

**What it does:** Replaces `--dangerously-skip-permissions` with a safety-checked alternative. A separate classifier model reviews each tool call before execution.

**How the classifier works:**
- Runs on **Claude Sonnet 4.6** (even if main session uses a different model)
- Before each tool call, classifier reviews the conversation and decides if the action matches what you asked for
- Blocks actions that: escalate beyond task scope, target unrecognized infrastructure, appear driven by hostile content (prompt injection)
- Safe actions proceed automatically; risky ones blocked and Claude redirected

**Enable:**
- CLI: `claude --enable-auto-mode`
- Desktop/VS Code: Settings > Claude Code, then select from permission mode dropdown
- Shift+Tab cycles between permission modes

**Admin controls:**
- `"disableAutoMode": "disable"` in managed settings
- `"autoMode"` key to customize classifier trust/block rules

---

### 2.7 Mobile App Integration

**Not a standalone feature** -- mobile integration is the connecting tissue between the above features:

- **Claude iOS app** (App Store) and **Android app** (Play Store) connect to:
  - Remote Control sessions (view and send messages)
  - Dispatch (send tasks that spawn Desktop sessions)
  - Channels (send messages via Telegram/Discord/iMessage that push into CLI sessions)
- Push notifications from Dispatch when sessions complete or need approval
- QR code scanning from terminal for quick mobile connection
- `/mobile` command in Claude Code to display download QR codes

---

## 3. How Features Compare (Official Matrix)

| Feature | Trigger | Claude runs on | Setup | Best for |
|---------|---------|---------------|-------|----------|
| **Dispatch** | Message from phone | Your machine (Desktop) | Pair mobile app with Desktop | Delegating work while away |
| **Remote Control** | Drive from claude.ai/code or mobile | Your machine (CLI/VS Code) | `claude remote-control` | Steering in-progress work |
| **Channels** | Push from chat app or webhook | Your machine (CLI) | Install channel plugin | Reacting to external events |
| **Slack** | @Claude in team channel | Anthropic cloud | Install Slack app | PRs and reviews from team chat |
| **Scheduled tasks** | Set a schedule | CLI, Desktop, or cloud | Pick a frequency | Recurring automation |

## 4. JTBD / User Moments

**Primary Job:** "When I step away from my workstation but have development work in progress, I want to monitor and direct Claude Code from my phone so I can keep development moving without being desk-bound."

**Secondary Jobs:**
- "When a CI failure or external event occurs, I want Claude to react automatically in my existing session so I can get immediate triage without manual intervention."
- "When I have recurring tasks (morning PR review, dependency checks, test runs), I want Claude to run them on a schedule so I can arrive to completed work."
- "When CLI tools can't reach a system I need, I want Claude to control my screen directly so I can automate GUI-dependent workflows."

## 5. Assumptions & Evidence

| Assumption | Type | Confidence | Evidence For | Evidence Against |
|------------|------|------------|--------------|------------------|
| Remote Control is production-ready for daily use | feasibility | high | GA on all plans, detailed docs, troubleshooting guide, auto-reconnect | 10-min network timeout, must keep terminal open |
| Dispatch is reliable for task delegation | feasibility | low | Shipped as research preview, works for simple tasks | ~50% success on complex tasks (community testing), Pro/Max only |
| Channels replace the need for OpenClaw-style setups | value | medium | Official Telegram/Discord/iMessage support, custom channel API | Research preview, limited to allowlisted plugins, requires Bun |
| /loop is useful for production automation | value | medium | Three-tier scheduling (session, desktop, cloud), natural language | Session-scoped /loop has 3-day expiry, no persistence |
| Computer Use is ready for autonomous workflows | feasibility | low | Impressive demos, prompt injection detection | macOS only, "still early", research preview, Pro/Max only |
| Auto Mode makes --dangerously-skip-permissions obsolete | value | medium | Separate classifier model, blocks hostile actions, Sonnet 4.6 reviewer | Research preview, can still allow risky actions on ambiguous intent |

### Evidence Grade Justifications

- **Remote Control (high confidence):** Full official documentation with detailed architecture, troubleshooting, CLI reference. Multiple independent sources confirm the polling-based outbound-only architecture. Version requirement (v2.1.51+) is specific and verifiable. Available on all plan tiers.
- **Dispatch (low confidence):** Only available as research preview. The ~50% complex task success rate comes from a single practitioner blog post (Mejba Ahmed), not systematic testing. Limited to Pro/Max plans suggests Anthropic is not confident enough for enterprise.
- **Channels (medium confidence):** Full official documentation with setup guides, source code on GitHub (claude-plugins-official), clear MCP server architecture. But research preview status and Bun dependency are constraints. The VentureBeat article calling it an "OpenClaw killer" is editorializing.
- **Computer Use (low confidence):** Anthropic's own blog post says "still early" and "Claude can make mistakes." macOS-only and Pro/Max-only. The tiered permission model is well-designed but the underlying screen control reliability is acknowledged as work-in-progress.

## 6. Technical Signals

- **Feasibility for genie-team adoption:** moderate to complex
- **Constraints:**
  - Remote Control + Channels require claude.ai OAuth (not API keys) -- this conflicts with headless `claude -p` execution model
  - Dispatch requires Desktop app -- not compatible with CLI-only genie-team architecture
  - Computer Use requires macOS Desktop app -- not compatible with headless execution
  - Auto Mode requires Sonnet 4.6 or Opus 4.6 -- model-locked
  - Channels require Bun runtime
- **Needs Architect spike:** yes -- specifically around:
  - Whether Remote Control server mode (`--spawn worktree --capacity N`) could replace genie-team's custom worktree management
  - Whether Channels could serve as an intake mechanism for genie-team topics
  - Whether Auto Mode could replace `--dangerously-skip-permissions` in autonomous runs
  - Impact of claude.ai OAuth requirement on headless/CI execution

## 7. Feature-by-Feature Comparison: Genie Team vs Claude Code Native

### 7.1 Session Management & Worktrees

| Capability | Genie Team (Current) | Claude Code Native |
|------------|---------------------|-------------------|
| Worktree creation | `sessionStart(item, phase)` in `src/git/worktree.ts` — naming convention `repo--item-slug`, branch `genie/{item}-{phase}` | Remote Control server: `--spawn worktree` — auto-creates per connection |
| Concurrent sessions | Semaphore-based batch executor, configurable `--parallel N` | `--capacity 32` concurrent sessions in server mode |
| Session cleanup | `sessionCleanup()` with `--force`, stale reattachment | Auto-cleanup not documented; likely manual |
| Phase-aware branching | Branch per item per phase, one worktree per logical unit | Generic worktree per session — no phase concept |
| Session resume | `SessionTracker` passes `resumeSessionId` across phases (scout → shaper → architect → crafter → critic) | Session persistence via remote control reconnect; no cross-phase chaining |

**Verdict:** Genie Team's worktree management is **more sophisticated** — it understands phases, items, and the relationship between them. Remote Control's `--spawn worktree` is a simpler building block. **Retain custom worktree layer**, but consider using Remote Control's server mode as the underlying session host for remote access.

### 7.2 Scheduling & Recurring Tasks

| Capability | Genie Team (Current) | Claude Code Native |
|------------|---------------------|-------------------|
| Daemon mode | `genies daemon` — continuous polling, `--interval`, `--max-cycles`, `--parallel N`, SIGINT/SIGTERM | Not applicable — different model |
| Session-scoped loops | Not native (uses Claude's `/loop`) | `/loop 5m <prompt>` — CronCreate/CronList/CronDelete internally, 3-day expiry |
| Persistent scheduling | Not implemented — relies on external cron/CI | Desktop Scheduled Tasks — survives restarts, `~/.claude/scheduled-tasks/`, missed-run catch-up |
| Cloud scheduling | Not implemented | Cloud Scheduled Tasks — runs on Anthropic infra, fresh repo clone, min 1hr interval |
| Batch discovery | Auto-scans backlog for `status: shaped\|designed\|implemented` items | Not applicable — no backlog concept |
| Review cycles | Auto-retry on `CHANGES_REQUESTED` verdict (1 cycle interactive, 3 in daemon) | Not applicable — no verdict concept |

**Verdict:** Genie Team's daemon mode is **uniquely valuable** — it understands the backlog, phases, and verdict loops. Claude's scheduling tiers (session/desktop/cloud) are good for **simple recurring tasks** but have no concept of backlog-driven work. **Retain daemon/batch**, but consider:
- **Adopt** Desktop Scheduled Tasks for simple recurring genies (nightly `/diagnose`, morning `/genie:status`)
- **Adopt** Cloud Scheduled Tasks for CI-independent recurring work
- **Prune** nothing — these are complementary, not overlapping

### 7.3 Remote Access & Mobile

| Capability | Genie Team (Current) | Claude Code Native |
|------------|---------------------|-------------------|
| Mobile control | None | Remote Control from Claude mobile app; Dispatch from phone |
| Web access | None | claude.ai/code connects to Remote Control sessions |
| Push notifications | None (silent failures in unattended mode per autonomous run lessons) | Dispatch sends push notifications on completion/approval-needed |
| Task delegation from phone | None | Dispatch routes tasks to Code sessions automatically |

**Verdict:** Genie Team has **zero remote/mobile capability**. This is a clear gap. **Adopt** Remote Control for interactive genie sessions. Dispatch is interesting but unreliable (50% complex task success) and Desktop-only — **monitor but don't adopt yet**.

### 7.4 Event-Driven Intake

| Capability | Genie Team (Current) | Claude Code Native |
|------------|---------------------|-------------------|
| External event intake | Manual topic creation in `docs/topics/`, manual `/discover` invocation | Channels — MCP servers push events into running sessions |
| CI integration | Exit codes + `--output-format stream-json` for monitoring | Custom channel plugins could bridge CI events |
| Chat integration | None | Telegram, Discord, iMessage channels |
| Webhook support | None | Custom channel plugins can receive webhooks |

**Verdict:** Channels represent a **new capability class** that Genie Team doesn't have. Custom channel plugins could bridge CI failures, PR comments, or Slack messages into genie sessions. **Adopt** Channels for event-driven intake, but the current topic file → `/discover` flow is more structured and should be **retained** for deliberate discovery work.

### 7.5 Permission Management

| Capability | Genie Team (Current) | Claude Code Native |
|------------|---------------------|-------------------|
| Autonomous execution | `--dangerously-skip-permissions` (required per autonomous run lessons) | Auto Mode — classifier model reviews each tool call |
| Phase-specific tool allowlists | CLI contract defines allowed tools per phase (discover: read-only, deliver: read/write/execute) | Not applicable — no phase concept |
| Safety model | Trust-based: skip permissions or don't | Risk-based: separate Sonnet 4.6 classifier blocks scope escalation, prompt injection |
| Enterprise control | Not applicable | `autoMode` managed setting, customizable classifier rules |

**Verdict:** Auto Mode is a **significant upgrade** over `--dangerously-skip-permissions`. The classifier approach (separate model reviews each action) is fundamentally safer than binary trust. **Adopt** Auto Mode when auth model allows, but **retain** phase-specific tool allowlists as an additional layer — they're more granular than Auto Mode's intent-matching.

### 7.6 Computer Use

| Capability | Genie Team (Current) | Claude Code Native |
|------------|---------------------|-------------------|
| GUI automation | Playwright MCP (research, per `docs/analysis/20260214_research_claude_app_interaction_capabilities.md`) | Computer Use — screen control as last resort |
| Tool hierarchy | Not formalized | Connectors > Bash > Chrome extension > Computer Use |

**Verdict:** Computer Use is **not relevant** to Genie Team's current scope. Genie Team operates on code, not GUIs. Playwright MCP covers web automation needs. **Skip** — revisit only if genies need to interact with GUI-only tools.

### 7.7 Context & Session State

| Capability | Genie Team (Current) | Claude Code Native |
|------------|---------------------|-------------------|
| Session state tracking | Zero-cost hooks (track-command.sh, track-artifacts.sh, reinject-context.sh) | None built-in — sessions are ephemeral |
| Cross-phase context | SessionTracker with `resumeSessionId` chaining | No concept of phase chaining |
| Context commands | `/context:load`, `/context:summary`, `/context:recall`, `/context:refresh` | No equivalent |
| Document trail | `docs/` directory with structured artifacts per phase | No equivalent |

**Verdict:** Genie Team's context management is **far ahead** of native Claude Code. The hook-based session state, phase chaining, and document trail are unique differentiators. **Retain entirely** — nothing to adopt from native here.

---

## 8. Strategic Assessment: Adopt / Enhance / Prune

### ADOPT (native features that fill real gaps)

| Feature | Priority | Blocker | Value |
|---------|----------|---------|-------|
| **Auto Mode** | High | claude.ai OAuth auth | Replaces `--dangerously-skip-permissions` with meaningful safety |
| **Remote Control** | Medium | claude.ai OAuth auth | Enables mobile access to genie sessions |
| **Desktop Scheduled Tasks** | Medium | Desktop app dependency | Simple recurring genie automation without custom daemon |
| **Channels (custom plugins)** | Medium | Research preview, Bun dependency | Event-driven intake for CI/PR/chat events |
| **Cloud Scheduled Tasks** | Low | Fresh clone model (no local state) | CI-independent recurring tasks |

### ENHANCE (our features that become better informed by native patterns)

| Genie Team Feature | Enhancement Opportunity |
|--------------------|----------------------|
| **Daemon mode** | Add notification hooks (could use Channels as notification sink) |
| **Worktree management** | Could offer Remote Control server mode as an optional backend for remote-accessible worktrees |
| **Permission model** | Layer Auto Mode classifier under phase-specific tool allowlists for defense-in-depth |
| **Session state hooks** | Expose session state to Channels so external systems can query genie status |
| **Preflight validation** | Add Auto Mode availability check; warn if falling back to `--dangerously-skip-permissions` |

### PRUNE (features we can drop if native equivalents are adopted)

| Candidate | Condition | Risk |
|-----------|-----------|------|
| `--dangerously-skip-permissions` usage | Auto Mode is GA + supports API key auth | Low — Auto Mode is strictly better |
| Custom session-scoped loop wrappers (if any) | `/loop` covers the use case | None — we already delegate to Claude's `/loop` |

**Assessment:** Very little to prune. Genie Team's features are mostly **complementary** to native Claude Code, not duplicative. The orchestration layer operates at a higher abstraction (backlog items, phases, verdicts, review cycles) that native features don't attempt to cover.

### THE AUTH WALL

**Critical finding:** Every adoption candidate is blocked by the same constraint: **claude.ai OAuth is required, API keys are not supported.** Genie Team's headless execution model (`claude -p` with `ANTHROPIC_API_KEY`) cannot use Remote Control, Channels, Auto Mode, or Dispatch.

**Resolution paths:**
1. **Migrate to OAuth:** Use `claude` CLI with OAuth login instead of API key. Works for interactive sessions but unclear for headless/CI.
2. **Hybrid model:** Interactive sessions use OAuth (getting Remote Control + Auto Mode), headless daemon keeps API key path.
3. **Wait for API key support:** Anthropic may extend these features to API key users. No timeline available.
4. **Agent SDK bridge:** The SDK migration (ADR-005) wraps `claude -p` — check if the SDK can authenticate via OAuth programmatically.

---

## 9. Opportunity Areas (Unshaped)

1. **Resolve the auth wall** — Spike on OAuth vs API key for genie-team's execution model. This unblocks everything else. Determine if `claude` CLI with OAuth can work in headless mode, or if a hybrid model (interactive=OAuth, daemon=API key) is needed.

2. **Auto Mode as defense-in-depth** — Layer Auto Mode's classifier under genie-team's phase-specific tool allowlists. Two levels of safety: Auto Mode catches scope escalation/injection, phase config catches phase-inappropriate tools.

3. **Remote Control for supervised genie sessions** — Run genie sessions with Remote Control enabled so the user can monitor and intervene from mobile. Not as a replacement for the orchestrator, but as an observation/override layer.

4. **Channels for event-driven genie work** — Build custom channel plugins that bridge CI failures, PR comments, and deploy events into running genie sessions. This could evolve the current "pull from backlog" model into a "push events trigger discovery" model.

5. **Desktop Scheduled Tasks for lightweight genie automation** — Use Desktop's persistent scheduling for simple recurring tasks (`/diagnose` nightly, `/genie:status` mornings) without needing the full daemon infrastructure.

## 10. Evidence Gaps

- **Auth model compatibility:** Can `claude` CLI authenticate via OAuth in headless/daemon mode? Or does OAuth require interactive browser flow? This is the single most important unknown.
- **Auto Mode classifier accuracy:** No published false-positive/false-negative rates. How often does it block legitimate genie actions? Cost impact of running a second model per tool call?
- **Remote Control server mode at scale:** No data on `--capacity 32` with concurrent genie sessions (memory, CPU, token costs).
- **Channels reliability:** No delivery guarantees, latency data, or failure mode documentation for Telegram/Discord polling.
- **Cloud Scheduled Tasks environment:** What tools are available? Can MCP servers run? What network access exists? Is the repo clone shallow or full?
- **API key support timeline:** Will these features ever support API keys, or is OAuth the permanent direction?
- **Enterprise availability:** Dispatch and Computer Use are Pro/Max only. No timeline for Team/Enterprise.
- **Cost impact:** Auto Mode runs a second model call per tool invocation. Channels poll continuously. No pricing data available.

## 11. Routing Recommendation

- [ ] **Continue Discovery** -- More exploration needed
- [ ] **Ready for Shaper** -- Problem understood
- [x] **Needs Architect Spike** -- Technical feasibility unclear
- [x] **Needs Navigator Decision** -- Strategic question

**Rationale:** The discovery question is well-mapped. The path forward requires two things:

1. **Architect spike on OAuth auth in headless mode** — This is the gate for all adoption. Test whether `claude` CLI can authenticate via OAuth without an interactive browser flow (e.g., device code flow, service account, or token caching). If not, determine if a hybrid auth model is viable.

2. **Strategic decision on adoption sequencing** — Given that Genie Team's orchestration layer operates at a higher abstraction than native features, the question isn't "replace vs keep" but "which native primitives to compose into the existing architecture." Recommended sequencing:
   - **Now:** Auto Mode adoption (highest safety ROI, simplest integration)
   - **Next:** Remote Control for supervised sessions + Desktop Scheduled Tasks for lightweight automation
   - **Later:** Channels for event-driven intake (requires custom plugin development)
   - **Skip:** Dispatch (unreliable), Computer Use (wrong scope)

**Key insight:** Genie Team's orchestration layer remains valuable even with full native feature adoption. Native features provide **infrastructure primitives** (session hosting, scheduling, event intake, permission classification). Genie Team provides **workflow semantics** (backlog-driven phases, verdict loops, context chaining, document trail). These are complementary layers, not competing ones.
