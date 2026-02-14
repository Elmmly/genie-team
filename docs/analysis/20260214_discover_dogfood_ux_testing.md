---
type: discover
topic: "Usability study capabilities for Genie Team — dogfood command for UX evaluation"
status: active
created: "2026-02-14"
updated: "2026-02-14"
supersedes: null
related:
  - docs/analysis/20260214_discover_mcp_servers_automation_testing.md
  - docs/analysis/20260214_scout_report_application_interaction_research.md
---

# Opportunity Snapshot: Usability Study Capabilities for Genie Team

## 1. Discovery Question

**Original:** An approach for having a `/dogfood` command backed by a skill for a user-empathetic agent to run the app, click through key flows, and determine how effective the UX is for delighting the user and making it easy to complete the JTBD. Flows should be automated for reuse. Key stats should be measured and reported on.

**Reframed:** How do we enable Genie Team to act as a synthetic usability tester — actually running target applications (web, iOS, Android, CLI), clicking through real user flows, scoring the experience against JTBD outcomes and brand guidelines, and producing actionable UX reports?

## 2. Claude's Actual Application Interaction Capabilities

The initial discovery incorrectly treated "click through the app" as metaphorical. Claude has **concrete, real capabilities** to interact with running applications:

### Web Applications

| Capability | Tool | Status | Approach |
|---|---|---|---|
| **Playwright MCP** | `@playwright/mcp` (Microsoft official) | GA / Production | Accessibility tree — no vision required. Fast (<1s), reliable, token-efficient |
| **Claude for Chrome** | Browser extension | Beta | Side-panel integration; clicks, fills forms, navigates in user's browser session |
| **Computer Use API** | `computer_20251124` tool | Beta | Screenshot + mouse/keyboard control of sandboxed desktop with Firefox |
| **Browser-Use** | Python framework | Community | Chrome DevTools Protocol, self-hosted |

**Best for web UX testing: Playwright MCP** — uses the accessibility tree (semantic structure) rather than screenshots, making it faster, more reliable, and cheaper than vision-based approaches.

### Mobile Applications (iOS & Android)

| Capability | Tool | Status | Approach |
|---|---|---|---|
| **Appium MCP** | `appium-mcp` (official Appium project) | Production/Beta | AI-driven element detection; 90% less maintenance vs brittle selectors |
| **Detox MCP** | Community | Beta | React Native-specific |

**Appium MCP** supports both real devices and emulators. Organizations report 90% reduction in test maintenance. Intelligent locator recovery falls back to learned alternatives when selectors break.

### Desktop Applications

| Capability | Tool | Status | Approach |
|---|---|---|---|
| **Computer Use API** | `computer_20251124` | Beta | Screenshot + mouse/keyboard. Only option for arbitrary desktop apps |
| **AppleScript MCP** | `peakmojo/applescript-mcp` + others | Community | macOS native automation; controls Finder, Notes, Calendar, etc. |
| **Windows UI Automation MCP** | `mcp-windows-desktop-automation` | Community | Windows UI Automation API; mouse/keyboard/window control |

**Computer Use** is the universal fallback for any GUI app but has 3-5s latency per action and vision hallucination risks.

### CLI Applications

| Capability | Tool | Status | Approach |
|---|---|---|---|
| **Bash tool** | Built into Claude Code | GA | Native command execution; evaluate output, chain commands |
| **Claude Code itself** | This session | GA | Already runs commands, reads output, makes judgments |

**CLI testing is the most natural fit** — Claude Code already runs bash commands natively, can evaluate output quality, and chain multi-step interactions.

### Accessibility & Quality Auditing

| Capability | Tool | Status | Approach |
|---|---|---|---|
| **Axe MCP** | Deque Systems (official) | Production | Enterprise WCAG scanning; AI-guided remediation |
| **axe-core community MCPs** | `mcp-accessibility-scanner`, `a11y-mcp` | Community | WCAG mapping with selectors for remediation |

## 3. The UXAgent Research Precedent

