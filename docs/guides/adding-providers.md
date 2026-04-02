# Adding a New AI Provider

This guide covers how to add a new LLM provider to genie-team. The multi-provider architecture (ADR-007) supports two tiers:

- **Tier 1:** Wrap an embeddable agent SDK (like Claude Agent SDK). Full fidelity.
- **Tier 2:** Wrap an LLM API SDK with the self-managed agent loop. Reduced fidelity but works with any provider that has tool/function calling.

Most new providers will be Tier 2. This guide covers that path.

## What you'll create

1. A provider client (`src/providers/<name>-client.ts`) implementing `LLMClient`
2. Tests (`src/providers/<name>-client.test.ts`)
3. A case in the CLI executor factory (`src/cli.ts`)

That's it — the `LLMApiExecutor` handles the agent loop, and `LocalToolExecutor` handles tool execution. Your job is the mapping between our unified types and the provider's SDK types.

## Step 1: Implement LLMClient

Create `src/providers/<name>-client.ts`:

```typescript
import type {
  LLMClient,
  Message,
  CompletionOptions,
  CompletionResponse,
  ToolCall,
} from "../core/llm-types.js";

export class MyProviderLLMClient implements LLMClient {
  readonly name = "my-provider";

  constructor(private readonly apiKey: string) {
    // Initialize provider SDK
  }

  async complete(
    messages: Message[],
    options: CompletionOptions,
  ): Promise<CompletionResponse> {
    // 1. Convert our Message[] to provider's message format
    // 2. Convert our Tool[] to provider's tool format
    // 3. Call the provider's API
    // 4. Convert the response back to our CompletionResponse
  }
}
```

### What you need to map

| Our type | What to map to | Notes |
|----------|---------------|-------|
| `Message.role` | Provider's role format | Most use "user"/"assistant"/"system" |
| `Message.toolCalls` | Provider's tool call format | How assistant requests tool use |
| `Message.toolResult` | Provider's tool result format | How tool results are sent back |
| `Tool.inputSchema` | Provider's function/tool schema | Usually JSON Schema, field names differ |
| `CompletionResponse.toolCalls` | Parse from provider response | Extract tool call ID, name, input |
| `CompletionResponse.usage` | Map token count fields | Field names vary |

### Provider-specific gotchas

**OpenAI:** Tool call arguments are a JSON string (not an object). Parse with `JSON.parse(tc.function.arguments)`.

**Google:** Function calls may lack IDs. Generate them: `fc_${counter}_${Date.now()}`. Tool results match by name, not ID.

**Anthropic:** Tool results are sent as user messages with `tool_result` content blocks, not a separate "tool" role. Assistant messages mix text and tool_use blocks in the same content array.

## Step 2: Write tests

Create `src/providers/<name>-client.test.ts`. Mock the provider SDK and test:

1. Basic completion (text response, no tools)
2. Tool definitions are mapped correctly
3. Tool calls in the response are parsed correctly
4. Tool result messages are formatted correctly
5. System prompt is passed correctly
6. Token usage is mapped correctly

See `src/providers/openai-client.test.ts` for the pattern.

## Step 3: Wire into CLI

In `src/cli.ts`, add a case to `createExecutor()`:

```typescript
case "my-provider": {
  const apiKey = process.env.MY_PROVIDER_API_KEY;
  if (!apiKey) {
    throw new Error("--provider my-provider requires MY_PROVIDER_API_KEY environment variable");
  }
  const client = new MyProviderLLMClient(apiKey);
  const tools = new LocalToolExecutor(process.cwd());
  return new LLMApiExecutor(client, tools);
}
```

Update the `--provider` help text and the error message for unknown providers.

## Step 4: Update genie-config.yaml support

Users can set your provider as default in their config:

```yaml
provider: my-provider
tiers:
  default:
    model: my-model-name
    description: Standard delivery
```

No code changes needed — the config system passes the provider string to `createExecutor()`.

## Testing

```bash
# Unit tests (mocked)
npx vitest run src/providers/<name>-client.test.ts

# Live test (requires API key)
export MY_PROVIDER_API_KEY=...
genies-core run --provider my-provider --model <model-name> \
  --from discover --through discover --skip-permissions --verbose \
  "what patterns exist in this repo?"
```

## Reference

- `src/core/llm-types.ts` — LLMClient interface, unified types
- `src/core/llm-api-executor.ts` — Self-managed agent loop
- `src/core/tool-executor.ts` — LocalToolExecutor (Read/Write/Edit/Bash/Glob/Grep)
- `src/providers/openai-client.ts` — OpenAI reference implementation (~120 lines)
- `src/providers/google-client.ts` — Google reference implementation (~150 lines)
- `src/providers/anthropic-client.ts` — Anthropic reference implementation (~130 lines)
- `docs/decisions/ADR-007-multi-provider-phase-execution.md` — Architecture decision
