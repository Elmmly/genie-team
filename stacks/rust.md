# Rust Stack Profile

Stack profile template for Rust projects. Used by `/arch:init` to generate project-specific configuration.

## Detection

| Indicator | Source |
|-----------|--------|
| `Cargo.toml` | Primary indicator |
| `Cargo.toml` → `edition` | Edition (2018, 2021, 2024) |
| `rust-toolchain.toml` | Specific toolchain version |

## Version Detection

```
grep '^edition' Cargo.toml | head -1 | sed 's/.*"\(.*\)".*/\1/'
```

## Framework Detection

| Dependency | Framework |
|-----------|-----------|
| `actix-web` | Actix Web |
| `axum` | Axum |
| `rocket` | Rocket |
| `warp` | Warp |
| `tokio` | Tokio async runtime |
| `clap` | Clap CLI |
| `tauri` | Tauri desktop |
| `bevy` | Bevy game engine |

## Rules Content

Generate as `.claude/rules/stack-rust.md`:

```markdown
# Rust Stack Rules

## Edition: Rust {edition}

## Error Handling
- Use `?` operator for error propagation — NEVER `.unwrap()` in library code
- Use `thiserror` for library error types, `anyhow` for application errors
- Add context with `.context("what failed")?` (anyhow) or `.map_err()`
- Define error enums with `#[derive(thiserror::Error)]`
- `.unwrap()` is ONLY acceptable in tests and `main()`

## Ownership & Borrowing
- Prefer references (`&T`, `&mut T`) over cloning
- NEVER use `.clone()` to "fix" borrow checker errors — restructure ownership
- Use `Cow<'_, str>` when ownership is conditional
- Prefer `&str` over `String` in function parameters
- Return owned types (`String`, `Vec<T>`) from constructors

## Type System
- Use `enum` for state machines and variants
- Implement `Display` for user-facing types
- Implement `Debug` for all types (`#[derive(Debug)]`)
- Use newtype pattern for domain types: `struct UserId(String)`
- Use `Option<T>` not sentinel values

## Async (if using tokio/async-std)
- Never block in async context — use `tokio::spawn_blocking` for sync ops
- Use `tokio::select!` for concurrent operations
- Prefer `Stream` over collecting into `Vec` for large datasets
- Use structured concurrency with `JoinSet` or `FuturesUnordered`

## Performance
- Use `&[T]` not `&Vec<T>` in function signatures
- Use iterators + `collect()` not manual loops with `push`
- Avoid allocations in hot paths — pre-allocate with `Vec::with_capacity`
- Use `#[inline]` judiciously — only for small, frequently-called functions

## Anti-Patterns
- No `.unwrap()` in library code — use `?` with proper error types
- No `.clone()` to escape borrow checker — fix the ownership model
- No `Box<dyn Any>` — use proper trait objects or enums
- No `unsafe` without a `// SAFETY:` comment justifying it
- No `String` parameters when `&str` suffices

## Verification
After editing Rust files, run: `cargo check && cargo clippy`
```

## CLAUDE.md Section

```markdown
### Rust (Edition {edition})
**Build & verify:** `cargo check && cargo test && cargo clippy`
**Error handling:** `?` operator + `thiserror`/`anyhow`, never `.unwrap()` in lib code
**Ownership:** Prefer references over `.clone()`, restructure ownership instead
**Types:** Newtypes for domain concepts, enums for state machines
```

## Settings Permissions

```json
["Bash(cargo build*)", "Bash(cargo check*)", "Bash(cargo test*)", "Bash(cargo clippy*)", "Bash(cargo run*)", "Bash(cargo fmt*)"]
```

## Hook Verification

File extension match: `.rs`
Verification command: `cargo check 2>&1 | head -30`
Fallback: `cargo clippy 2>&1 | head -30`

## Test Framework Detection

Rust uses the built-in `#[test]` attribute. Additional tools:

| Dependency | Tool | Purpose |
|-----------|------|---------|
| `proptest` | proptest | Property-based testing |
| `mockall` | mockall | Mock generation |
| `rstest` | rstest | Parameterized tests |
| `criterion` | criterion | Benchmarking |
| `insta` | insta | Snapshot testing |

## Known Pitfalls

1. **`.unwrap()` abuse**: Claude uses `.unwrap()` extensively instead of proper error propagation with `?`.
2. **`.clone()` overuse**: When the borrow checker complains, Claude adds `.clone()` instead of restructuring ownership.
3. **Missing `derive` macros**: Claude forgets `#[derive(Debug, Clone)]` on types.
4. **Blocking in async**: Claude uses synchronous I/O inside async functions without `spawn_blocking`.
5. **Over-generic code**: Claude creates overly generic functions when concrete types suffice.
