# totto2727/agent-sdk/cli/codex

A Codex-backed adapter for the provider-neutral `totto2727/agent-sdk/cli` session contract.

This document is canonical `src/cli/codex/README.mbt.md`; common session types and behavior are documented in the [CLI package README](../README.mbt.md).

## Usage

Ask Codex to summarize a repository and return the provider-neutral completed response:

```mbt check
///|
pub async fn summarize_repository() -> @cli.FinalResponse {
  codex_cli()
  .start()
  .prompt(@cli.Prompt::Prompt("Summarize the repository status"))
}
```

Pass `Prompt.context_files` to append caller-ordered paths to the Codex prompt. Completed Codex patch paths are returned in `FinalResponse.changed_files`, and a completed thread can be resumed through its opaque continuation.

## Key features

- `codex_cli` preserves Codex-native client, thread, and turn options at the adapter boundary.

- Prompt context paths are appended in caller order using the Codex SDK input format.

- Completed Codex file changes are exposed as typed `Path` values.

- Provider errors and task cancellation propagate through the common session contract after process cleanup.

## Prerequisites

- **MoonBit**: Install the MoonBit toolchain and `moon` command.

- **Codex CLI**: Install Codex or provide its executable through `ClientOptions`.

- **agent-sdk module**: Add `totto2727/agent-sdk` to the consuming MoonBit module.

## Setup

1. Add the module to your MoonBit project.

```bash
moon add totto2727/agent-sdk@0.2.0
```

2. Import `totto2727/agent-sdk/cli/codex` and construct it with optional Codex-native options.

## API

See the [Mooncakes API reference for `totto2727/agent-sdk/cli/codex`](https://mooncakes.io/docs/totto2727/agent-sdk/cli/codex) for the maintained generated API.

## Development

For repository structure and development commands, see [AGENTS.md](../../../AGENTS.md).

## License

MIT; see [LICENSE](../../../LICENSE).

_This README was generated from the [share-artifact skill](https://raw.githubusercontent.com/totto2727-org/agent/refs/heads/main/plugins/totto2727-coding/skills/share-artifact/SKILL.md) and [README template](https://raw.githubusercontent.com/totto2727-org/agent/refs/heads/main/plugins/totto2727-coding/skills/share-artifact/readme/template.md)._
