# totto2727/agent-sdk

Provider-neutral MoonBit interfaces for running Codex and OpenCode CLI sessions while preserving each provider's native options, events, errors, and continuation behavior.

This document is canonical `README.mbt.md`; maintain `README.md` as the relative symlink `README.md -> README.mbt.md`.

## Usage

Use the same consumer flow with either provider adapter:

```mbt check
///|
async fn run(cli : @cli.Cli, prompt : String) -> @cli.FinalResponse {
  cli.start().prompt(@cli.Prompt::Prompt(prompt))
}
```

Construct an adapter with provider-native options, then pass its `Cli` value to the shared flow:

```mbt check
///|
let codex = @codex_adapter.codex_cli(
  options=@codex.ClientOptions::ClientOptions(),
  thread_options=@codex.ThreadOptions::ThreadOptions(),
  turn_options=@codex.TurnOptions::TurnOptions(),
)

///|
let opencode = @opencode_adapter.opencode_cli(
  options=@opencode.ClientOptions::ClientOptions(),
  thread_options=@opencode.ThreadOptions::ThreadOptions(),
)
```

Pass `Prompt::Prompt(text, context_files=[...])` when a provider should receive caller-ordered workspace files. Resume a completed response with `Cli::continue_session(response.continuation.unwrap())` when it exposes a continuation.

## Key features

- One provider-neutral `Cli`, `CliSession`, `Prompt`, and `FinalResponse` contract for both adapters.

- Opaque continuations keep provider-owned resume behavior out of consumer code.

- Codex reports completed patch paths through `FinalResponse.changed_files`; OpenCode returns an empty change list because its current event model does not expose a reliable set.

- Cancelling the MoonBit task running `CliSession::prompt` cancels the provider process and propagates the cancellation error after cleanup.

- The module supports both `wasm` and `native` targets and prefers `wasm` for target-unspecified builds.

## Prerequisites

- **MoonBit**: Install the MoonBit toolchain and `moon` command.

- **Provider CLI**: Install Codex or OpenCode when using the corresponding adapter, or provide its executable through the provider SDK's native client options.

- **Wasm host**: Supply the process bridge required by the provider SDK when running the Wasm target.

## Setup

1. Add the module to your MoonBit project.

```bash
moon add totto2727/agent-sdk@0.2.0
```

2. Import the common package and the provider adapter package needed by your application.

```mbt
import {
  "totto2727/agent-sdk/cli" @cli,
  "totto2727/agent-sdk/cli/codex" @codex_adapter,
}
```

## API

The [Mooncakes API reference](https://mooncakes.io/docs/totto2727/agent-sdk) contains the maintained generated API for the common, Codex, and OpenCode packages. Public symbols also carry caller-visible behavior and checked examples in their `///` documentation.

## Development

For repository structure and development commands, see [AGENTS.md](./AGENTS.md).

## License

MIT; see [LICENSE](./LICENSE).

_This README was generated from the [share-artifact skill](https://raw.githubusercontent.com/totto2727-org/agent/refs/heads/main/plugins/totto2727-coding/skills/share-artifact/SKILL.md) and [README template](https://raw.githubusercontent.com/totto2727-org/agent/refs/heads/main/plugins/totto2727-coding/skills/share-artifact/readme/template.md)._
