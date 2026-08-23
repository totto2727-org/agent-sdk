# totto2727/agent-sdk/cli/codex

A Codex-backed adapter for the provider-neutral `totto2727/agent-sdk/cli` session contract.

Consumer acquisition, imports, and the common session flow are documented in the root [Setup](../../../README.mbt.md#setup) and [Usage](../../../README.mbt.md#usage).

## Package role

- `codex_cli` preserves Codex-native client, thread, and turn options at the adapter boundary.
- Prompt context paths are appended in caller order using the Codex SDK input format.
- Completed Codex file changes are exposed as typed `Path` values.
- Provider errors and task cancellation propagate through the common session contract after process cleanup.

## Usage

See the [checked Codex adapter flows](./codex_test.mbt).

## API

[Mooncakes API reference for `totto2727/agent-sdk/cli/codex`](https://mooncakes.io/docs/totto2727/agent-sdk/cli/codex)

_This README was generated from the [share-artifact skill](https://raw.githubusercontent.com/totto2727-org/agent/refs/heads/main/plugins/totto2727-coding/skills/share-artifact/SKILL.md) and [README template](https://raw.githubusercontent.com/totto2727-org/agent/refs/heads/main/plugins/totto2727-coding/skills/share-artifact/readme/template.md)._
