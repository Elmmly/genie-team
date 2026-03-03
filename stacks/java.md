# Java Stack Profile

Stack profile template for Java projects. Used by `/arch:init` to generate project-specific configuration.

## Detection

| Indicator | Source |
|-----------|--------|
| `pom.xml` | Maven project |
| `build.gradle` / `build.gradle.kts` | Gradle project |
| `pom.xml` → `maven.compiler.source` | Java version (Maven) |
| `build.gradle` → `jvmToolchain` | Java version (Gradle) |

## Version Detection

Maven:
```
grep -A1 'maven.compiler.source\|maven.compiler.release' pom.xml | grep -oP '>\K[0-9]+'
```

Gradle:
```
grep -oP 'jvmToolchain\(\K[0-9]+|sourceCompatibility.*JavaVersion.VERSION_\K[0-9]+' build.gradle
```

## Framework Detection

| Dependency | Framework |
|-----------|-----------|
| `spring-boot-starter` | Spring Boot |
| `spring-boot-starter-webflux` | Spring WebFlux (reactive) |
| `quarkus-*` | Quarkus |
| `micronaut-*` | Micronaut |
| `io.vertx` | Vert.x |
| `jakarta.ee` | Jakarta EE |
| `javax.servlet` | Java EE (legacy) |

## Rules Content

Generate as `.claude/rules/stack-java.md`:

```markdown
# Java Stack Rules

## Version: Java {version}

## Modern Java Patterns (Java 17+)
- Use records for data classes: `record UserDto(String name, String email) {}`
- Use sealed classes for type hierarchies: `sealed interface Shape permits Circle, Square`
- Use pattern matching: `if (obj instanceof String s) { ... }`
- Use text blocks for multi-line strings: `""" ... """`
- Use `Optional<T>` for nullable returns — NOT null

## Spring Boot Conventions (if detected)
- Use constructor injection — NEVER `@Autowired` field injection
- Use `@ConfigurationProperties` for typed config
- Use `@Transactional` at service layer, not controller
- Separate `@RestController` (web) from `@Service` (business logic)
- Use `@Valid` for request validation

## Error Handling
- Catch specific exceptions — NEVER catch bare `Exception`
- Use `@ControllerAdvice` for global exception handling
- Chain causes: `throw new AppException("context", e)`
- Use SLF4J: `log.error("context: {}", detail, exception)`
- Return problem details (RFC 7807) for REST APIs

## Reactive (WebFlux) — if detected
- NEVER use JPA/Hibernate in WebFlux — use R2DBC
- NEVER call `.block()` in reactive chains
- Use `Mono` for 0-1 results, `Flux` for 0-N results
- Use `WebClient` not `RestTemplate` for HTTP calls

## Jakarta EE Migration (Java 17+)
- Use `jakarta.*` namespace — NOT `javax.*`
- This applies to: persistence, servlet, validation, inject, transaction
- Spring Boot 3+ requires Jakarta EE 9+

## Build Tool
- Maven: `mvn clean compile` for build, `mvn test` for tests
- Gradle: `gradle build` for build, `gradle test` for tests

## Anti-Patterns
- No `@Autowired` field injection — use constructor injection
- No JPA entities in WebFlux pipelines — use R2DBC
- No `javax.*` on Jakarta EE 10+ — use `jakarta.*`
- No bare `catch (Exception e)` — catch specific types
- No `new Thread()` — use `ExecutorService` or virtual threads (Java 21+)
- No raw `RestTemplate` in new code — use `WebClient`

## Verification
After editing Java files:
- Maven: `mvn compile -q`
- Gradle: `gradle compileJava -q`
```

## CLAUDE.md Section

```markdown
### Java {version}
**Build & verify:** `mvn compile && mvn test` (or `gradle build && gradle test`)
**Modern Java:** Records, sealed classes, pattern matching (17+), virtual threads (21+)
**Spring Boot:** Constructor injection, `@ConfigurationProperties`, service-layer transactions
**Namespace:** `jakarta.*` (not `javax.*`) for Spring Boot 3+ / Jakarta EE 9+
```

## Settings Permissions

```json
["Bash(mvn *)", "Bash(mvn compile*)", "Bash(mvn test*)", "Bash(gradle *)", "Bash(gradle build*)", "Bash(gradle test*)", "Bash(gradle compileJava*)"]
```

## Hook Verification

File extension match: `.java`
Verification command (Maven): `mvn compile -q 2>&1 | tail -10`
Verification command (Gradle): `gradle compileJava -q 2>&1 | tail -10`

## Test Framework Detection

| Dependency | Framework | Notes |
|-----------|-----------|-------|
| `junit-jupiter` | JUnit 5 | Standard |
| `junit` (4.x) | JUnit 4 | Legacy — recommend migration |
| `mockito-core` | Mockito | Mocking |
| `assertj-core` | AssertJ | Fluent assertions |
| `testcontainers` | Testcontainers | Integration testing |
| `spring-boot-starter-test` | Spring Test | Includes JUnit 5 + Mockito + AssertJ |

## Known Pitfalls

1. **Reactive/blocking confusion**: Claude mixes JPA (blocking) into WebFlux (reactive) pipelines, causing thread pool exhaustion.
2. **`javax` vs `jakarta`**: Claude uses `javax.*` imports on Jakarta EE 10+ / Spring Boot 3+, causing compilation failures.
3. **Field injection**: Claude uses `@Autowired` on fields instead of constructor injection, making testing harder.
4. **Legacy patterns**: Claude generates `RestTemplate` instead of `WebClient`, catches bare `Exception`, uses `Thread.sleep()`.
5. **Build tool confusion**: Claude sometimes generates Maven commands for Gradle projects and vice versa.
