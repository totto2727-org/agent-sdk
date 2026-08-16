# agent-sdk repository instructions

## Repository structure

```text
src/cli/          Provider-neutral prompt, session, continuation, and response contracts
src/cli/codex/    Codex SDK adapter
src/cli/opencode/ OpenCode SDK adapter
README.mbt.md     Canonical user-facing README and literate MoonBit examples
README.md         Relative symlink to README.mbt.md
moon.mod          Module metadata, registry dependencies, and target support
```

## Development commands

### Execution rules

- Run MoonBit commands from the module root.

- Use the repository's pinned MoonBit toolchain through the active Nix or direnv environment.

- Keep `README.mbt.md` canonical and preserve the relative `README.md -> README.mbt.md` symlink.

- Do not add a second README, a generated API dump, or provider-specific source package under the common `src/cli` package.

### Standard tasks

- `moon update` — Resolve registry dependencies recorded by `moon.mod`.

- `moon info` — Inspect module and package metadata.

- `moon check` — Type-check all module packages for the preferred target.

- `moon check README.mbt.md` — Validate checked MoonBit examples in the canonical README.

- `moon test` — Run package tests, including provider adapter process fixtures.

- `moon build` — Build all module packages for the preferred target.

- `moon package --list` — Verify package publication contents.

## Architecture

### Common contract

- `src/cli` owns the provider-neutral `Prompt`, `Continuation`, `FinalResponse`, `CliSession`, and `Cli` contracts.

- `Prompt.context_files` preserves caller order; callers resolve relative paths before construction.

- `Continuation` remains opaque and keeps provider-owned resume behavior behind `Cli::continue_session`.

### Provider adapters

- `src/cli/codex` depends only on `totto2727/agent-sdk/cli` and `totto2727/codex-sdk/cli`.

- `src/cli/opencode` depends only on `totto2727/agent-sdk/cli` and `totto2727/opencode-sdk/cli`.

- Codex appends context paths to prompt text and reports completed patch paths; OpenCode forwards context paths as ordered local-file inputs and reports no changed files.

- Provider-native options, events, errors, permissions, and rich inputs remain in the provider SDK packages; do not duplicate them in the common contract.

### Targets and publication

- The module and all three packages declare `+wasm+native`, with `wasm` as the preferred target.

- Keep one target-neutral source layout. The selected provider SDK owns the process bridge required by a Wasm host.

- `moon.mod` is the publication source of truth; use registry dependencies instead of local source overlays or generated `moon.work` files.

## Development tools

- **MoonBit**: Language compiler, package manager, documentation generator, and test runner.

- **Nix and direnv**: Reproducible default toolchain environment; the CI shell adds provider CLI executables for process tests.

- **Mooncakes**: Canonical generated API documentation and registry for `totto2727/agent-sdk`.

## Package-specific rules

- Document every public symbol with `///` comments that state caller-visible behavior and include a checked example when a usage pattern is non-obvious.

- Keep provider-specific private implementation details in the adapter package that owns them; do not add provider imports to `src/cli`.

- Preserve cancellation ownership: cancelling the task that runs `CliSession::prompt` must cancel and clean up the provider process before propagating the cancellation error.

- When changing public behavior, update the corresponding `///` documentation and README usage summary together, then run the full module checks.

_This AGENTS.md was generated from the [share-artifact skill](https://raw.githubusercontent.com/totto2727-org/agent/refs/heads/main/plugins/totto2727-coding/skills/share-artifact/SKILL.md) and [AGENTS template](https://raw.githubusercontent.com/totto2727-org/agent/refs/heads/main/plugins/totto2727-coding/skills/share-artifact/agents/template.md)._
