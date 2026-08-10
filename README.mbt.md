# totto2727/agent-sdk

Provider-neutral MoonBit interfaces for running Codex and OpenCode CLI sessions without merging their provider-specific configuration, event, or error models.

## Packages

| Package | Responsibility |
| --- | --- |
| `totto2727/agent-sdk/cli` | Common text prompt, opaque continuation, final response, and cancellable session contract |
| `totto2727/agent-sdk/cli/codex` | Codex adapter configured with native `CodexOptions`, `ThreadOptions`, and `TurnOptions` |
| `totto2727/agent-sdk/cli/opencode` | OpenCode adapter configured with native `OpenCodeOptions` and `ThreadOptions` |

`src/server/.gitkeep` only reserves a future directory. This module contains no Server package, contract, adapter, or implementation.

## Dependency direction

```mermaid
flowchart LR
  Core[agent-core-sdk/cli] --> CodexSDK[codex-sdk/cli]
  Core --> OpenCodeSDK[opencode-sdk/cli]
  CodexSDK --> CodexAdapter[agent-sdk/cli/codex]
  OpenCodeSDK --> OpenCodeAdapter[agent-sdk/cli/opencode]
  Common[agent-sdk/cli] --> CodexAdapter
  Common --> OpenCodeAdapter
  CodexAdapter --> Consumer[CLI consumer]
  OpenCodeAdapter --> Consumer
```

`agent-sdk/cli` imports neither provider nor `agent-core-sdk`. Each adapter imports only the common package and its matching provider SDK. `agent-sdk` therefore has no direct dependency on `agent-core-sdk` and no provider-to-provider dependency.

## Processing flow

```mermaid
flowchart TD
  Configure[Choose provider-native options] --> Adapter[Create Codex or OpenCode adapter]
  Adapter --> Choice{New or continued session?}
  Choice -->|New| Start[Cli.start]
  Choice -->|Continuation| Continue[Cli.continue_session]
  Start --> Prompt[CliSession.prompt]
  Continue --> Prompt
  Prompt --> Provider[Provider SDK Thread.run]
  Provider --> Result[FinalResponse text plus opaque continuation]
  Prompt -. task cancellation .-> Cancel[Provider cleanup then cancellation propagation]
```

The common `Prompt` contains text only. A `Continuation` contains the provider session identifier but remains opaque to common consumers. Cancelling the MoonBit task that runs `CliSession::prompt` cooperatively cancels the provider call and propagates the cancellation error after provider cleanup.

Provider-specific sandbox, approval, permission, configuration, events, rich inputs, output metadata, and errors remain in `codex-sdk/cli` or `opencode-sdk/cli`. Adapter constructors accept provider-native option types, and provider errors pass through unchanged, so consumers may import the chosen provider SDK when they need those extensions.

## Usage

```mbt check
///|
async fn run(cli : @cli.Cli, prompt : String) -> @cli.FinalResponse {
  cli.start().prompt(@cli.Prompt::Prompt(prompt))
}
```

Choose an adapter without changing the consumer flow:

```mbt check
///|
let codex = @codex_adapter.codex_cli(
  options=@codex.CodexOptions::CodexOptions(),
  thread_options=@codex.ThreadOptions::ThreadOptions(),
  turn_options=@codex.TurnOptions::TurnOptions(),
)

///|
let opencode = @opencode_adapter.opencode_cli(
  options=@opencode.OpenCodeOptions::OpenCodeOptions(),
  thread_options=@opencode.ThreadOptions::ThreadOptions(),
)
```

## Development

The module retains the template's `source = "./src"` layout and currently follows the native target supported by both provider CLI packages. Dependencies are declared according to MoonBit's official [module configuration](https://docs.moonbitlang.com/en/latest/toolchain/moon/module.html) and [package configuration](https://docs.moonbitlang.com/en/latest/toolchain/moon/package.html).

Run the standard module checks from the repository root once the provider SDK versions are available in the registry:

```bash
moon update
moon info
moon check --target native
moon test --target native
moon build --target native
moon package --list
```

Before publication, validate with a `moon.work` overlay pinned to `codex-sdk` 0.2.0 commit `d38b46958f45cdc674c860239daa38ea701e389b` and `opencode-sdk` 0.3.0 commit `eeed825b5e02f6457f17089c605ec578296e0d41`.
