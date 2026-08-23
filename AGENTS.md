# agent-sdk repository instructions

## Repository structure

```text
src/cli/          Provider-neutral prompt, session, continuation, and response contracts
src/cli/codex/    Codex SDK adapter and package README
src/cli/opencode/ OpenCode SDK adapter and package README
README.mbt.md     Canonical module overview and literate MoonBit document
README.md         Relative symlink to README.mbt.md
LICENSE           Module license
moon.mod          Module metadata, registry dependencies, and target support
```

The package-specific README files document only the public contract owned by their package; module-wide guidance remains here.

## Development commands

### Execution rules

- Run MoonBit commands from the module root unless a command explicitly targets a package README.

- Use the pinned MoonBit toolchain from the active Nix or direnv environment.

- Keep `README.mbt.md` as the physical module overview and preserve the root `README.md -> README.mbt.md` relative symlink.

- Keep checked examples executable and use `moon.pkg` test-only imports for dependencies needed only by tests or documentation tests.

- Do not create `CLAUDE.md`, duplicate module-wide README content in a package README, or add provider-specific imports to `src/cli`.

### Standard tasks

- `moon update` — Resolve registry dependencies recorded by `moon.mod`.

- `moon info` — Inspect module and package metadata.

- `moon fmt --check` — Verify MoonBit formatting, including literate README files.

- `moon check` — Type-check all module packages for the preferred target.

- `moon check --target native` — Type-check all module packages for the native target.

- `moon -C /tmp check "$PWD/README.mbt.md"` — Validate the root module README from an external working directory so the command cannot succeed without compiling its checked examples.

- `(cd src/cli && moon check README.mbt.md)` — Validate the common package README.

- `(cd src/cli/codex && moon check README.mbt.md)` — Validate the Codex package README.

- `(cd src/cli/opencode && moon check README.mbt.md)` — Validate the OpenCode package README.

- `moon test` — Run package tests, including provider adapter process fixtures.

- `moon test --target native` — Run package tests for the native target.

- The root README has checked provider-neutral Codex usage; its YAML front matter supplies the documentation-only imports without adding a root package or production source files.

- `(cd src/cli && moon test README.mbt.md)` — Execute the common package README examples.

- `(cd src/cli/codex && moon test README.mbt.md)` — Execute the Codex package README examples.

- `(cd src/cli/opencode && moon test README.mbt.md)` — Execute the OpenCode package README examples.

- `moon build --target wasm` and `moon build --target native` — Build all module packages for both supported targets.

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

- Keep one target-neutral source layout. The provider SDK stack owns the process bridge required by a Wasm host; `agent-sdk` only consumes that provider-facing stack.

- `moon.mod` is the publication source of truth; use registry dependencies instead of local source overlays or generated `moon.work` files.

## Development tools

- **MoonBit**: Language compiler, package manager, documentation generator, and test runner.

- **Nix and direnv**: Reproducible default toolchain environment; the CI shell adds provider CLI executables for process tests.

- **Mooncakes**: Canonical generated API documentation and registry for `totto2727/agent-sdk`.

## Package-specific rules

- Document every public symbol with `///` comments that state caller-visible behavior and include a checked example when a usage pattern is non-obvious.

- Keep provider-specific private implementation details in the adapter package that owns them; do not add provider imports to `src/cli`.

- Preserve cancellation ownership: cancelling the task that runs `CliSession::prompt` must cancel and clean up the provider process before propagating the cancellation error.

- When changing public behavior, update the corresponding `///` documentation and the package README usage summary together, then run the full module checks.

_This AGENTS.md was generated from the [share-artifact skill](https://raw.githubusercontent.com/totto2727-org/agent/refs/heads/main/plugins/totto2727-coding/skills/share-artifact/SKILL.md) and [AGENTS template](https://raw.githubusercontent.com/totto2727-org/agent/refs/heads/main/plugins/totto2727-coding/skills/share-artifact/agents/template.md)._
