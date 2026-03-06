# Go Stack Profile

Stack profile template for Go projects. Used by `/arch:init` to generate project-specific configuration.

## Detection

| Indicator | Source |
|-----------|--------|
| `go.mod` | Primary indicator |
| `go.mod` → `go` directive | Version source |
| `go.sum` | Dependency lock file |

## Version Detection

```
grep '^go ' go.mod | awk '{print $2}'
```

## Framework Detection

| Dependency | Framework |
|-----------|-----------|
| `github.com/gin-gonic/gin` | Gin |
| `github.com/labstack/echo` | Echo |
| `github.com/gofiber/fiber` | Fiber |
| `github.com/gorilla/mux` | Gorilla Mux |
| `github.com/go-chi/chi` | Chi |
| `google.golang.org/grpc` | gRPC |
| `github.com/spf13/cobra` | Cobra CLI |
| `github.com/urfave/cli` | urfave CLI |

## Rules Content

Generate as `.claude/rules/stack-go.md`:

```markdown
# Go Stack Rules

## Version: Go {version}

## Modern Idioms (Go 1.21+)
- Use `max(a, b)` and `min(a, b)` builtins — not manual if/else
- Use `slices.Contains(s, v)` — not manual loops
- Use `slices.Sort(s)` — not `sort.Slice(s, func...)`
- Use `cmp.Or(a, b, c)` — not nil-check chains
- Use `maps.Keys(m)` / `maps.Values(m)` for map operations
- Use `any` — not `interface{}`  (Go 1.18+)

## Error Handling
- ALWAYS wrap errors with context: `fmt.Errorf("functionName: %w", err)`
- NEVER bare `return err` — always add context
- Use `errors.Is()` for sentinel error comparison
- Use `errors.As()` for typed error extraction
- Define sentinel errors: `var ErrNotFound = errors.New("not found")`

## Concurrency
- Always pass `context.Context` as the first parameter
- Use `errgroup.Group` for bounded goroutine management
- NEVER spawn unbounded goroutines
- Use `sync.Once` for lazy initialization
- Prefer channels for communication, mutexes for state

## gRPC Services
- Define services in `.proto` files first — implementation follows the contract
- Use interceptors (`UnaryInterceptor`, `StreamInterceptor`) for cross-cutting concerns (logging, auth, metrics, recovery) — not inline in handlers
- Always propagate `context.Context` through the full call chain — gRPC cancellation and deadlines depend on it
- Set deadlines on ALL client calls: `ctx, cancel := context.WithTimeout(ctx, 5*time.Second)`
- Use `metadata.FromIncomingContext(ctx)` for request metadata — not custom headers
- Streaming patterns:
  - **Unary:** Single request → single response (default, most common)
  - **Server streaming:** Single request → response stream (feeds, large result sets)
  - **Client streaming:** Request stream → single response (uploads, batch operations)
  - **Bidirectional:** Stream ↔ stream (real-time, chat-style interactions)
- Check `ctx.Done()` in streaming loops to prevent goroutine leaks on client disconnect

## gRPC Error Handling
- Use `status.Errorf(codes.X, "msg")` in gRPC handlers — NOT `fmt.Errorf` (gRPC clients need status codes, not wrapped errors)
- Map domain errors to gRPC status codes:
  - `codes.NotFound` — resource doesn't exist
  - `codes.InvalidArgument` — bad request data
  - `codes.PermissionDenied` — authorization failure
  - `codes.Internal` — unexpected server error
  - `codes.Unavailable` — transient failure (retry-safe)
  - `codes.DeadlineExceeded` — timeout
- Use `status.WithDetails()` for rich error information (field violations, debug info)
- In interceptors: catch panics and convert to `codes.Internal`

## Protobuf Conventions
- Messages: PascalCase (`UserProfile`, not `user_profile`)
- Fields: snake_case (`first_name`, not `firstName`)
- Enums: SCREAMING_SNAKE_CASE with type prefix (`USER_STATUS_ACTIVE`)
- Package: dot-separated with version (`service.v1`)
- NEVER reuse field numbers — use `reserved` for removed fields
- NEVER change field types — add new fields instead
- Version proto packages (`v1`, `v2`) for breaking changes

## Naming
- MixedCaps, not snake_case (Go convention)
- Exported = PascalCase, unexported = camelCase
- Interfaces: single-method = verb+er (Reader, Writer)
- Constructors: `NewFoo(...)` returns `*Foo`
- Avoid stutter: `user.User` bad, `user.Service` good

## Project Layout
- `cmd/` for entry points
- `internal/` for private packages
- `pkg/` only if explicitly sharing with other projects
- Flat package structure — avoid deep nesting

## Anti-Patterns
- No bare `return err` — always `fmt.Errorf("context: %w", err)`
- No manual loops for operations in `slices` package (Go 1.21+)
- No `interface{}` — use `any` (Go 1.18+)
- No `init()` functions — use explicit initialization
- No global mutable state — pass dependencies explicitly
- No `panic()` for expected errors — return error values
- No `fmt.Errorf` in gRPC handlers — use `status.Errorf` with proper codes
- No missing deadlines on gRPC client calls — always `context.WithTimeout`
- No blocking in streaming handlers without `ctx.Done()` checks
- No panics escaping gRPC handlers — use recovery interceptor

## Verification
After editing Go files, run: `go build ./... && go vet ./...`
```

