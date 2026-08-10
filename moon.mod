name = "totto2727/agent-sdk"

version = "0.1.0"

readme = "README.mbt.md"

repository = "https://github.com/totto2727-org/agent-sdk"

license = "MIT"

keywords = [ "agent", "cli", "codex", "opencode", "sdk", "moonbit" ]

description = "Provider-neutral MoonBit interfaces for agent CLI SDKs"

// Leave both settings unset for synchronous, backend-neutral libraries.
//
// For async libraries, uncomment supported_targets and exactly one
// preferred_target. Choose the first viable preferred target in this order:
// wasm, js, native. If a dependency supports fewer targets, narrow both
// settings to match that dependency.
//
supported_targets = "native"
// preferred_target = "wasm"
// preferred_target = "js"
preferred_target = "native"

import {
  "moonbitlang/async@0.20.3",
  "moonbitlang/x@0.4.47",
  "totto2727/codex-sdk@0.2.0",
  "totto2727/opencode-sdk@0.3.0",
}

source = "./src"
