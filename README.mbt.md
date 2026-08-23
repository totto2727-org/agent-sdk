---
moonbit:
  backend: wasm
  import:
    - path: totto2727/agent-sdk@0.2.0/cli
      alias: cli
    - path: totto2727/agent-sdk@0.2.0/cli/codex
      alias: codex_adapter
---

# totto2727/agent-sdk

Provider-neutral MoonBit interfaces for running Codex and OpenCode CLI sessions while leaving each provider's native options, event models, errors, and continuation behavior in its own SDK.

## Usage

Use the provider-neutral session contract from the common [CLI package](./src/cli/README.mbt.md), then select the [Codex adapter](./src/cli/codex/README.mbt.md) or [OpenCode adapter](./src/cli/opencode/README.mbt.md).

After adding the packages described in [Setup](#setup), ask Codex to summarize a repository and return its provider-neutral response:

```mbt check
///|
pub async fn summarize_repository() -> @cli.FinalResponse {
  let response = @codex_adapter.codex_cli().start().prompt(
    @cli.Prompt::Prompt("Summarize the repository status"),
  )
  response
}
```

## Key features

- One provider-neutral `Cli`, `CliSession`, `Prompt`, and `FinalResponse` contract for both adapters.

- Opaque continuations keep provider-owned resume behavior out of consumer code.

- Codex reports completed patch paths through `FinalResponse.changed_files`; OpenCode returns an empty change list because its current event model does not expose a reliable set.

- The module supports both `wasm` and `native` targets and prefers `wasm` for target-unspecified builds.

## Prerequisites

- **MoonBit**: Install the MoonBit toolchain and `moon` command.

- **Provider CLI**: Install Codex or OpenCode when using the corresponding adapter, or provide its executable through the provider SDK's native client options.

- **Wasm host**: Supply the process bridge provided by the provider SDK stack, including its shared `agent-core` dependency, when running the Wasm target.

## Setup

1. Add the module to your MoonBit project.

```bash
moon add totto2727/agent-sdk@0.2.0
```

2. Import the common package and the provider adapter package needed by your application in `moon.pkg`.

```moonbit
import {
  "totto2727/agent-sdk/cli" @cli,
  "totto2727/agent-sdk/cli/codex" @codex_adapter,
}
```

See the package-specific usage guides for checked examples and provider-native options.

## API

The [Mooncakes module API reference](https://mooncakes.io/docs/totto2727/agent-sdk) links to the maintained generated API for the [common package](https://mooncakes.io/docs/totto2727/agent-sdk/cli), [Codex adapter](https://mooncakes.io/docs/totto2727/agent-sdk/cli/codex), and [OpenCode adapter](https://mooncakes.io/docs/totto2727/agent-sdk/cli/opencode).

## Development

For repository structure and development commands, see [AGENTS.md](./AGENTS.md).

## License

MIT; see [LICENSE](./LICENSE).

_This README was generated from the [share-artifact skill](https://raw.githubusercontent.com/totto2727-org/agent/refs/heads/main/plugins/totto2727-coding/skills/share-artifact/SKILL.md) and [README template](https://raw.githubusercontent.com/totto2727-org/agent/refs/heads/main/plugins/totto2727-coding/skills/share-artifact/readme/template.md)._
