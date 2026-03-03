# Kotlin Stack Profile

Stack profile template for Kotlin / Android projects. Used by `/arch:init` to generate project-specific configuration.

## Detection

| Indicator | Source |
|-----------|--------|
| `build.gradle.kts` with `kotlin` plugin | Primary indicator (Gradle Kotlin DSL) |
| `build.gradle` with `kotlin-android` | Primary indicator (Gradle Groovy) |
| `settings.gradle.kts` | Multi-module project |
| `libs.versions.toml` → `kotlin` | Version catalog (preferred) |
| `build.gradle.kts` → `jvmToolchain` | JVM target version |

## Version Detection

Version catalog (preferred):
```
grep '^kotlin' gradle/libs.versions.toml | head -1 | sed 's/.*= *"\(.*\)"/\1/'
```

Build file fallback:
```
grep -oP "kotlin\(\"[^\"]+\"\) version \"\K[^\"]+|kotlinOptions.*jvmTarget.*\"\K[0-9.]+" build.gradle.kts
```

## Framework Detection

| Dependency/Plugin | Framework |
|------------------|-----------|
| `com.android.application` plugin | Android app |
| `com.android.library` plugin | Android library |
| `org.jetbrains.compose` | Compose Multiplatform |
| `io.ktor:ktor-server` | Ktor (server-side) |
| `org.springframework.boot` plugin | Spring Boot (Kotlin) |
| `kotlin("multiplatform")` plugin | Kotlin Multiplatform |

## Android-Specific Detection

| File/Pattern | Detected |
|-------------|----------|
| `compileSdk` in build.gradle | Android SDK version |
| `minSdk` / `targetSdk` | API level targets |
| `libs.versions.toml` → `agp` | Android Gradle Plugin version |
| `libs.versions.toml` → `ksp` | KSP version |

## Rules Content

Generate as `.claude/rules/stack-kotlin.md`:

```markdown
# Kotlin Stack Rules

## Version: Kotlin {version}, Android API {minSdk}–{targetSdk}

## Jetpack Compose Patterns
- Use `remember` and `derivedStateOf` for expensive computations
- Use stable types as keys in `LazyColumn` / `LazyRow` items
- Mark classes as `@Stable` or `@Immutable` when appropriate
- Avoid allocations in composable functions (no `listOf()` inside composition)
- Use `Modifier` parameter as first optional parameter in composable functions
- Hoist state: composables receive state, emit events

## Kotlin Coroutines
- Use `viewModelScope` for ViewModel operations — NEVER `GlobalScope`
- Use `lifecycleScope` for UI-layer coroutines
- Use `withContext(Dispatchers.IO)` for blocking I/O — NEVER block Main
- Use `Flow` for reactive streams — `StateFlow` for UI state, `SharedFlow` for events
- Always handle cancellation — structured concurrency propagates automatically
- Use `supervisorScope` when child failures shouldn't cancel siblings

## Architecture (MVVM)
- ViewModel exposes `StateFlow<UiState>` — NOT `LiveData` in new code
- Use sealed classes/interfaces for UI state: `data class UiState(val items: List<Item>, val isLoading: Boolean)`
- One-way data flow: UI → ViewModel (events) → Repository → DataSource
- Use Hilt (`@HiltViewModel`, `@Inject constructor`) for dependency injection
- Repository pattern for data access — ViewModel never directly accesses data sources

## Build Configuration Safety
- Pin exact versions in `libs.versions.toml` — AGP, Kotlin, KSP must be compatible
- Use KSP (not kapt) for annotation processing — kapt is deprecated
- Always specify `jvmToolchain` or `jvmTarget` for consistent compilation
- Test version matrix changes in isolation before committing

## Material3
- Use `MaterialTheme.colorScheme` — NOT `MaterialTheme.colors` (Material2)
- Use `Surface`, `Card`, `TopAppBar` from `androidx.compose.material3`
- Follow Material3 typography: `MaterialTheme.typography.bodyMedium`

## Anti-Patterns
- No `GlobalScope` — use structured scopes (`viewModelScope`, `lifecycleScope`)
- No `LiveData` in new Compose code — use `StateFlow` + `collectAsStateWithLifecycle()`
- No `kapt` — migrate to KSP
- No blocking calls on Main dispatcher — use `withContext(Dispatchers.IO)`
- No `mutableListOf()` inside composable functions — use `remember`
- No `Thread.sleep()` — use `delay()` in coroutines
- No hardcoded Android API checks — use `@RequiresApi` or `Build.VERSION.SDK_INT`

## Verification
After editing Kotlin files, run: `./gradlew compileDebugKotlin`
```

## CLAUDE.md Section

```markdown
### Kotlin {version} (Android API {minSdk}–{targetSdk})
**Build & verify:** `./gradlew assembleDebug && ./gradlew testDebugUnitTest`
**Compose:** Hoist state, stable keys, `remember`/`derivedStateOf` for performance
**Coroutines:** `viewModelScope`/`lifecycleScope` only, never `GlobalScope`
**Build safety:** Pin AGP + Kotlin + KSP in `libs.versions.toml`
```

## Settings Permissions

```json
["Bash(./gradlew *)", "Bash(gradle *)", "Bash(adb *)", "Bash(kotlin *)"]
```

## Hook Verification

File extension match: `.kt`, `.kts`
Verification command: `./gradlew compileDebugKotlin 2>&1 | tail -20`
Fallback: `./gradlew assembleDebug 2>&1 | tail -20`

## Test Framework Detection

| Dependency | Framework | Command |
|-----------|-----------|---------|
| `junit:junit` | JUnit 4 | `./gradlew testDebugUnitTest` |
| `junit-jupiter` | JUnit 5 | `./gradlew testDebugUnitTest` |
| `io.mockk:mockk` | MockK | (mocking library) |
| `org.mockito.kotlin` | Mockito-Kotlin | (mocking library) |
| `app.cash.turbine` | Turbine | Flow testing |
| `androidx.compose.ui:ui-test-junit4` | Compose UI Test | `./gradlew connectedDebugAndroidTest` |
| `io.kotest:kotest` | Kotest | Property-based + BDD |

## MCP Recommendations

| MCP Server | Purpose | Install |
|-----------|---------|---------|
| `mobile-next/mobile-mcp` | Cross-platform device automation, screenshots | `claude mcp add mobile-mcp -- npx -y @anthropic/mobile-mcp` |
| `normaltusker/kotlin-mcp-server` | Gradle integration, Kotlin LSP (32 tools) | Build from source; see repo README |

## Known Pitfalls

1. **AGP + Kotlin + KSP version matrix**: The documented #1 failure mode. AGP 9.0 broke kapt support, causing Room incompatibility. Always pin exact compatible versions in `libs.versions.toml`.
2. **Library selection mismatch**: Claude may be proficient with older libraries (MPAndroidChart) but not newer ones (Vico). Test Claude's proficiency with candidate libraries before committing architecture.
3. **Coroutines structured concurrency**: `GlobalScope` usage, incorrect cancellation propagation, exception handling in `supervisorScope`. Explicit scope rules prevent most issues.
4. **No native IDE integration**: Unlike Xcode 26.3 with native Claude support, Android Studio has no equivalent native Claude agent integration. Use terminal Claude Code + MCP servers.
5. **Compose recomposition**: Claude can create recomposition performance issues — unnecessary recompositions from unstable keys, allocations inside composables, missing `remember`.
6. **Material2 vs Material3**: Claude may generate Material2 imports (`MaterialTheme.colors`) when Material3 is intended. Explicit rules prevent this.
