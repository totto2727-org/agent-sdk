# totto2727/agent-sdk/cli

Provider-neutral MoonBit interfaces for prompts, live CLI sessions, opaque continuations, and completed responses.

Consumer acquisition, imports, and the common session flow are documented in the root [Setup](../../README.mbt.md#setup) and [Usage](../../README.mbt.md#usage).

## Package role

- `Prompt` carries caller-ordered context paths without changing text-only callers.
- `Cli` and `CliSession` provide one flow for starting, prompting, and resuming provider adapters.
- `Continuation` hides provider-owned resume identifiers and behavior from consumers.
- `FinalResponse` exposes final text, optional session metadata, changed paths, and an optional continuation.
- Cancelling the task running `CliSession::prompt` propagates the cancellation error after provider cleanup.

## Usage

See the [checked common session consumer flow](./cli_test.mbt).

## API

[Mooncakes API reference for `totto2727/agent-sdk/cli`](https://mooncakes.io/docs/totto2727/agent-sdk/cli)

_This README was generated from the [share-artifact skill](https://raw.githubusercontent.com/totto2727-org/agent/refs/heads/main/plugins/totto2727-coding/skills/share-artifact/SKILL.md) and [README template](https://raw.githubusercontent.com/totto2727-org/agent/refs/heads/main/plugins/totto2727-coding/skills/share-artifact/readme/template.md)._
