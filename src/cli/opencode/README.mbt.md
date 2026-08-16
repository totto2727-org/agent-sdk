# totto2727/agent-sdk/cli/opencode

An OpenCode-backed adapter for the provider-neutral `totto2727/agent-sdk/cli` session contract.

This document is canonical `src/cli/opencode/README.mbt.md`; common session types and behavior are documented in the [CLI package README](../README.mbt.md).

## Usage

Create an OpenCode adapter with OpenCode-native options, then start its provider-neutral session. Adapter construction does not start a provider process, so this checked example is deterministic:

```mbt check
///|
test "create an OpenCode adapter session" {
  let cli = opencode_cli()
  let session = cli.start()
  assert_eq(session.id(), None)
}
```

Pass `Prompt.context_files` to forward caller-ordered local-file inputs to OpenCode. OpenCode currently returns an empty `FinalResponse.changed_files` collection because its event model does not expose a reliable change set, and a completed thread can be resumed through its opaque continuation.

## Key features

- `opencode_cli` preserves OpenCode-native client and thread options at the adapter boundary.

- Prompt context paths are forwarded as ordered local-file inputs.

- Provider errors and task cancellation propagate through the common session contract after process cleanup.

## Prerequisites

- **MoonBit**: Install the MoonBit toolchain and `moon` command.

- **OpenCode CLI**: Install OpenCode or provide its executable through `ClientOptions`.

- **agent-sdk module**: Add `totto2727/agent-sdk` to the consuming MoonBit module.

## Setup

1. Add the module to your MoonBit project.

```bash
moon add totto2727/agent-sdk@0.2.0
```

2. Import `totto2727/agent-sdk/cli/opencode` and construct it with optional OpenCode-native options.

## API

See the [Mooncakes API reference for `totto2727/agent-sdk/cli/opencode`](https://mooncakes.io/docs/totto2727/agent-sdk/cli/opencode) for the maintained generated API.

## Development

For repository structure and development commands, see [AGENTS.md](../../../AGENTS.md).

## License

MIT; see [LICENSE](../../../LICENSE).

_This README was generated from the [share-artifact skill](https://raw.githubusercontent.com/totto2727-org/agent/refs/heads/main/plugins/totto2727-coding/skills/share-artifact/SKILL.md) and [README template](https://raw.githubusercontent.com/totto2727-org/agent/refs/heads/main/plugins/totto2727-coding/skills/share-artifact/readme/template.md)._