**UXAgent** (published CHI EA '25, peer-reviewed) is a framework for LLM-driven usability testing:

- **Architecture:** Persona Generator → LLM Agent Module → Universal Browser Connector → Qualitative/Quantitative/Video output
- **Key finding: Exceeds human evaluator performance in issue detection**
  - App 1: UXAgent found **77%** of usability issues vs **63%** by 5 experienced human UX practitioners
  - App 2: UXAgent found **73%** vs **57%** by human evaluators
- **Appropriate for:** Pilot testing, rapid design iteration, regression detection, A/B comparison
- **Not appropriate for:** Replacing human UX research, summative studies, high-stakes compliance claims
- **Key limitation:** Synthetic user behavior is "detailed" but "not like real humans" — behavioral fidelity gap is fundamental

**Implication for Genie Team:** We can build a UXAgent-like capability that acts as a synthetic user, runs through flows, and identifies usability issues — positioned as a *pilot testing and regression detection* tool, not a replacement for human feedback.

## 4. Observed Behaviors / Signals

- **No experiential feedback loop exists.** The 7 D's workflow produces artifacts, but nobody evaluates whether the *experience* was good.
- **`/discern` reviews code, not UX.** The Critic checks AC compliance, code quality, tests — never "was this easy to use?"
- **Autonomous `/run` field tests surfaced UX friction ad hoc.** "Edit-before-read wasted 4 turns", "critic was pedantic" — captured in memory, not structured measurement.
- **The tooling to actually test exists.** Playwright MCP, Appium MCP, Computer Use, Bash tool — Claude can literally click through web/mobile/desktop/CLI apps today.
- **UXAgent research validates the approach.** Peer-reviewed at CHI '25, outperforms human evaluators on issue detection.

## 5. Pain Points / Friction Areas

- **No one is using Claude's app interaction capabilities for UX evaluation.** The tools exist but aren't connected to a usability testing workflow.
- **No UX scoring rubric.** Even if Claude runs through an app, how does it score the experience? Against what criteria?
- **Phase transition friction is unmeasured.** Handoffs between genies are where UX often breaks — invisible today.
- **No regression detection.** When a genie prompt changes, we can't detect whether UX quality degraded.
- **No brand alignment testing.** Even when brand guidelines exist, genie outputs aren't checked against them.
- **Latency impact unknown.** Computer Use has 3-5s per action; Playwright MCP is sub-second — which matters for realistic UX simulation.

## 6. JTBD / User Moments

**Primary Job:**
"When I'm building or improving a product, I want an AI to act as a real user — run my app, attempt key tasks, identify friction — so I can catch usability problems before real users hit them."

**Supporting Jobs:**
1. "When I've changed a genie prompt or app feature, I want to re-run the same UX flows against the new version so I can detect regressions automatically."
2. "When I'm adding a new feature to any project, I want to simulate diverse user personas completing the JTBD so I can identify where different users struggle."
3. "When reviewing a product before release, I want objective UX scores against brand guidelines and design principles so I can make ship/no-ship decisions with data."
4. "When I install Genie Team into a client project, I want to dogfood the end-to-end experience on that project's actual app so I can demonstrate value."

## 7. Assumptions & Evidence

| Assumption | Type | Confidence | Evidence For | Evidence Against |
|---|---|---|---|---|
| Claude can interact with web apps as a user would | Feasibility | **High** | Playwright MCP (GA, Microsoft official), Claude for Chrome (beta), Computer Use API (beta) | Vision-based approaches have coordinate hallucination risk |
| Claude can interact with mobile apps | Feasibility | **High** | Appium MCP (official, iOS + Android, real devices + emulators) | Latency 2-4s per action; less mature than web |
| Claude can interact with CLI apps | Feasibility | **High** | Built-in Bash tool, already GA in Claude Code | Interactive TUI apps (curses) may break terminal state |
| Claude can interact with desktop GUI apps | Feasibility | **Moderate** | Computer Use API (beta), AppleScript/Windows MCPs | 3-5s latency, vision hallucination, sandbox required |
| LLM-as-judge can evaluate UX quality | Feasibility | **High** | UXAgent (CHI '25): 73-77% issue detection vs 57-63% human; DeepEval, Braintrust production frameworks | Position/length bias; needs careful rubric design |
| Automated UX flows can be reused for regression testing | Feasibility | **High** | Braintrust "every trace becomes a test case"; Playwright MCP supports deterministic replay | Human decision points in workflows complicate reuse |
| UX delight is measurable by AI | Value | **Moderate** | HEART framework, task completion benchmarks, DX Core 4 metrics | Delight is partially subjective; synthetic users miss emotional nuance |
| Brand alignment can be scored programmatically | Feasibility | **Moderate** | LLM-as-judge can compare output against brand guidelines (tone, formatting, terminology) | No existing tool does this; would need custom rubric |

## 8. Technical Signals

- **Feasibility:** High (upgraded from Moderate)
- **Why high:** The core capability gap is closed. Claude CAN interact with running apps across all four platforms. The remaining work is workflow design and scoring rubrics — not fundamental capability gaps.
- **Tool selection by platform:**

| Platform | Recommended Tool | Why |
|---|---|---|
| Web apps | Playwright MCP | Fastest, most reliable, accessibility-tree based, token-efficient |
| iOS/Android | Appium MCP | Official, AI-driven element detection, both platforms |
| CLI apps | Bash tool (native) | Already built into Claude Code, zero setup |
| Desktop apps | Computer Use API | Only option for arbitrary GUI; AppleScript MCP for macOS-specific |
| Accessibility | Axe MCP | Enterprise WCAG scanning, Deque-backed |

- **Architecture insight:** Playwright MCP's accessibility-tree approach is fundamentally better than Computer Use's screenshot approach for web — faster, more reliable, cheaper. Computer Use is the fallback for desktop apps where no semantic API exists.
- **Needs Architect spike:** Yes — design the `/dogfood` workflow architecture: which MCPs to wire, how to define flows, scoring rubric format, report output

## 9. Opportunity Areas (Unshaped)

These are problem territories, NOT solutions:

1. **Synthetic usability testing across platforms** — Claude can now interact with web/mobile/desktop/CLI apps. How do we structure this into a repeatable usability study workflow that any project can use?

2. **UX scoring rubric design** — What does "delightful" mean, operationally? HEART framework (Happiness, Engagement, Adoption, Retention, Task Success) adapted for AI evaluation. How do we translate brand guidelines into scoring criteria?

3. **Reusable flow definitions** — How do we define user flows (task scenarios, personas, success criteria) in a format that's both human-readable and machine-executable? One flow definition, reusable across regression runs.

4. **UX regression detection** — When a genie prompt or app feature changes, automatically re-run flows and compare scores. Flag degradation.

5. **Cross-platform coverage** — Same user journey tested across web + mobile + CLI. Unified reporting.

6. **Genie Team self-dogfooding** — Use these capabilities on Genie Team itself: run `/discover`, `/define`, `/design`, `/deliver`, `/discern` flows and score the experience of using each genie.

7. **Brand alignment scoring** — Compare genie output (tone, terminology, formatting, visual design) against brand guidelines. Score alignment programmatically.

## 10. Evidence Gaps

### Missing Data
- No UX scoring rubric exists yet for any platform — needs to be designed
- No baseline UX metrics for Genie Team's own workflows
- No data on Playwright MCP + LLM-as-judge used together for UX evaluation (novel combination)
- No performance benchmarks for running automated UX flows at scale (cost, time, reliability)

### Unanswered Questions
- **Flow definition format:** How do we define a user flow? (YAML scenario? Gherkin? Freeform prompt?)
- **Persona modeling:** How do we simulate diverse users? (UXAgent's persona generator approach?)
- **Scoring calibration:** How do we calibrate LLM-as-judge scores against human UX expert ratings?
- **Scope for v1:** Start with CLI-only dogfooding of Genie Team? Or web+mobile for client projects?

## 11. Routing Recommendation

- [ ] **Continue Discovery** — More exploration needed
- [x] **Ready for Shaper** — Problem understood
- [ ] **Needs Architect Spike** — Technical feasibility unclear
- [ ] **Needs Navigator Decision** — Strategic question

**Rationale:** The capability landscape is now clear. Claude can interact with web apps (Playwright MCP), mobile apps (Appium MCP), desktop apps (Computer Use), and CLI apps (Bash). The UXAgent research validates that LLM-driven usability testing outperforms human evaluators on issue detection (73-77% vs 57-63%). The remaining work is:

1. **Shaper:** Define the appetite, scope, and acceptance criteria for a `/dogfood` capability
2. **Architect:** Design the workflow (MCP wiring, flow definition format, scoring rubric schema, report format)
3. **Crafter:** Build it

**Next:** `/define docs/analysis/20260214_discover_dogfood_ux_testing.md`

## 12. Research Sources

### Claude App Interaction Capabilities
- [Computer Use Tool — Anthropic Docs](https://platform.claude.com/docs/en/agents-and-tools/tool-use/computer-use-tool)
- [Claude Code Chrome Extension (beta)](https://code.claude.com/docs/en/chrome)
- [Playwright MCP — Microsoft GitHub](https://github.com/microsoft/playwright-mcp)
- [Appium MCP — Official GitHub](https://github.com/appium/appium-mcp)
- [Axe MCP Server — Deque Systems](https://www.deque.com/axe/mcp-server/)

### UXAgent (LLM Usability Testing)
- [UXAgent CHI EA '25 Paper](https://dl.acm.org/doi/10.1145/3706599.3719729)
- [UXAgent arxiv:2502.12561](https://arxiv.org/abs/2502.12561)
- [Simulating Usability Testing arxiv:2504.09407](https://arxiv.org/abs/2504.09407)
- [Synthetic Heuristic Evaluation](https://arxiv.org/html/2507.02306)

### LLM-as-Judge & Agent Evaluation
- [Demystifying evals for AI agents — Anthropic](https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents)
- [LLM-as-a-Judge — Langfuse](https://langfuse.com/docs/evaluation/evaluation-methods/llm-as-a-judge)
- DeepEval, Braintrust, Opik, Confident AI — production evaluation frameworks

### CLI & Developer Experience
- [10 design principles for delightful CLIs — Atlassian](https://www.atlassian.com/blog/it-teams/10-design-principles-for-delightful-clis)
- DX Core 4, SPACE framework, DORA metrics
- HEART framework (Google) — Happiness, Engagement, Adoption, Retention, Task Success

### MCP Ecosystem
- [Official MCP Registry](https://registry.modelcontextprotocol.io/)
- [Windows Desktop Automation MCP](https://github.com/mario-andreschak/mcp-windows-desktop-automation)
- [AppleScript MCP](https://github.com/peakmojo/applescript-mcp)

### Supporting Analysis (this session)
- `docs/analysis/20260214_discover_mcp_servers_automation_testing.md` — Full MCP server catalog
- `docs/analysis/20260214_scout_report_application_interaction_research.md` — Detailed capability matrix
