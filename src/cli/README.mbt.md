# totto2727/agent-sdk/cli

Provider-neutral MoonBit interfaces for prompts, live CLI sessions, opaque continuations, and completed responses.

This document is canonical `src/cli/README.mbt.md`; it documents only the common contract. Provider-native behavior belongs to the [Codex adapter](./codex/README.mbt.md) and [OpenCode adapter](./opencode/README.mbt.md).

## Usage

Construct a prompt and pass it to the provider-neutral session flow. This checked example uses the public prompt contract without starting a provider process:

```mbt check
///|
test "construct a prompt for a provider session" {
  let prompt = Prompt::Prompt("Summarize the repository", context_files=[])
  assert_eq(prompt.text, "Summarize the repository")
}
```

Use `Cli::start` for a fresh session and `Cli::continue_session` with the opaque continuation returned by a completed response.

## Key features

- `Prompt` carries caller-ordered context paths without changing text-only callers.

- `Cli` and `CliSession` provide one flow for starting, prompting, and resuming provider adapters.

- `Continuation` hides provider-owned resume identifiers and behavior from consumers.

- `FinalResponse` exposes final text, optional session metadata, changed paths, and an optional continuation.

- Cancelling the task running `CliSession::prompt` propagates the cancellation error after provider cleanup.

## Prerequisites

- **MoonBit**: Install the MoonBit toolchain and `moon` command.

- **agent-sdk module**: Add `totto2727/agent-sdk` to the consuming MoonBit module.

## Setup

1. Add the module to your MoonBit project.

```bash
moon add totto2727/agent-sdk@0.2.0
```

2. Import `totto2727/agent-sdk/cli` in the package that owns your session flow.

## API

See the [Mooncakes API reference for `totto2727/agent-sdk/cli`](https://mooncakes.io/docs/totto2727/agent-sdk/cli) for the maintained generated API.

## Development

For repository structure and development commands, see [AGENTS.md](../../AGENTS.md).

## License

MIT; see [LICENSE](../../LICENSE).

_This README was generated from the [share-artifact skill](https://raw.githubusercontent.com/totto2727-org/agent/refs/heads/main/plugins/totto2727-coding/skills/share-artifact/SKILL.md) and [README template](https://raw.githubusercontent.com/totto2727-org/agent/refs/heads/main/plugins/totto2727-coding/skills/share-artifact/readme/template.md)._
