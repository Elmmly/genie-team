# C# Stack Profile

Stack profile template for C# / .NET projects. Used by `/arch:init` to generate project-specific configuration.

## Detection

| Indicator | Source |
|-----------|--------|
| `*.csproj` | Primary indicator |
| `*.sln` | Solution file (multi-project) |
| `*.csproj` → `TargetFramework` | .NET version |
| `global.json` | SDK version pinning |

## Version Detection

```
grep '<TargetFramework>' *.csproj | head -1 | sed 's/.*>\(.*\)<.*/\1/'
```

Maps: `net8.0` → .NET 8, `net7.0` → .NET 7, `net6.0` → .NET 6, `netcoreapp3.1` → .NET Core 3.1

## Framework Detection

| Dependency/Pattern | Framework |
|-------------------|-----------|
| `Microsoft.AspNetCore` | ASP.NET Core |
| `Microsoft.Maui` | .NET MAUI |
| `Blazor` in csproj | Blazor |
| `Microsoft.Azure.Functions` | Azure Functions |
| `Grpc.AspNetCore` | gRPC |
| `worker` SDK | Background Worker |

## Rules Content

Generate as `.claude/rules/stack-csharp.md`:

```markdown
# C# Stack Rules

## Version: .NET {version}

## Modern C# Patterns (.NET 6+)
- Use minimal hosting: `WebApplication.CreateBuilder(args)` — NOT `Startup.cs`
- Use top-level statements for `Program.cs`
- Use file-scoped namespaces: `namespace MyApp;`
- Use `global using` for commonly-used namespaces
- Enable `<Nullable>enable</Nullable>` in csproj
- Use records for immutable data: `record UserDto(string Name, string Email)`

## Dependency Injection
- Use constructor injection — NEVER field injection with `[Inject]`
- Register services in `Program.cs` or extension methods
- Use `IServiceCollection` extensions for module registration
- Prefer `AddScoped` for request-scoped, `AddSingleton` for stateless

## Error Handling
- Use exception filters: `catch (HttpRequestException ex) when (ex.StatusCode == 404)`
- Chain inner exceptions: `throw new AppException("context", ex)`
- Use `ILogger<T>` for structured logging
- Return `Result<T>` or similar for expected failures — exceptions for unexpected

## Async Patterns
- ALWAYS use `await` — NEVER `Task.Result` or `Task.Wait()` (causes deadlocks)
- Use `async Task` not `async void` (except event handlers)
- Use `CancellationToken` in async methods
- Use `ValueTask` for hot paths that often complete synchronously

## HTTP Clients
- NEVER `new HttpClient()` per request — use `IHttpClientFactory`
- Configure named/typed clients in DI
- Use `Polly` for retry policies

## Anti-Patterns
- No `Startup.cs` on .NET 6+ — use minimal hosting
- No `new HttpClient()` — use `IHttpClientFactory`
- No `Task.Result` / `.Wait()` — use `await` (deadlock risk)
- No `async void` — use `async Task` (exception handling)
- No nullable warnings suppressed — fix the null handling
- No `Thread.Sleep()` — use `await Task.Delay()`

## Verification
After editing C# files, run: `dotnet build --no-restore`
```

## CLAUDE.md Section

```markdown
### C# / .NET {version}
**Build & verify:** `dotnet build && dotnet test`
**Modern patterns:** Minimal hosting, file-scoped namespaces, records for DTOs
**Async safety:** Always `await`, never `Task.Result`/`.Wait()` (deadlock risk)
**HTTP:** `IHttpClientFactory`, never `new HttpClient()` per request
```

## Settings Permissions

```json
["Bash(dotnet build*)", "Bash(dotnet test*)", "Bash(dotnet run*)", "Bash(dotnet format*)"]
```

## Hook Verification

File extension match: `.cs`
Verification command: `dotnet build --no-restore 2>&1 | tail -5`
Fallback: `dotnet build 2>&1 | tail -10`

## Test Framework Detection

| Dependency | Framework | Command |
|-----------|-----------|---------|
| `xunit` | xUnit | `dotnet test` |
| `NUnit` | NUnit | `dotnet test` |
| `MSTest` | MSTest | `dotnet test` |
| `FluentAssertions` | FluentAssertions | (assertion library) |
| `Moq` | Moq | (mocking) |
| `NSubstitute` | NSubstitute | (mocking) |

## Known Pitfalls

1. **Outdated .NET patterns**: Claude generates `Startup.cs` + `ConfigureServices` for .NET 6+ projects. Rules enforce minimal hosting.
2. **Blocking async**: `Task.Result` and `.Wait()` cause deadlocks in ASP.NET. Rule explicitly forbids.
3. **Raw HttpClient**: Claude creates `new HttpClient()` per request, causing socket exhaustion.
4. **Nullable ignorance**: Claude suppresses nullable warnings instead of fixing null handling.
5. **Framework version confusion**: .NET 6/7/8 APIs differ significantly. Version detection is critical.
