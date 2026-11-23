name = "totto2727/agent-sdk"

version = "0.2.2"

readme = "README.mbt.md"

repository = "https://github.com/totto2727-org/agent-sdk"

license = "MIT"

keywords = [ "agent", "cli", "codex", "opencode", "sdk", "moonbit" ]

description = "Provider-neutral MoonBit interfaces for agent CLI SDKs"

preferred_target = "wasm"

supported_targets = "+wasm+native"

import {
  "moonbitlang/async@0.22.10",
  "moonbitlang/x@0.5.8",
  "totto2727/codex-sdk@0.4.2",
  "totto2727/opencode-sdk@0.4.2",
}

source = "./src"