## CLAUDE.md Section

```markdown
### Go {version}
**Build & verify:** `go build ./... && go test ./... && go vet ./...`
**Modern idioms:** Use `max/min` builtins, `slices.Contains`, `cmp.Or` (Go 1.21+)
**Error wrapping:** Always `fmt.Errorf("context: %w", err)`, never bare `return err`
**Concurrency:** `context.Context` first param, `errgroup.Group` for bounded goroutines
**gRPC:** `status.Errorf` for errors (not `fmt.Errorf`), deadlines on all client calls, interceptors for cross-cutting
```

## Settings Permissions

```json
["Bash(go build*)", "Bash(go test*)", "Bash(go vet*)", "Bash(go run*)", "Bash(go mod*)", "Bash(staticcheck*)"]
```

## Hook Verification

File extension match: `.go`
Verification command: `go vet ./...`
Fallback: `go build ./... 2>&1 | head -20`

## Test Framework Detection

Go uses the standard `testing` package. Additional tools:

| Dependency | Tool | Purpose |
|-----------|------|---------|
| `github.com/stretchr/testify` | testify | Assertions + mocking |
| `github.com/onsi/ginkgo` | Ginkgo | BDD-style tests |
| `github.com/onsi/gomega` | Gomega | Matchers |
| `github.com/golang/mock` | gomock | Interface mocking |
| `go.uber.org/mock` | uber/mock | Interface mocking (maintained fork) |
| `google.golang.org/grpc/test/bufconn` | bufconn | In-process gRPC testing |

## Known Pitfalls

1. **Obsolete idioms**: Claude trained on Go 1.16-era code. Generates manual loops instead of `slices.Contains`, `if a > b` instead of `max(a, b)`. Version-gated rules fix this.
2. **Bare error returns**: Claude often writes `return err` without context wrapping, making error chains useless.
3. **Unbounded goroutines**: Claude spawns goroutines without `errgroup` or proper lifecycle management.
4. **`interface{}` vs `any`**: Claude uses the old syntax. Rule enforcement switches to `any`.
5. **Package naming**: Claude creates deeply nested packages. Go idiom is flat packages.
6. **gRPC error wrapping confusion**: Claude uses `fmt.Errorf` wrapping in gRPC handlers instead of `status.Errorf`. The Go error wrapping rules conflict with gRPC's error model — gRPC handlers must return `status.Error` types. Wrapping a `status.Error` with `fmt.Errorf` loses the status code; the client receives `codes.Unknown` instead of the intended code.
7. **Missing gRPC deadlines**: Claude omits `context.WithTimeout` on gRPC client calls, creating calls that hang indefinitely when downstream services are unresponsive.
8. **Streaming lifecycle leaks**: Claude forgets to check `ctx.Done()` in streaming loops. When a client disconnects mid-stream, the server goroutine continues processing and sending to a dead stream until it errors out.
