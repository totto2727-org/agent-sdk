# totto2727/agent-sdk/cli/opencode

An OpenCode-backed adapter for the provider-neutral `totto2727/agent-sdk/cli` session contract.

Consumer acquisition, imports, and the common session flow are documented in the root [Setup](../../../README.mbt.md#setup) and [Usage](../../../README.mbt.md#usage).

## Package role

- `opencode_cli` preserves OpenCode-native client and thread options at the adapter boundary.
- Prompt context paths are forwarded as ordered local-file inputs.
- OpenCode returns an empty `FinalResponse.changed_files` collection because its current event model does not expose a reliable change set.
- Provider errors and task cancellation propagate through the common session contract after process cleanup.

## Runnable example

See the [checked OpenCode adapter flows](./opencode_test.mbt).

## API

[Mooncakes API reference for `totto2727/agent-sdk/cli/opencode`](https://mooncakes.io/docs/totto2727/agent-sdk/cli/opencode)
