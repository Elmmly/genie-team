# Code Quality Standards

## General Principles

- No hardcoded values — use config/registry
- Type hints on public methods
- Docstrings for public functions
- Consistent naming conventions
- Error handling at boundaries

## Error Handling

- Log errors with context
- Propagate meaningful exceptions
- Don't swallow errors silently
- Fail fast on invalid state
- Provide actionable error messages

## Pattern Adherence

Follow project patterns strictly:
- Structural patterns (registry, factory, strategy)
- Data patterns (repository, DTO, entity)
- Integration patterns (adapter, gateway)

**When uncertain:** Ask, don't assume.

## Instrumentation

Add observability:
- Structured logging at boundaries
- Metrics for key operations
- JSON-serializable log payloads

**Logging levels:**
- DEBUG: Detailed flow information
- INFO: Key events and state changes
- WARNING: Recoverable issues
- ERROR: Failures requiring attention

## Security Considerations

- No sensitive data exposure
- Input validation at boundaries
- Authentication/authorization checks
- No injection vulnerabilities
- Secure defaults
