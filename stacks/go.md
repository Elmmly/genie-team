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

## Known Pitfalls

1. **Obsolete idioms**: Claude trained on Go 1.16-era code. Generates manual loops instead of `slices.Contains`, `if a > b` instead of `max(a, b)`. Version-gated rules fix this.
2. **Bare error returns**: Claude often writes `return err` without context wrapping, making error chains useless.
3. **Unbounded goroutines**: Claude spawns goroutines without `errgroup` or proper lifecycle management.
4. **`interface{}` vs `any`**: Claude uses the old syntax. Rule enforcement switches to `any`.
5. **Package naming**: Claude creates deeply nested packages. Go idiom is flat packages.
