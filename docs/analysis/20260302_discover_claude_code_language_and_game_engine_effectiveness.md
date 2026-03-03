# Claude Code: Language & Game Engine Effectiveness Study

**Date:** 2026-03-02 (updated 2026-03-03: added mobile development sections)
**Type:** Discovery / Research
**Status:** Complete

---

## Executive Summary

Claude Code is a top-tier AI coding tool across the seven evaluated languages (TypeScript, Rust, Go, C#, Java, Swift, Kotlin) and shows strong — but uneven — capability across game engines and mobile platforms. The consistent finding: **Claude's raw model capability is high, but output quality is highly context-sensitive.** Projects that invest in CLAUDE.md configuration, skills/rules, and MCP integrations get dramatically better results than defaults.

**Mobile development note (added 2026-03-03):** iOS and Android native development are now included. The key dynamic: mobile development quality is gated by **feedback loop tooling** (MCP servers connecting Claude to Xcode/simulators/emulators). iOS tooling is more mature than Android. See sections 7 and 8.

### Key Numbers

| Benchmark | Best Claude Score | Rank |
|-----------|------------------|------|
| SWE-bench Verified | 80.9% (Opus 4.5) | 1st — first model to break 80% |
| Aider Polyglot | ~89.4% (Opus 4.5) | Top tier |
| DevQualityEval Go | 98.89% (Sonnet 3.5) | 2nd of 107 models |
| DevQualityEval Rust | 95.13% (Sonnet 3.7) | 3rd overall |
| SWE-Sharp-Bench C# | 30.67% (Sonnet 3.7) | 1st (but ~32pt gap vs Python) |
| Defects4J Java repair | >70% precision (Claude 4 models) | Best precision tier |
| Terminal-Bench | ~59.3% (Opus 4.5) | Leading |
| SWE-bench Multilingual | Leads 7 of 8 languages | 1st |
| KotlinHumanEval | 80.12% (Sonnet 3.5) | Tied GPT-4o; o1 leads at 91.93% |
| Swift-Eval | Score drops on Swift-specific features | Frontier models best (28-problem eval) |

### What These Benchmarks Measure

- **SWE-bench Verified** — The gold standard for real-world coding. 500 actual GitHub issues (mostly Python) from popular open-source repos. The AI must read the issue, find the relevant code, and produce a working fix. Scores = % of bugs successfully fixed. This is the closest proxy to "can it do real software engineering."

- **Aider Polyglot** — Tests code *editing* (not just generation) across 6 languages: C++, Go, Java, JavaScript, Python, Rust. Uses 225 hard Exercism exercises where the AI must edit existing files to pass tests. Created by Paul Gauthier (aider tool author). Best available multi-language editing benchmark.

- **DevQualityEval** — Evaluates code generation and unit test writing across multiple languages (Go, Java, Rust, others). Created by Symflower. Tests 100+ models on practical daily tasks (implement a function, generate tests). Scores = % of tasks where generated code compiles and passes tests.

- **SWE-Sharp-Bench** — The C#-specific equivalent of SWE-bench. 150 real issue-resolving tasks from 17 C# GitHub repositories. Created by Microsoft Research (Nov 2025). The only dedicated C# software engineering benchmark.

- **Defects4J** — 835 real Java bugs from open-source projects (JFreeChart, Commons Math, etc.). Used to evaluate automated program repair. Measures whether AI can correctly fix known Java bugs.

- **Terminal-Bench** — Tests AI agents on complicated real terminal tasks: compiling code, configuring systems, running builds. Measures agentic terminal competence, not just code generation.

- **SWE-bench Multilingual** — Extension of SWE-bench to 9 languages (300 tasks). Shows how models perform outside the Python-dominated training data. Reveals the "language familiarity gradient."

- **Multi-SWE-bench** (ByteDance) — Similar to SWE-bench Multilingual but larger: 1,632 real GitHub issues across 7 languages. Provides per-language difficulty breakdowns (easy/medium/hard).

- **KotlinHumanEval / Kotlin_QA** (JetBrains Research, Feb 2025) — The most comprehensive Kotlin-specific benchmark. Tests function generation (KotlinHumanEval) and open-ended explanation/QA. Published by JetBrains, the authoritative Kotlin stakeholder.

- **Swift-Eval** (MacPaw Research) — First Swift-oriented benchmark: 28 hand-crafted problems across 44 code LLMs. Tests Swift-specific language features. Smaller sample, but the only dedicated Swift coding evaluation available.

---

## 1. Overall Benchmark Landscape

### SWE-bench Verified (Real-World Software Engineering)

The gold standard — 500 human-verified GitHub issues from real repositories. Higher = more real bugs fixed autonomously.

| Model | Score | Date |
|-------|-------|------|
| Claude 3.5 Sonnet | 49% | Oct 2024 |
| Claude 3.7 Sonnet | 62.3% (70.3% with scaffold) | Feb 2025 |
| Claude Opus 4 | 72.5% | May 2025 |
| Claude Sonnet 4 | 72.7% | May 2025 |
| Claude Sonnet 4.5 | 77.2% (~82% parallel) | Sep 2025 |
| Claude Opus 4.5 | **80.9%** | Nov 2025 |

**Caveat:** SWE-bench is primarily Python repos. Language-specific slices exist in SWE-bench Multilingual but are smaller samples.

### Aider Polyglot (Multi-Language Code Editing)

225 Exercism exercises across C++, Go, Java, JavaScript, Python, and Rust. Measures code editing in context, not just generation.

- Claude 3.7 Sonnet: 60.4% (highest non-reasoning model at release)
- Claude 4 Opus: 72%
- Claude Opus 4.5: ~89.4%
- **Scaffold matters:** Same model (Claude 3.7) goes from 60.4% to 76.4% depending on agent architecture

### Key Interpretation

1. **SWE-bench dominance is real** — Claude has been #1 since 3.7 Sonnet
2. **Scaffolding adds 10-15 percentage points** — the agentic layer matters independently of model quality
3. **Competitive programming (LiveCodeBench) is a weakness** — Gemini and GPT lead on algorithmic contests; Claude leads on real engineering
4. **HumanEval/MBPP are saturated** — all frontier models score 90%+, no longer differentiating

---

## 2. TypeScript

### Benchmark Position

No TypeScript-specific benchmark exists at SWE-bench quality. Evidence is inferred from multilingual aggregates and community reports.

### Strengths

| Capability | Evidence Quality | Details |
|-----------|-----------------|---------|
| Multi-file refactoring | Moderate | 96% accuracy on PropTypes→TypeScript migrations; maintained cross-file context where Cursor required re-prompting |
| Advanced type patterns | Weak (community assertion) | Described as stronger than alternatives for complex generics, conditional types |
| Token efficiency | Single study | 5.5x fewer tokens than Cursor for identical tasks |
| Monorepo cross-file ops | Anecdotal | Full-session context maintenance vs. Cursor's per-file |

### Weaknesses

| Issue | Severity | Mitigation |
|-------|----------|-----------|
| **No auto type-check verification** | High | Claude claims errors fixed without running `tsc --noEmit`. Requires hooks or explicit CLAUDE.md instruction. Community workaround: `bartolli/claude-code-typescript-hooks` |
| **Framework pattern staleness** | Medium | Next.js 15+ async params/cookies/headers not in training data. Explicit version pinning in CLAUDE.md required |
| **Context drift in long sessions** | Medium | Interface/signature fidelity degrades — wrong argument order, duplicate exports. Caused by context compression |
| **CLAUDE.md maintenance burden** | Medium | Primary mechanism for conveying project conventions; manual to keep current |

### Community Resources

- CLAUDE.md templates for Next.js + TypeScript + Tailwind widely shared
- `bartolli/claude-code-typescript-hooks` — auto type-checking after edits
- `SpillwaveSolutions/mastering-typescript-skill` — Claude Code skill for TS patterns

### Comparison Table

| Dimension | Claude Code | Cursor | GitHub Copilot |
|-----------|-------------|--------|---------------|
| Multi-file tasks | Strong | Moderate | Weak (not agentic) |
| Type verification | Gap (no auto check) | Better (IDE inline) | Best (always visible) |
| Advanced types | Strong (weak evidence) | Moderate | Moderate |
| Framework awareness | Needs CLAUDE.md config | Built-in for popular stacks | GitHub-trained |
| Best for | Autonomous refactors, migrations | Active coding with visual feedback | Inline autocomplete |

### Research-Driven Recommendation

**Verdict: Proceed with high confidence. TypeScript is Claude Code's strongest production language.**

The evidence supports TypeScript as the highest-ROI language for Claude Code adoption:

1. **Highest natural affinity.** TypeScript/JavaScript dominate Claude's training corpus. Multi-file refactoring, type inference, and framework pattern knowledge are all strong out of the box.
2. **Install verification hooks immediately.** The TypeScript verification gap (no auto `tsc --noEmit`) is the single highest-risk issue. Use `bartolli/claude-code-typescript-hooks` or add post-edit hooks in your workflow. Without this, Claude will claim fixes work that don't compile.
3. **Pin framework versions in CLAUDE.md.** Next.js 15+, React Server Components, and async API changes are post-training-cutoff. Explicit version declarations eliminate the most common class of framework errors.
4. **Use for:** Multi-file refactoring, PropTypes→TypeScript migrations, monorepo cross-file operations, test generation, component scaffolding.
5. **Caution for:** Very advanced type-level programming (template literal types, recursive generics at scale) — evidence is weak. Manual review recommended for complex type gymnastics.

---

## 3. Rust

### Benchmark Position

| Benchmark | Model | Score | Notes |
|-----------|-------|-------|-------|
| Rust-SWE-bench (ICSE '26) | RustForger + Claude 3.7 | 28.6% of 500 tasks | 34.9% improvement over next best; uniquely solved 46 tasks |
| DevQualityEval v1.1 | Claude 3.7 Sonnet | 95.13% | 3rd overall |
| RustEvo2 (API currency) | All models | 56.1% pre-cutoff → 32.5% post-cutoff | Structural training data limitation |
| SWE-bench Multilingual | Claude Opus 4.5 | Leads Rust slice | Small sample (~33 tasks) |

### Strengths

| Capability | Evidence Quality | Details |
|-----------|-----------------|---------|
| Lifetime/borrow checker resolution | High (multiple sources) | Claude traces from symptom to root cause — distinguishing lifetime extension vs. ownership restructuring |
| Compiler as feedback loop | High | Rust's strict type system catches Claude's mistakes automatically. "Like the most efficient expert code reviewer" |
| Large-scale scaffolding | High | 100K-line C compiler in Rust (16 agents, $20K); 100K TS→Rust port ($200); Rue language (100K lines in 11 days) |
| Learning amplification | Moderate | Doubles as tutor + generator; explains ownership/async while building |
| Result/Option handling | Moderate | Good when explicitly prompted |

### Weaknesses

| Issue | Severity | Mitigation |
|-------|----------|-----------|
| **Non-idiomatic by default** | High | Overuses `.unwrap()`, `.clone()` to escape borrow checker instead of restructuring. Requires explicit CLAUDE.md rules |
| **Cross-file integration failures** | High | Compiles independently but fails when integrated. vjeux's fix: one method per file, comment scaffolding |
| **API currency (32.5% post-cutoff)** | High | Hallucinated crate APIs common for fast-moving ecosystem (axum, tokio, bevy). Use Context7 MCP or explicit docs |
| **Async complexity ceiling** | Medium | Simple async OK; Send+Sync+'static bounds, async-in-traits, multi-layer interactions need iteration |
| **Proc-macro generation** | Unknown (likely weak) | No benchmark; structurally hard (expansion context, hygiene) |
| **Capability ceiling** | Medium | C compiler project "nearly reached limits" — new features broke existing functionality |

### Notable Projects

1. **Claude's C Compiler** — 100K-line Rust C compiler, compiles Linux 6.9, 99% GCC torture test pass rate (16 agents, ~$20K)
2. **Rue Language** — Steve Klabnik's experimental systems lang, ~100K lines in 11 days
3. **vjeux's TS→Rust Port** — 100K lines ported in 1 month for ~$200

### Community Resources

- `minimaxir/rust-claude-md` — Community CLAUDE.md for Rust
- `actionbook/rust-skills` — Microsoft Pragmatic Rust Guidelines as Claude Skills
- JetBrains state of Rust ecosystem 2025 — AI tool adoption tracking

### Research-Driven Recommendation

**Verdict: Proceed for scaffolding and translation. Invest heavily in idiom enforcement for production code.**

The evidence shows Claude Code is remarkably productive for Rust at scale (100K+ line projects demonstrated) but produces non-idiomatic code by default:

1. **Lean into the compiler feedback loop.** Rust's strict type system is Claude's strongest collaborator. The generate→compile→fix cycle works reliably even when individual generations are imperfect. This is a structural advantage no other language offers at this level.
2. **Use community CLAUDE.md and skills.** `minimaxir/rust-claude-md` and `actionbook/rust-skills` (Microsoft Pragmatic Rust Guidelines) are proven. The idiom gap between default and configured output is the largest of any language studied.
3. **Explicitly prohibit anti-patterns.** `.unwrap()` in library code and `.clone()` to escape borrow checker pressure are Claude's most consistent bad habits. Ban them in CLAUDE.md with specific alternatives.
4. **Decompose for integration safety.** vjeux's key lesson: Claude generates files that compile independently but fail when integrated. One method per file with explicit interface comments catches this.
5. **Use for:** Large-scale scaffolding, TypeScript/C→Rust ports, algorithm implementation from papers, lifetime/borrow checker resolution, learning Rust while building.
6. **Caution for:** Proc-macros (no evidence of quality), unsafe code (no benchmark), async patterns with complex Send+Sync bounds (requires iteration). API hallucinations on fast-moving crates (axum, tokio, bevy) — always verify against current docs.
7. **Avoid for:** Projects requiring expert-level idiomatic Rust without human review. The C compiler project explicitly hit Claude's capability ceiling on complex systems work.

---

## 4. Go

### Benchmark Position

| Benchmark | Model | Score | Rank |
|-----------|-------|-------|------|
| DevQualityEval v1.0 | Claude 3.5 Sonnet | 98.89% | 2nd of 107 |
| Tessl Go bug fix (with MCP) | Claude Opus 4.5 | 100% success | — |
| SWE-bench Multilingual | Claude Opus 4.5 | Leads Go slice | 1st |
| Go Dev Survey usage | Claude Code | 25% of respondents | 3rd tool |

### The Context Engineering Gap

This is the defining finding for Go: Claude's performance is **dramatically context-sensitive.**

- **Without context:** Poor success rate on post-cutoff API tasks
- **With Tessl MCP context:** 100% success, 1.6x faster, 3x cheaper ($0.10 vs $0.30/trial)

### Strengths

| Capability | Evidence Quality | Details |
|-----------|-----------------|---------|
| Overall Go code generation | High (benchmark) | #2 of 107 models at 98.89% |
| Complex pattern reasoning | Moderate | Practitioner: "for complex Go patterns, Cursor with Claude" beats Copilot |
| Context-augmented performance | High | Tessl MCP: 100% on real Go bug fixes with proper docs |
| Rising adoption | High (survey) | 25% Go developer usage, growing year-over-year |

### Weaknesses

| Issue | Severity | Mitigation |
|-------|----------|-----------|
| **Obsolete idioms by default** | High | Uses `if-else` not `max(a,b)` (Go 1.21); manual loops not `slices.Contains`; no `cmp.Or`. JetBrains shipped `go-modern-guidelines` plugin specifically for this |
| **Goroutine/channel patterns** | Medium | Both Claude and Copilot struggle with channel synchronization. Subtle bugs surface under production load |
| **Incomplete error wrapping** | Medium | Generates bare `return err` instead of `fmt.Errorf("context: %w", err)`. Requires explicit CLAUDE.md rules |
| **Post-cutoff API blindness** | Medium | Falls back to older workarounds for recently-updated libraries |

### Community Resources

- JetBrains `go-modern-guidelines` plugin + `/use-modern-go` Claude Code command
- Tessl MCP — Go-specific context engineering
- Go Dev Survey: AI satisfaction at 55% (vs 90%+ for Go itself) — community has clear expectations gap

### Research-Driven Recommendation

**Verdict: Proceed with context engineering. The gap between default and configured Go output is the most dramatic of any language studied.**

The Tessl MCP finding (poor→100% success with proper context) is the single most compelling evidence that Claude Code's Go capability is unlocked by configuration, not limited by model quality:

1. **Install JetBrains `go-modern-guidelines` or equivalent.** This is non-negotiable. Without it, Claude generates pre-Go 1.21 idioms that will fail linters and frustrate reviewers. JetBrains shipped this plugin specifically because the problem is universal across AI tools.
2. **Specify Go version in CLAUDE.md.** "This project uses Go 1.22. Use `cmp.Or`, `slices.Contains`, `max/min` builtins." This single line eliminates the most common class of outdated idiom errors.
3. **Add explicit error wrapping rules.** Claude generates bare `return err` without context. CLAUDE.md rule: "Always wrap errors with `fmt.Errorf("functionName: %w", err)`" fixes this consistently.
4. **Add goroutine safety patterns.** Explicit rules for context cancellation, `errgroup`, bounded goroutines. Both Claude and Copilot struggle here — this is the highest-risk area for Go.
5. **Use for:** Complex multi-file Go services, API development, standard library usage, Go module management. Claude's 98.89% DevQualityEval score (2nd of 107 models) shows strong underlying capability.
6. **Caution for:** Channel synchronization patterns, post-cutoff library APIs. Budget for human review on concurrency code.
7. **Consider Tessl MCP** for projects using rapidly-evolving Go libraries. The measured result (100% success, 3x cheaper) is the strongest context-engineering ROI data point in this entire study.

### 2025 Go Developer Survey: AI Tool Usage

| Tool | Usage Share | Trend |
|------|-----------|-------|
| ChatGPT | 45% | Declining |
| GitHub Copilot | 31% | Flat |
| **Claude Code** | **25%** | **Rising** |
| Claude (web/API) | 23% | Rising |
| Gemini | 20% | Flat |

---

## 5. C#

### Benchmark Position

C# has a dedicated benchmark — SWE-Sharp-Bench (Microsoft Research, Nov 2025) — making this the most precisely measured non-Python language.

| Benchmark | Model | Score | Notes |
|-----------|-------|-------|-------|
| SWE-Sharp-Bench | SWE-Agent + Claude Sonnet 3.7 | **30.67%** (150 tasks) | 1st among tested models; Python equivalent: 62.4% — a 32-point gap |
| SWE-Sharp-Bench | SWE-Agent + GPT-4o | Lower than Sonnet 3.7 | — |
| SWE-bench Multilingual | Claude Opus 4.5 | Leads 7/8 langs (C# included) | Small per-language sample |
| Aider Polyglot | — | **C# not included** | Coverage gap — no direct aider data |

**Key artifact:** The 32-point Python-to-C# gap on SWE-Sharp-Bench is the clearest quantified evidence of Claude's language familiarity gradient. Claude is still #1 for C#, but at roughly half its Python effectiveness for autonomous bug resolution.

### Strengths

| Capability | Evidence Quality | Artifact/Details |
|-----------|-----------------|---------|
| Multi-file .NET orchestration | Moderate (practitioner reports) | Claude coordinates controller, service, repository, DTO, and test files coherently for CRUD operations. Copilot handles pieces but requires manual wiring |
| C# type system as safety net | Moderate (multiple independent reports) | Compiler catches Claude's mistakes — same dynamic as Rust. "The compiler becomes your ally in validating AI-generated code" |
| Code modernization transforms | Moderate (blog posts) | Callback→async/await, null checks→nullable reference types, loops→LINQ, pre-.NET 6→minimal APIs. Documented transformation patterns |
| ASP.NET Core DI patterns | Moderate | `@Service`, `@Repository`, constructor injection. Well-represented in training data. Dedicated Claude Code skills exist |
| Spring Boot 2→3 equivalent: .NET Framework→.NET Core migration | Moderate | `javax.*`→`jakarta.*` equivalent namespace changes; `Startup.cs`→minimal API migration documented |
| Unit test generation (xUnit/NUnit) | Moderate (community consensus) | Consistently cited as Claude Code's strongest Java/C# use case |
| Entity Framework Core | Moderate | Strongly-typed DbContext schema means Claude suggestions validated against actual model. Effective when DbContext provided in context |

### Weaknesses

| Issue | Severity | Artifact/Evidence | Mitigation |
|-------|----------|-------------------|-----------|
| **~32pt gap vs Python on real bugs** | High | SWE-Sharp-Bench: 30.67% C# vs 62.40% Python. Microsoft Research, 150 tasks, peer-reviewed | Structural — training data skew. Compensate with CLAUDE.md, verification hooks |
| **Outdated .NET patterns by default** | High | Generates pre-.NET 6 `Startup.cs` pattern; uses raw `HttpClient` over `IHttpClientFactory`; misses C# 12 primary constructors | Pin .NET version in CLAUDE.md; use `dotnet-skills` community resources |
| **No auto build verification** | High | Same pattern as TypeScript/Go — Claude claims fixes without running `dotnet build`. MSBuild timeout bug (#4185) compounds this in web sandbox | Add `dotnet build && dotnet test` to CLAUDE.md verification instructions; use hooks |
| **NuGet/MSBuild web sandbox bugs** | Medium | GitHub Issues #4185 (MSBuild timeout), #12087 (NuGet proxy auth). Local CLI unaffected | Use local CLI, not web sandbox |
| **DOTS/ECS (Unity-specific C#)** | Medium | Niche API, sparse training data. No documented evidence of quality | Keep performance-critical Unity code manually authored |
| **Roslyn source generators** | Unknown (likely weak) | No benchmark. Structurally complex (incremental generators, SyntaxProvider). Sparse corpus | Manual authorship recommended |
| **Span\<T\>, unsafe, P/Invoke** | Unknown (likely weak) | No direct evidence. Safety-boundary code requires precise usage | Manual review essential |

### Notable Artifacts

- **SWE-Sharp-Bench dataset** — 150 C# issue-resolving tasks from 17 real GitHub repos. The only dedicated C# software engineering benchmark. Published by Microsoft Research (Nov 2025). [arXiv](https://arxiv.org/html/2511.02352v3), [Hugging Face](https://huggingface.co/datasets/microsoft/SWE-Sharp-Bench)
- **dotnet-skills** (`Aaronontheweb/dotnet-skills`) — Community-maintained Claude Code skills for .NET, including 27 skills + Roslyn MCP tools
- **CLAUDE.md for .NET Developers** — Complete template with .NET version pinning, coding standards, verification commands ([codewithmukesh.com](https://codewithmukesh.com/blog/claude-md-mastery-dotnet/))
- **Roguelite deckbuilder** — Reported as 100% Claude-generated C# Unity code (via Unity MCP)
- **C# library vibe-coded** — Full library authored with Claude Code; author documented the workflow ([hamy.xyz](https://hamy.xyz/blog/2025-07_vibe-coded-csharp-library))

### Comparison: Claude Code vs. Competitors for C#

| Dimension | Claude Code | GitHub Copilot | JetBrains Rider AI |
|-----------|-------------|---------------|-------------------|
| Multi-file orchestration | Strong (agentic) | Weak (not agentic) | Moderate (Agent mode) |
| IDE C# integration | Terminal/external | Native (VS, VS Code, Rider) | Very strong (Roslyn AST) |
| Verification of output | Weak (no auto build) | Inline (IDE shows errors) | Inline + deep Roslyn |
| NuGet/SDK awareness | Training cutoff-bounded | GitHub-trained, more current | Live Roslyn analysis |
| Best use case | Complex multi-file tasks, architecture, migrations | Inline completion, common patterns | IDE-native, Roslyn-backed quality |

**Hybrid recommendation:** JetBrains Rider + Claude Agent (natively integrated as of Sep 2025) provides Roslyn's semantic understanding plus Claude's reasoning. This is likely the strongest C#-specific configuration available.

### Research-Driven Recommendation

**Verdict: Proceed with configuration investment. High ROI for enterprise .NET, moderate for greenfield.**

The evidence supports using Claude Code for C# with these conditions:

1. **Invest in CLAUDE.md first.** The gap between default and configured output is the largest of any language studied. Pin .NET version, specify modern patterns (minimal APIs, `IHttpClientFactory`, nullable reference types enabled, primary constructors), include `dotnet build && dotnet test` verification commands.
2. **Use `dotnet-skills` or equivalent.** Community resources compensate for the default quality gap. The ecosystem is smaller than TypeScript/Rust but active.
3. **Use local CLI, not web sandbox.** MSBuild timeout and NuGet proxy bugs (#4185, #12087) are environment-level blockers in the web sandbox. Local CLI has none of these issues.
4. **Pair with Rider AI for inline work.** Claude Code's terminal-based workflow excels at multi-file orchestration; Rider's Roslyn integration excels at inline correctness. Use both.
5. **Budget for the Python gap.** Expect ~50% of the autonomous effectiveness you'd get on a Python project. Human review is more critical for C# than for TypeScript or Go.
6. **Avoid for:** DOTS/ECS, Roslyn source generators, Span/unsafe/interop — these require manual authorship.

---

## 6. Java

### Benchmark Position

Java has multi-benchmark coverage but no single dedicated benchmark at SWE-Sharp-Bench's quality.

| Benchmark | Model | Score | Notes |
|-----------|-------|-------|-------|
| Multi-SWE-bench (ByteDance) | Claude Sonnet 3.7 | 13.48% easy, 13.85% medium, 0.41% hard | 128 Java issues. Java ranked 2nd after Python in model performance |
| Aider Polyglot | Claude Opus 4.5 | ~89.4% aggregate | Java is 1/6 of benchmark (~37 exercises). No per-language breakdown |
| DevQualityEval | Claude 3.7 Sonnet | "King of code generation" (with help) | Java in benchmark set but per-language C#/Java scores not prominently published |
| Defects4J (Java bugs) | Claude 4 models | >70% precision in repair | All systems exceeding 70% precision relied on Claude 4 models |
| SWE-bench Multilingual | Claude 3.7 Sonnet | 43% overall (vs 63% Python) | ~20pt penalty for non-Python languages. Java in middle tier |

**Key artifact:** The Defects4J finding is the strongest Java-specific signal — all high-precision (>70%) automated repair systems used Claude 4 models as the base, indicating Claude's Java reasoning is the best available for real bug fixing.

### Strengths

| Capability | Evidence Quality | Artifact/Details |
|-----------|-----------------|---------|
| Unit test generation (JUnit 5 + Mockito) | High (community consensus) | Consistently cited as Claude Code's single strongest Java use case. Generates AAA-pattern tests with coverage awareness |
| Spring Boot DI and annotation patterns | High (multiple documented migrations) | `@Service`, `@Repository`, `@Autowired`, constructor injection. Multiple Spring Boot 2.x→3.x migration successes documented |
| Spring Boot migration (2.x→3.x, Struts2→Spring) | High (blog artifacts) | Multiple end-to-end migration case studies: [Medium](https://medium.com/vibecodingpub/migrating-a-spring-boot-2-x-project-using-claude-code-4a8dbe13125c), [DEV](https://dev.to/damogallagher/modernizing-legacy-struts2-applications-with-claude-code-a-developers-journey-2ea7) |
| Java Streams API | Moderate (practitioner reports) | Functional patterns well-defined; generates idiomatic Stream chains with correct terminal operations |
| Records, sealed classes, pattern matching (Java 17+) | Moderate | Training includes finalized modern Java features. Generates correct record syntax and exhaustive switch expressions |
| Spring Security 6 / Jakarta EE migration | Moderate | Understands `javax.*`→`jakarta.*`, lambda DSL for SecurityFilterChain, `WebSecurityConfigurerAdapter` deprecation |
| Maven/Gradle standard configs | Moderate | Handles standard pom.xml, parent POMs, BOM imports, multi-module `settings.gradle` |
| Architectural reasoning | Moderate (practitioner report) | Acts as "reasoning and analysis assistant" for hexagonal, layered, event-driven architecture review |

### Weaknesses

| Issue | Severity | Artifact/Evidence | Mitigation |
|-------|----------|-------------------|-----------|
| **~20pt gap vs Python on real issues** | High | SWE-bench Multilingual: 43% vs 63% Python. Multi-SWE-bench: 13-14% on medium Java bugs | Structural — training data skew. Compensate with CLAUDE.md, explicit framework versions |
| **Reactive/blocking confusion** | High | Documented: Claude mixes JPA (blocking) with WebFlux (reactive). Suggests JPA queries inside reactive pipelines unless explicitly told to use R2DBC | Add explicit "reactive only: use R2DBC, not JPA" rule in CLAUDE.md |
| **Annotation processor ordering** | Medium | Maven annotation processor order (Lombok before MapStruct) is a documented pain point. Claude may generate incorrect ordering | Capture correct ordering in CLAUDE.md once; Claude follows it thereafter |
| **Modern vs legacy Java friction** | Medium | Claude defaults to modern patterns (Java 17+); generates records/sealed classes for projects stuck on Java 8. Creates compile errors on legacy codebases | Pin Java version in CLAUDE.md. For Java 8 projects, explicitly restrict available language features |
| **Complex distributed architecture ceiling** | Medium | Event-driven Kafka + CQRS + gRPC "can confuse even Opus" — complex multi-service reasoning hits context limits | Decompose to single-service tasks; use CLAUDE.md per service |
| **Custom Gradle plugins** | Low-Medium | Enterprise convention plugins, custom lifecycle configs exceed Claude's knowledge | Manual authorship for build infrastructure |
| **Context window pressure** | Medium | 200K token limit real constraint for large Java projects with many classes. "Lost in the middle" effect documented | CLAUDE.md with explicit architecture overview; decompose tasks by module |

### Notable Artifacts

- **Defects4J repair precision** — All >70% precision systems used Claude 4 models. 835 real Java bugs from open-source projects. [arXiv](https://arxiv.org/pdf/2506.17208)
- **Spring Boot 2.x→3.x migration** — End-to-end Claude-assisted migration documented: [Medium case study](https://medium.com/vibecodingpub/migrating-a-spring-boot-2-x-project-using-claude-code-4a8dbe13125c)
- **Struts2→Spring Boot modernization** — Full legacy modernization journey: [DEV Community](https://dev.to/damogallagher/modernizing-legacy-struts2-applications-with-claude-code-a-developers-journey-2ea7)
- **Android MVP in 4 days** — Complete Android app built by developer with zero Android experience using Claude Code: [DEV Community](https://dev.to/raio/i-built-an-android-app-in-4-days-with-zero-android-experience-using-claude-code-and-a-two-layer-2p44)
- **Spring Boot 4 Migration Skill** — Community Claude Code skill: [github.com/adityamparikh/spring-boot-4-migration-skill](https://github.com/adityamparikh/spring-boot-4-migration-skill)
- **Maven Central MCP** — Community-built MCP connecting Claude to Maven Central for dependency lookup: [DEV Community](https://dev.to/arvindand/how-i-connected-claude-to-maven-central-and-why-you-should-too-2clo)
- **Claude Agent in JetBrains IDEs** — Native integration (Sep 2025) gives IntelliJ users Claude's reasoning with IDE-aware context

### Comparison: Claude Code vs. Competitors for Java

| Dimension | Claude Code | GitHub Copilot | JetBrains IntelliJ AI |
|-----------|-------------|---------------|----------------------|
| Multi-file orchestration | Strong (agentic) | Weak (completion-based) | Moderate (Agent mode) |
| Complex business logic | Better (multi-class reasoning) | "Remains inaccurate" for multi-class | Moderate |
| Spring Boot awareness | Good with CLAUDE.md | Good for common patterns | Strong (IntelliJ Spring support) |
| IntelliJ integration | Terminal/external (or native via Claude Agent) | Native plugin | Native |
| Inline autocomplete | Weaker (terminal model) | Stronger (native IDE) | Strong |
| Best use case | Architecture, migrations, multi-file features | Inline completion, boilerplate | IDE-native coding flow |

### Research-Driven Recommendation

**Verdict: Proceed for Spring Boot projects and migrations. Caution for reactive Java and legacy Java 8.**

The evidence supports using Claude Code for Java with these conditions:

1. **Strongest for Spring Boot + JUnit.** The documented migration successes (Struts2→Spring, Spring Boot 2.x→3.x) and consistent test generation quality make this the highest-confidence Java use case. Spring Boot migration is a repeatable, high-value workflow.
2. **Pin Java version and Spring version in CLAUDE.md.** The modern-vs-legacy friction is real. Explicit version constraints prevent Claude from introducing Java 17+ syntax into Java 8 codebases.
3. **Add reactive boundary rules.** If using WebFlux: explicitly state "use R2DBC, not JPA" and "all repository methods return Mono/Flux" in CLAUDE.md. This prevents the documented blocking/reactive confusion.
4. **Capture annotation processor ordering once.** Lombok→MapStruct→compiler ordering in pom.xml is a known footgun. Document it in CLAUDE.md and Claude follows it reliably.
5. **Use IntelliJ + Claude Agent for daily work.** The native JetBrains integration provides IDE-aware context. Use terminal Claude Code for multi-file migrations and architectural tasks.
6. **Budget for the Python gap.** Expect ~70% of the autonomous effectiveness you'd get on Python (based on SWE-bench Multilingual gap). More human review needed than TypeScript or Go.
7. **Decompose distributed systems.** Don't ask Claude to reason across Kafka + CQRS + gRPC in a single session. Work one service at a time.
8. **Avoid for:** Custom Gradle plugin authorship, complex annotation processor development, Java 8 projects that can't adopt modern syntax (negative productivity from constant corrections).

---

## 7. iOS / Swift

### Benchmark Position

Swift lacks SWE-bench coverage entirely. Swift and Kotlin are absent from SWE-bench Multilingual, DevQualityEval, and Aider Polyglot. The best available data:

| Benchmark | Model | Score | Notes |
|-----------|-------|-------|-------|
| Swift-Eval (MacPaw, 28 problems) | Frontier models | Significant drops on Swift-specific features | No per-model scores publicly available |
| SWE-bench Multilingual | — | **Swift not included** | No Swift repos in benchmark corpus |

**Key structural gap:** The absence of a SWE-bench equivalent for Swift means all effectiveness evidence is practitioner-reported. This is a benchmark limitation, not a capability limitation.

### Strengths

| Capability | Evidence Quality | Details |
|-----------|-----------------|---------|
| SwiftUI scaffolding and UI generation | High (multiple independent reports) | Functional UI code that improves dramatically through iteration. Screenshot-based refinement effective — paste image, Claude identifies and fixes visual issues |
| Compiler-as-feedback-loop (xcodebuild) | High (2 detailed case studies) | Connecting `xcodebuild` to Claude transforms quality. "Like Rust's compiler — catches Claude's mistakes automatically" |
| Project-wide refactoring | High (multiple sources) | Extracted SwiftUI views, migrated architectural patterns. Kean.blog: "+3,672 −4,967 changes, ~90% generated by prompts" |
| Objective-C → SwiftUI rewrites | High (documented case study) | twocentstudios: Complete 12-year-old ObjC app rewritten to Swift/SwiftUI. "Super fun, productive, absolutely worth $20" |
| Prototyping speed | High (multiple reports) | Functional prototypes in 2-4 hours. App ready for iOS review in 8 hours with minimal iOS experience |
| Mock data and unit test generation | High (documented) | "Perfect accuracy, nearly instantly" for mock data and SwiftUI previews |
| Learning amplification | Moderate | Non-iOS developers shipped working apps with Claude Code assistance |

### Weaknesses

| Issue | Severity | Mitigation |
|-------|----------|-----------|
| **Swift Concurrency (async/await, actors)** | High | Multiple sources: universally cited as highest-risk area. `DispatchQueue.main.async` overuse, incorrect actor isolation, forward progress violations. Explicit CLAUDE.md rules; require manual concurrency review |
| **Deprecated API defaults** | High | Paul Hudson (Hacking with Swift): `foregroundColor()`, `cornerRadius()`, `NavigationView`, `ObservableObject`, `onChange()` 1-param variant all generated instead of modern equivalents. Add explicit prohibitions in CLAUDE.md |
| **iOS version targeting confusion** | High | Generates latest-API code for older targets; SwiftUI API changes between iOS 16/17/18 cause runtime issues. Pin `Platform: iOS 17+, Language: Swift 6.0` in CLAUDE.md |
| **Defaults to iOS 16-style architecture** | High | twocentstudios: "By default writes iOS 16 style code, favoring `@StateObject` and `@ObservableObject`" instead of iOS 17+ `@Observable` macro |
| **No `.pbxproj` modification** | High | Community consensus: "Never let AI modify .pbxproj files — one corrupted project file will waste hours." Create source files with Claude Code, add to Xcode manually |
| **Visual debugging blind spot** | Medium | Layout bugs produce no build error. XcodeBuildMCP + iOS Simulator MCP for screenshot capture partly mitigates |
| **SwiftUI compiler type-check errors** | Medium | Complex view type expressions trigger "unable to type-check in reasonable time." Explicit rule: extract views exceeding 100 lines |
| **Hallucinated or nonexistent APIs** | Medium | Paul Hudson: Claude generates plausible-looking but nonexistent API calls. Always run `xcodebuild` as verification |

### The Xcode 26.3 Inflection Point (February 2026)

Apple shipped native Claude Agent SDK integration into Xcode 26.3. This is structurally significant:

| Feature | Details |
|---------|---------|
| Claude Agent SDK integration | Same harness as Claude Code — subagents, background tasks, plugins |
| MCP support | Native Xcode MCP (20 tools): file ops, diagnostics, Apple docs, Swift REPL, SwiftUI previews |
| SwiftUI visual feedback | Claude captures Xcode Previews, sees visual output, iterates |
| Goal-based execution | Developer specifies objective; Claude breaks down task, picks files, iterates |

### The Feedback Loop Problem (and Solution)

The defining variable for iOS development quality is whether Claude can build, run, and observe the app autonomously.

**Before MCP tooling:** `write code → manually trigger build → copy error → paste back → repeat`

**With XcodeBuildMCP + iOS Simulator MCP:** `write → xcodebuild → structured error JSON → fix → install → launch → screenshot → iterate`

Documented result (blakecrosley.com): 8-10 minutes of manual error handling → **90 seconds autonomous**.

### Notable iOS Projects

1. **macOS App (Indragie Karunaratne)** — ~20,000 lines shipped, estimated <1,000 written by hand
2. **Vinylogue Swift Rewrite (twocentstudios)** — 12-year-old Objective-C iOS app rewritten to Swift/SwiftUI
3. **iOS App in 8 hours** — Developer with minimal iOS experience shipped to App Store review in 8 hours
4. **Kean.blog feature** — +3,672 −4,967 lines, ~90% Claude-generated, in production app

### Community Resources

- `keskinonur/claude-code-ios-dev-guide` — Comprehensive CLAUDE.md templates, XcodeBuildMCP integration
- `AvdLee/SwiftUI-Agent-Skill` — SwiftUI best practices agent skill (ForEach identity, iOS 26 patterns)
- `getsentry/XcodeBuildMCP` — 59 tools: build, test, simulator, LLDB, UI automation
- `joshuayoes/ios-simulator-mcp` — Simulator UI control and screenshot capture
- Hacking with Swift — "What to fix in AI-generated Swift code" (deprecated API list)

### Research-Driven Recommendation

**Verdict: Proceed with tooling investment. High ROI once MCP stack is configured.**

The evidence shows Claude Code is genuinely productive for iOS development — but only with proper MCP tooling. Without it, the broken feedback loop (no `xcodebuild` access) limits Claude to single-turn code generation with no verification.

1. **Configure XcodeBuildMCP before writing any code.** The feedback loop transformation (8-10 min → 90 sec) is the highest-ROI single action. Install: `claude mcp add XcodeBuildMCP -- npx -y xcodebuildmcp@latest mcp`
2. **Set minimum deployment target and Swift version in CLAUDE.md.** `Platform: iOS 17+ / macOS 14+, Language: Swift 6.0, UI: SwiftUI, Architecture: MVVM` — eliminates the largest class of API version errors.
3. **Add deprecated API prohibitions explicitly.** "Use `@Observable` not `ObservableObject`. Use `NavigationStack` not `NavigationView`. Use `foregroundStyle()` not `foregroundColor()`. Never modify `.pbxproj` files."
4. **Require explicit Swift Concurrency review.** Claude can write async/await but struggles with actor isolation and structured concurrency. Flag all `async` code for human review.
5. **Use Xcode 26.3 native integration for SwiftUI-heavy work.** The SwiftUI Preview visual feedback loop is uniquely valuable.
6. **Use for:** Project-wide refactoring, Objective-C → SwiftUI rewrites, prototyping, UI scaffolding, test generation.
7. **Caution for:** Swift Concurrency patterns, post-cutoff APIs (iOS 26), complex view hierarchies.
8. **Avoid:** Direct `.pbxproj` modification, complex concurrent actor patterns without human review.

---

## 8. Android / Kotlin

### Benchmark Position

| Benchmark | Model | Score | Notes |
|-----------|-------|-------|-------|
| KotlinHumanEval | Claude 3.5 Sonnet | **80.12%** | Ties GPT-4o; OpenAI o1 leads at 91.93% |
| Kotlin_QA | Claude 3.5 Sonnet | **8.38/10** | 4th of 5 models; DeepSeek-R1 leads at 8.79 |
| SWE-bench Multilingual | — | **Kotlin not included** | No Kotlin repos in benchmark corpus |

**Key interpretation:** Claude 3.5 Sonnet ties GPT-4o on Kotlin function generation but trails reasoning models (o1, DeepSeek-R1) by ~12 points. These are older model scores — Claude 4.5 Kotlin benchmarks are not published. JetBrains notes all models showed "knowledge is incomplete and can be outdated."

### Strengths

| Capability | Evidence Quality | Details |
|-----------|-----------------|---------|
| Jetpack Compose UI generation | High (multiple reports) | "Claude is great for Native Android" — specifically called out as better than alternatives for Compose |
| MVVM + ViewModel + Hilt architecture | High | StateFlow, ViewModel lifecycle, Hilt DI all well-handled. Patterns well-represented in training data |
| Coroutines (basic async/await) | Moderate | Simple suspend functions, basic Flow usage work. Complex structured concurrency needs guidance |
| Kotlin Multiplatform (KMP) | Moderate | "Claude was surprisingly helpful with KMP and CMP" — smart mapping of Jetpack Compose to Compose Multiplatform |
| Material3 component usage | Moderate | Material3 components generated competently |
| Zero-experience productivity | High | Multiple reports of non-Android developers shipping working apps |

### Weaknesses

| Issue | Severity | Mitigation |
|-------|----------|-----------|
| **AGP / Kotlin / KSP version matrix** | High | AGP 9.0 broke kapt support, causing Room incompatibility (documented 2-hour failure). Pin exact versions in CLAUDE.md using `libs.versions.toml` |
| **Library selection mismatch** | High | Design AI recommended Vico charts but Claude proficient with MPAndroidChart. "Before committing to a library, check the Implementation AI's proficiency first" |
| **Kotlin Coroutines structured concurrency** | High | `GlobalScope` usage, incorrect cancellation propagation, exception handling. Explicit scope rules in CLAUDE.md |
| **No native Android Studio integration** | Medium | Unlike Xcode 26.3, Android Studio has no equivalent native Claude agent integration |
| **Post-cutoff Android API levels** | Medium | Claude may use deprecated APIs for newer Android levels. Pin `minSdk` and `targetSdk` in CLAUDE.md |
| **Gradle complex configuration** | Medium | Custom plugins, version catalogs, build flavors — limited evidence of reliable generation |
| **Environmental setup amnesia** | Medium | Claude "constantly forgot about Android SDK location" — document SDK paths in CLAUDE.md |
| **Compose recomposition pitfalls** | Medium | Explicitly called out as known issue — use rules about `remember`, `derivedStateOf`, stable keys |

### The Android Tooling Gap

Unlike iOS (XcodeBuildMCP + native Xcode 26.3), Android lacks an equivalent mature autonomous feedback loop:

| Tool | Type | Purpose |
|------|------|---------|
| `mobile-next/mobile-mcp` | MCP server | Cross-platform: device management, app lifecycle, screenshot, accessibility tree |
| `normaltusker/kotlin-mcp-server` | MCP server | Gradle integration, Kotlin LSP, emulator interaction (32 tools) |
| `CursorTouch/Android-MCP` | MCP server | Lightweight ADB-based Android interaction |
| `AlexGladkov/claude-in-mobile` | MCP server | Unified Android (ADB) + iOS Simulator + Compose Multiplatform |

### Notable Android Projects

1. **Android MVP in 4 days** (dev.to/raio) — Developer with zero Android experience built a working MVP using 53 structured prompts across 7 phases
2. **KMP + CMP app** (Kotlin Slack) — Claude mapped Jetpack Compose to Compose Multiplatform while understanding platform differences

### Community Resources

- `fastmcp.me` Android Kotlin skill — MVVM + Compose + Room + Hilt + Coroutines patterns
- `normaltusker/kotlin-mcp-server` — Gradle integration + Kotlin LSP
- `callstackincubator/agent-skills` — 27 React Native skills (includes Android native profiling)
- Kotlin MCP SDK (official, JetBrains) — `modelcontextprotocol/kotlin-sdk`

### Research-Driven Recommendation

**Verdict: Proceed for Jetpack Compose projects. Invest in version pinning and library validation.**

Claude Code is genuinely capable for Android development, particularly Jetpack Compose UI work, but the tooling ecosystem is less mature than iOS:

1. **Pin the version matrix first.** AGP + Kotlin + KSP version incompatibility is the single highest-frequency failure. Create `libs.versions.toml` with exact versions and reference them in CLAUDE.md.
2. **Validate library choice against Claude proficiency.** Before committing to a library, test Claude's knowledge of it with a small implementation task. Switching libraries after architecture is committed is expensive.
3. **Add coroutine scope rules explicitly.** `GlobalScope` ban, `viewModelScope` for ViewModel operations, `lifecycleScope` for UI-layer coroutines.
4. **Use mobile-mcp for emulator feedback.** Without an emulator connection, Claude can't observe runtime behavior.
5. **Leverage Claude's Compose strength.** Evidence that Claude handles Compose better than alternatives for native Android is consistent across sources.
6. **Use for:** Jetpack Compose UI, MVVM architecture, Material3 components, KMP shared logic, zero-experience prototyping.
7. **Caution for:** Complex Gradle configurations, kapt/KSP migration paths, structured concurrency edge cases.
8. **Avoid for:** Custom Gradle plugin authorship, legacy Android below API 26 without explicit guidance.

---

## 8a. Cross-Platform Mobile Frameworks

### React Native — Strongest Cross-Platform Evidence

| Capability | Evidence | Quality |
|-----------|---------|---------|
| Expo project scaffolding | High — JS/TS training data abundance | Strongest area |
| Native module bridging | Medium — Callstack agent-skills includes native config | Good with skills |
| Performance optimization | Moderate — 27 dedicated skills from Callstack | Strong with skills |

**Community:** `callstackincubator/agent-skills` (27 skills), `senaiverse` 7-agent Expo toolkit. Cars24 Engineering reports 50% dev time reduction.

### Flutter / Dart — Capable with Caveats

| Capability | Evidence | Quality |
|-----------|---------|---------|
| Dart code generation | High — "writes the best Dart code with least hand-holding" | Strong |
| Widget composition | High — Multiple apps built successfully | Strong |
| Android toolchain config | Low — "constantly forgot Android SDK location" | Weak |

**Competitive note:** Dart is Google's language; Gemini has structural training data advantages. Competition is noted by the Flutter community.

### Kotlin Multiplatform (KMP) — Early-Stage Promising

Claude's cross-language capability is a natural fit for KMP (Kotlin shared logic + SwiftUI + Compose), but evidence is thin. One community report: "surprisingly helpful." Worth watching as Swift Export stabilizes.

### .NET MAUI — No Direct Evidence

Inherits C# capability profile from section 5. No Claude Code-specific MAUI case studies found.

| Framework | Claude Strength | Key Risk | Confidence |
|-----------|----------------|----------|------------|
| **React Native** | JS/TS training data; Expo ecosystem | Performance defaults | High |
| **Flutter / Dart** | Dart code quality; widget composition | Android toolchain amnesia; Gemini competition | Medium |
| **KMP** | Cross-language + both native UIs | Build time on iOS; thin evidence | Low-Medium |
| **.NET MAUI** | C# generation | No dedicated resources | Low |

---

## 9. Game Engines

### Summary Matrix

| Engine | Claude Strength | Key Risk | MCP Available | Best Fit |
|--------|----------------|----------|---------------|---------|
| **Unity (C#)** | MonoBehaviour, Editor scripting, boilerplate | DOTS/ECS, Shader Graph, API staleness | Yes (5,800+ stars) | Prototyping, debugging, boilerplate |
| **Unreal (C++)** | UPROPERTY/UFUNCTION macros, C++ scaffolding, shaders | Blueprints (binary), GAS complexity | Yes (UE5.7) | Systems code, algorithms |
| **Godot (GDScript)** | GDScript syntax, standard patterns, prototyping | Cognitive offload risk, v3/v4 confusion | Yes | Small-medium projects |
| **Bevy (Rust ECS)** | Rust compiler as guard, ECS concepts | ~3mo breaking changes, thin corpus | Limited | Experienced Rust devs only |
| **Web (Phaser/Three.js/PixiJS)** | **Strongest overall**, official support, small contexts | Physics edge cases | Yes (Phaser, PlayCanvas official) | All game types, best for beginners |
| **Custom Engine** | Algorithm implementation, graphics/shaders | Long-range coherence | N/A | Veterans with clear architecture |

### Unity (C#) — Strong

The most mature Claude integration ecosystem. Unity MCP (CoplayDev) has 5,800+ GitHub stars.

**Works well:** MonoBehaviour scripting, event handlers, Editor scripting (`EditorWindow`, `CustomPropertyDrawer`), debugging AR/mobile issues. Developers report 30-40% less time on routine coding.

**Gaps:** DOTS/ECS (niche API, sparse training data), Shader Graph (binary format, can't read), Unity version API drift (2021 LTS vs Unity 6).

### Unreal Engine (C++) — Good for C++, Problematic for Blueprints

Multiple MCP integrations available (UnrealClaude, Claudius, Unreal Code Analyzer).

**Works well:** UPROPERTY/UFUNCTION macro generation, include handling, C++ scaffolding. One developer one-shot implemented a lighting algorithm from a 2025 research paper. Another one-shot a compute shader backend.

**Critical gap:** Blueprints are binary `.uasset` files — Claude cannot read or meaningfully modify existing Blueprint graphs. GAS (Gameplay Ability System) has no documented evidence of quality.

### Godot (GDScript) — Good for Prototyping

Godot MCP enables two-way communication with the editor.

**Works well:** Signals, `@export`, `@onready`, scene tree access, state machines, autoloads. One developer built an RTS with Claude writing all code.

**Warning:** The RTS developer documented a key risk: **cognitive offloading** — "lost touch with the underlying code" when Claude wrote everything. Also, Godot 3 vs 4 API confusion is common.

### Bevy (Rust ECS) — Capable but Fragile

`bevy-agent` crate exists on crates.io; Bevy ECS Patterns Claude skill available.

**Works well:** Rust compiler catches mistakes; ECS fundamentals (Query, Commands, Res/ResMut) understood conceptually.

**Critical gap:** Bevy releases breaking API changes ~quarterly. Pre-1.0 API instability means Claude's training data includes patterns that no longer exist. Thinnest community corpus of any evaluated engine.

### Web Games (Phaser, Three.js, PixiJS, PlayCanvas) — Strongest Category

This is where Claude performs best for game development. Reasons: JS/TS training data abundance, small focused files, immediate visual feedback, no binary format blockers.

- **Phaser:** Official Phaser team published a Claude Code tutorial (Feb 2026). Complete vertical shooter built in ~3 hours (Claude did ~70% of code).
- **Three.js:** "Incredibly good at heavy lifting" — gets ~80% of the way on React/Three.js components.
- **PixiJS:** Has LLM-friendly docs at `pixijs.com/llms` — most AI-ready framework surveyed.
- **PlayCanvas:** Official MCP server. Developer built Cookie Clicker clone with zero prior PlayCanvas experience.

### Custom Engines — Surprisingly Strong for Algorithms

Best evidence: Randy Gaul (veteran C/C++ game programmer, Roblox):
- One-shot lighting algorithm from a 2025 research paper
- One-shot compute shader backend for custom engine
- "Tasks that previously took months now take under an hour"

Also: 16 Claude agents wrote a C compiler in Rust from scratch. Algorithm-from-paper implementation is a consistent strength across all engine/language contexts.

### Game Development Anti-Patterns

| Pitfall | Pattern | Mitigation |
|---------|---------|-----------|
| Deprecated API usage | Claude uses old Unity/Godot/Bevy APIs | Pin version in CLAUDE.md; feed current docs via MCP |
| Binary asset blindness | Can't read Blueprints, Shader Graphs, packed scenes | Keep critical logic in code, not visual graphs |
| Knowledge loss between sessions | Project quirks forgotten | CLAUDE.md captures conventions persistently |
| Scope escalation | Asking Claude to build too much at once | Playable milestones; small focused tasks |
| Cognitive offload | Developer loses understanding of AI-generated code | Active review; understand before accepting |
| "Fun" judgment | AI can't tell you what's fun | Human game design; Claude executes mechanics |

### Notable Game Dev Events

- **2025 Vibe Coding Game Jam** (organized by @levelsio): 10,000+ submissions, 80%+ AI-written code required. Claude was the dominant tool.
- **8-year-old builds 30 games in 30 days** — HTML/JS web games via Claude Code
- **Phaser official tutorial** — Phaser's team building production-quality tutorials with Claude as co-developer

### Research-Driven Recommendations by Engine

**Unity — Proceed. Install MCP first.**
The 5,800-star Unity MCP ecosystem and 30-40% time savings reports make Unity the strongest engine choice for Claude-assisted development. Install Unity MCP before writing a single line — without project context awareness, Claude generates code that compiles but doesn't fit your project architecture. Avoid DOTS/ECS and Shader Graph tasks. Pin your Unity version in CLAUDE.md.

**Unreal Engine — Proceed for C++ systems code. Avoid Blueprint-dependent workflows.**
Claude one-shots algorithms from papers and generates production-ready UPROPERTY/UFUNCTION C++ scaffolding. This is a genuine productivity multiplier for engine programmers. However, if your gameplay logic lives primarily in Blueprints, Claude cannot inspect or modify those binary assets — the workflow breaks down. Keep critical logic in C++, not visual graphs.

**Godot — Proceed for prototyping. Maintain code ownership.**
GDScript patterns work well and Godot MCP enables editor integration. However, the documented cognitive offloading risk is real: the developer who had Claude write all RTS code "lost touch with the underlying code." Use Claude for generation, but actively review and understand every file. Best for: small-medium projects, game jams, prototyping. Pin Godot 4 explicitly — Claude confuses Godot 3 and 4 APIs.

**Bevy — Proceed only for experienced Rust developers. Pin versions aggressively.**
Bevy's ~quarterly breaking changes make it the most fragile option. Claude generates blend-of-versions code that won't compile against your current Bevy version. The Rust compiler catches these errors (making iteration possible), but expect more compile→fix cycles than with stable engines. Always specify exact Bevy version. Not recommended for Bevy newcomers.

**Web Games (Phaser/Three.js/PixiJS/PlayCanvas) — Strongly proceed. Lowest friction, highest success rate.**
This is the clearest recommendation in the entire study. Web game frameworks have: abundant training data, small focused files, no binary format barriers, immediate visual feedback, and official framework support (Phaser tutorial, PixiJS LLM docs, PlayCanvas MCP). A complete game was built in ~3 hours. Start here if evaluating Claude for game development.

**Custom Engines — Proceed for algorithm implementation. Budget for architectural oversight.**
Claude excels at translating research papers into working shader/graphics code — one-shotting lighting algorithms and compute shader backends. This is a genuine capability that changes the economics of engine development. However, long-range architectural coherence across a large custom codebase is still a human responsibility. Use Claude for subsystem implementation within an architecture you define and maintain.

---

## 10. Cross-Cutting Findings

### Finding 1: Context Engineering Is the Differentiator

Across all five languages and all game engines, the pattern is the same:

- **Default Claude output:** Good but not great. Outdated idioms, missing verification, non-idiomatic patterns
- **Context-engineered Claude output:** Dramatically better. Tessl MCP (Go): poor → 100% success. CLAUDE.md (TypeScript): framework errors eliminated. Rust skills: idiomatic output

**Implication:** The question is not "can Claude write X" but "have you configured Claude to write X well."

### Finding 2: Scaffolding Adds 10-15% to Raw Model Score

The same model performs very differently under different agent architectures:
- Claude 3.7 on aider polyglot: 60.4% base → 76.4% with Refact.ai scaffold
- SWE-bench: model score vs. agent-assisted score consistently differs by 5-15 points

### Finding 3: Verification Gaps Are Universal

- TypeScript: no auto `tsc --noEmit`
- Go: no auto `go vet` / `staticcheck`
- Rust: compiler catches some issues, but idiomatic quality isn't verified
- C#: no auto `dotnet build` (MSBuild timeout bug compounds this)
- Java: no auto `mvn compile` / `gradle build`
- Swift: no auto `xcodebuild` (solved with XcodeBuildMCP)
- Kotlin/Android: no auto Gradle build (partially solved with mobile-mcp)
- Game engines: no auto playtesting

Claude generates → claims it works → doesn't verify. This is consistent across all contexts.

### Finding 6: Mobile Development Is Gated by Feedback Loop Tooling

The mobile platforms (iOS, Android) reveal a pattern distinct from server-side languages: **effectiveness is gated not by model capability but by build/run/debug loop access.** Server-side languages have terminal-native toolchains (go build, cargo check, tsc). Mobile requires IDE tooling (Xcode, Android Studio) that historically broke the autonomous agentic loop.

The MCP ecosystem (XcodeBuildMCP, mobile-mcp) has largely solved this for iOS. Android remains less mature. This finding reinforces Finding 1 (context engineering) but adds a new dimension: for mobile, "context" includes not just instructions but autonomous build-and-observe capability.

### Finding 7: Platform API Version Drift Is the Mobile-Specific Variant of Staleness

Every server-side language has a staleness problem (Go 1.21 idioms, .NET 6+ patterns). Mobile platforms have a more acute version:
- **iOS:** API changes every year (iOS 16/17/18/26 all have different SwiftUI APIs). `@Observable` vs `@ObservableObject` is the same class of issue as `.NET 6 minimal hosting` vs `Startup.cs`
- **Android:** AGP + Kotlin + KSP version matrix creates a three-dimensional compatibility problem that no other platform exhibits
- **Both:** Deprecated API defaults are the single most reported issue across all mobile case studies

### Finding 4: Community Workaround Ecosystem as Signal

The proliferation of community-built CLAUDE.md templates, skills, hooks, and MCP integrations is itself evidence: developers are compensating for known gaps. The gap between "default Claude" and "configured Claude" is large enough to sustain an ecosystem.

### Finding 5: Binary Formats Are the Hard Boundary

Across game engines, the consistent wall is binary/visual formats: Blueprints, Shader Graphs, binary prefabs, packed scenes. Claude's effectiveness drops to near-zero for any workflow requiring inspection of these formats.

---

## 11. Recommendations by Use Case

### For a New TypeScript Project
1. Create a CLAUDE.md with explicit framework versions, async patterns, and build commands
2. Install TypeScript verification hooks (auto `tsc --noEmit` after edits)
3. Expect strong multi-file refactoring; budget for framework edge case review
4. **Confidence: High** — TypeScript is Claude's most natural territory

### For a New Rust Project
1. Use a community CLAUDE.md (minimaxir or actionbook/rust-skills)
2. Explicitly prohibit `.unwrap()` in library code, flag `.clone()` as a smell
3. Decompose large tasks to one method per file to catch integration failures early
4. Lean into the compiler feedback loop — generate → compile → fix is reliable
5. **Confidence: High for scaffolding, Medium for idiomatic quality**

### For a New Go Project
1. Install JetBrains `go-modern-guidelines` or equivalent rules
2. Specify Go version in CLAUDE.md with modern API expectations
3. Explicit error wrapping rules (`fmt.Errorf("context: %w", err)`)
4. Explicit goroutine safety patterns (context cancellation, errgroup)
5. **Confidence: High with context engineering, Medium without**

### For a New C# / .NET Project
1. Create a CLAUDE.md with .NET version, modern pattern requirements, and `dotnet build && dotnet test` verification
2. Use `dotnet-skills` (Aaronontheweb) or .NET Claude Kit community resources
3. Use local CLI — web sandbox has MSBuild timeout and NuGet proxy bugs
4. Pair with JetBrains Rider + Claude Agent for the strongest C#-specific setup
5. **Confidence: Medium** — Claude is #1 for C# but at ~50% of Python effectiveness. More human review needed

### For a New Java / Spring Boot Project
1. Create a CLAUDE.md with Java version, Spring version, and annotation processor ordering
2. Add explicit reactive/blocking boundary rules if using WebFlux
3. Leverage Claude's documented strength in Spring Boot migrations (2.x→3.x, Struts2→Spring)
4. Use IntelliJ + Claude Agent integration for daily coding; terminal Claude Code for migrations
5. **Confidence: Medium-High for Spring Boot** — Multiple documented migration successes. Medium for reactive Java

### For a New iOS / Swift Project
1. Install XcodeBuildMCP first: `claude mcp add XcodeBuildMCP -- npx -y xcodebuildmcp@latest mcp`
2. Set deployment target and Swift version in CLAUDE.md: `Platform: iOS 17+, Language: Swift 6.0, UI: SwiftUI`
3. Add deprecated API prohibitions: `@Observable` not `ObservableObject`, `NavigationStack` not `NavigationView`, `foregroundStyle()` not `foregroundColor()`
4. Never let Claude modify `.pbxproj` files — create source files, add to Xcode manually
5. Require human review on all Swift Concurrency (async/await, actors) code
6. **Confidence: High with MCP tooling, Medium without** — The feedback loop is the differentiator

### For a New Android / Kotlin Project
1. Pin AGP + Kotlin + KSP versions in `libs.versions.toml` and reference in CLAUDE.md
2. Test Claude's proficiency with candidate libraries before committing architecture to them
3. Add explicit coroutine scope rules: ban `GlobalScope`, specify `viewModelScope`/`lifecycleScope`
4. Install mobile-mcp for emulator feedback: `claude mcp add mobile-mcp -- npx -y @anthropic/mobile-mcp`
5. Leverage Claude's Compose strength — evidence shows it handles Compose better than alternatives
6. **Confidence: Medium-High for Jetpack Compose** — Version matrix complexity is the primary risk

### For React Native / Cross-Platform Mobile
1. Install Callstack agent skills (27 skills): performance, native bridging, accessibility
2. Use Expo for project scaffolding — strongest area due to JS/TS training data
3. For Flutter: declare state management approach in CLAUDE.md; document Android SDK paths
4. For KMP: early-stage promising but thin evidence. Test Claude's KMP knowledge before committing
5. **Confidence: High for React Native, Medium for Flutter, Low-Medium for KMP**

### For Game Development
1. **Start with web (Phaser/Three.js)** if possible — lowest friction, strongest results
2. **Unity/Unreal:** Invest in MCP setup first — without project context, quality drops significantly
3. **Godot:** Good for prototyping but actively review generated code to maintain understanding
4. **Bevy:** Only for experienced Rust devs; always specify exact version
5. **Custom engines:** Claude excels at implementing algorithms from papers — leverage this strength
6. **All engines:** Use CLAUDE.md extensively; build in playable milestones; keep logic in code (not visual graphs)

---

## 10. Language Effectiveness Ranking (Research-Derived)

Based on the aggregate evidence across benchmarks, community reports, and artifact quality:

| Rank | Language | Confidence | Key Evidence | Proceed? |
|------|----------|-----------|-------------|----------|
| 1 | **TypeScript** | High | Dominant training corpus, strong multi-file refactoring, 5.5x token efficiency vs Cursor | Yes — install verification hooks |
| 2 | **Go** | High (with config) | 98.89% DevQualityEval (#2 of 107), 100% with Tessl MCP context | Yes — install go-modern-guidelines |
| 3 | **Rust** | High (scaffolding) / Medium (idiom) | 100K-line projects demonstrated, compiler feedback loop, 95.13% DevQualityEval | Yes — enforce idiom rules via CLAUDE.md |
| 4 | **Java** | Medium-High (Spring) | >70% Defects4J precision, multiple migration successes, JUnit generation strong | Yes for Spring Boot — pin versions, add reactive rules |
| 5 | **C#** | Medium | 30.67% SWE-Sharp-Bench (#1 but ~32pt Python gap), strong multi-file orchestration | Yes with investment — larger human review budget needed |

**Game engines ranked by Claude effectiveness:**

| Rank | Engine | Proceed? |
|------|--------|----------|
| 1 | Web (Phaser/Three.js/PixiJS) | Strongly yes |
| 2 | Unity (C#) | Yes — install MCP first |
| 3 | Unreal (C++) | Yes for C++ code — avoid Blueprint workflows |
| 4 | Godot (GDScript) | Yes for prototyping — maintain code ownership |
| 5 | Custom Engines | Yes for algorithms — human architectural oversight |
| 6 | Bevy (Rust ECS) | Experienced Rust devs only — pin versions aggressively |

---

## Sources

### Benchmarks
- [Anthropic SWE-bench Performance](https://www.anthropic.com/engineering/swe-bench-sonnet)
- [Anthropic: Introducing Claude 4](https://www.anthropic.com/news/claude-4)
- [Anthropic: Introducing Claude Opus 4.5](https://www.anthropic.com/news/claude-opus-4-5)
- [Anthropic: Introducing Claude Sonnet 4.5](https://www.anthropic.com/news/claude-sonnet-4-5)
- [Aider LLM Leaderboards](https://aider.chat/docs/leaderboards/)
- [DevQualityEval v1.0 — Symflower](https://symflower.com/en/company/blog/2025/dev-quality-eval-v1.0-anthropic-s-claude-3.7-sonnet-is-the-king-with-help-and-deepseek-r1-disappoints/)
- [DevQualityEval v1.1 — Symflower](https://symflower.com/en/company/blog/2025/dev-quality-eval-v1.1-openai-gpt-4.1-nano-is-the-best-llm-for-rust-coding/)
- [RustEvo2: API Evolution Benchmark](https://arxiv.org/abs/2503.16922)
- [RustForger (ICSE '26)](https://arxiv.org/html/2602.22764v1)
- [Terminal-Bench](https://www.tbench.ai/)
- [LiveCodeBench](https://livecodebench.github.io/leaderboard.html)
- [EvalPlus Leaderboard](https://evalplus.github.io/leaderboard.html)

### TypeScript
- [Claude Code vs Cursor — Builder.io](https://www.builder.io/blog/cursor-vs-claude-code)
- [Claude Code vs Cursor — Qodo](https://www.qodo.ai/blog/claude-code-vs-cursor/)
- [Claude Code TypeScript Hooks](https://github.com/bartolli/claude-code-typescript-hooks)
- [GitHub Issue #1344: Systematic TS Errors](https://github.com/anthropics/claude-code/issues/1344)
- [GitHub Issue #6928: TS Error Remediation](https://github.com/anthropics/claude-code/issues/6928)

### Rust
- [Claude Code and Rust — julian.ac](https://www.julian.ac/blog/2025/05/03/claude-code-and-rust/)
- [Building a C Compiler with Claude — Anthropic](https://www.anthropic.com/engineering/building-c-compiler)
- [Porting 100K TS to Rust — vjeux](https://blog.vjeux.com/2026/analysis/porting-100k-lines-from-typescript-to-rust-using-claude-code-in-a-month.html)
- [Best AI Coding Tools for Rust — Shuttle.dev](https://www.shuttle.dev/blog/2025/09/09/ai-coding-tools-rust)
- [Coding Rust with Claude Code and Codex — HackerNoon](https://hackernoon.com/coding-rust-with-claude-code-and-codex)

### Go
- [Write Modern Go Code — JetBrains GoLand Blog](https://blog.jetbrains.com/go/2026/02/20/write-modern-go-code-with-junie-and-claude-code/)
- [JetBrains go-modern-guidelines](https://github.com/JetBrains/go-modern-guidelines)
- [Making Claude Good at Go — Tessl](https://tessl.io/blog/making-claude-good-at-go-using-context-engineering-with-tessl/)
- [2025 Go Developer Survey](https://go.dev/blog/survey2025)
- [AI Coding Tools for Go — Skoredin](https://skoredin.pro/blog/golang/ai-coding-tools-go-2025)

### C#
- [SWE-Sharp-Bench — Microsoft Research](https://www.microsoft.com/en-us/research/publication/swe-sharp-bench-a-reproducible-benchmark-for-c-software-engineering-tasks/)
- [SWE-Sharp-Bench on arXiv](https://arxiv.org/html/2511.02352v3)
- [Claude Code for C# and .NET Developers — zenvanriel](https://zenvanriel.nl/ai-engineer-blog/claude-code-csharp-dotnet-developers/)
- [Claude Code vs GitHub Copilot for .NET — C-SharpCorner](https://www.c-sharpcorner.com/article/claude-code-vs-github-copilot-which-is-better-for-net-c-sharp-devs/)
- [CLAUDE.md for .NET Developers — codewithmukesh](https://codewithmukesh.com/blog/claude-md-mastery-dotnet/)
- [dotnet-skills — Aaronontheweb](https://github.com/Aaronontheweb/dotnet-skills)
- [Vibe-Coded C# Library — HAMY](https://hamy.xyz/blog/2025-07_vibe-coded-csharp-library)
- [MSBuild timeout bug — GitHub Issue #4185](https://github.com/anthropics/claude-code/issues/4185)
- [NuGet proxy bug — GitHub Issue #12087](https://github.com/anthropics/claude-code/issues/12087)

### Java
- [Multi-SWE-bench — ByteDance/arXiv](https://arxiv.org/pdf/2504.02605)
- [Defects4J repair precision with Claude — arXiv](https://arxiv.org/pdf/2506.17208)
- [Spring Boot 2.x→3.x Migration with Claude Code — Medium](https://medium.com/vibecodingpub/migrating-a-spring-boot-2-x-project-using-claude-code-4a8dbe13125c)
- [Modernizing Struts2 with Claude Code — DEV Community](https://dev.to/damogallagher/modernizing-legacy-struts2-applications-with-claude-code-a-developers-journey-2ea7)
- [Claude for Java Developers and Architects — JavaTechOnline](https://javatechonline.com/claude-for-java-developers-and-architects/)
- [Claude Code for Java Developers — zenvanriel](https://zenvanriel.com/ai-engineer-blog/claude-code-java-developers/)
- [Claude Agent in JetBrains IDEs — JetBrains](https://blog.jetbrains.com/ai/2025/09/introducing-claude-agent-in-jetbrains-ides/)
- [Android MVP in 4 Days with Claude Code — DEV Community](https://dev.to/raio/i-built-an-android-app-in-4-days-with-zero-android-experience-using-claude-code-and-a-two-layer-2p44)
- [Spring Boot 4 Migration Skill](https://github.com/adityamparikh/spring-boot-4-migration-skill)
- [Maven Central MCP — DEV Community](https://dev.to/arvindand/how-i-connected-claude-to-maven-central-and-why-you-should-too-2clo)

### Game Engines
- [Unity MCP — CoplayDev](https://github.com/CoplayDev/unity-mcp)
- [UnrealClaude](https://github.com/Natfii/UnrealClaude)
- [Godot MCP](https://github.com/ee0pdt/Godot-MCP)
- [Bevy Agent — crates.io](https://crates.io/crates/bevy-agent)
- [Phaser + Claude Code Tutorial](https://phaser.io/news/2026/02/phaser-claude-code-tutorial)
- [PixiJS LLM Docs](https://pixijs.com/llms)
- [PlayCanvas MCP Server](https://github.com/playcanvas/editor-mcp-server)
- [AI Assisted Coding — Randy Gaul](https://randygaul.github.io/coding/2026/02/23/AI-Assisted-Coding.html)
- [CLAUDE.md for Game Devs — Mr. Phil Games](https://www.mrphilgames.com/blog/claude-md-for-game-devs)
- [Render: Testing AI Coding Agents (2025)](https://render.com/blog/ai-coding-agents-benchmark)
- [Exhaustive Comparison of Coding LLMs 2026 by Language](https://blog.greeden.me/en/2026/02/12/exhaustive-comparison-of-coding-llms-2026-reviewing-gpt-claude-gemini-codestral-deepseek-and-llama-by-popular-programming-language/)
