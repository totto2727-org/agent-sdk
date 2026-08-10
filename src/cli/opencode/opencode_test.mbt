///|
priv struct FakeOpenCode {
  executable : @path.Path
  records : String
}

///|
async fn with_fake_opencode(run : async (FakeOpenCode) -> Unit) -> Unit {
  let root = @fs.tmpdir(prefix="agent-sdk-opencode-test-")
  let executable = @path.Path(root) |> @path.Path::join(@path.Path("opencode"))
  let records = (root |> @path.Path::join(@path.Path("records"))).to_string()
  @fs.mkdir(records, recursive=true)
  @fs.write_file(
    executable.to_string(),
    fake_opencode_script(),
    create_mode=CreateOrTruncate,
  )
  @fs.chmod(executable.to_string(), 0o755)
  let fixture = FakeOpenCode::{ executable, records }
  try {
    run(fixture)
  } catch {
    error => {
      @async.protect_from_cancel(async fn() { @fs.rmdir(root, recursive=true) })
      raise error
    }
  }
  @fs.rmdir(root, recursive=true)
}

///|
fn FakeOpenCode::options(
  self : FakeOpenCode,
  events : Array[String],
  pause? : Bool = false,
  exit_code? : Int = 0,
) -> @sdk.OpenCodeOptions {
  let env : Map[String, String] = {
    "PATH": "/usr/bin:/bin",
    "FAKE_OPENCODE_RECORD_DIR": self.records,
    "FAKE_OPENCODE_EXIT_CODE": exit_code.to_string(),
  }
  if pause {
    env["FAKE_OPENCODE_PAUSE"] = "1"
  }
  for index, event in events {
    env["FAKE_OPENCODE_EVENTS_\{index + 1}"] = event
  }
  @sdk.OpenCodeOptions::OpenCodeOptions(
    opencode_path_override=self.executable,
    env=env,
  )
}

///|
async fn FakeOpenCode::record(
  self : FakeOpenCode,
  name : String,
  call : Int,
) -> String {
  @fs.read_file("\{self.records}/\{name}.\{call}").text()
}

///|
fn opencode_events(id : String, text : String) -> String {
  [
    "{\"type\":\"step_start\",\"timestamp\":1,\"sessionID\":\"\{id}\",\"part\":{\"type\":\"step-start\"}}",
    "{\"type\":\"text\",\"timestamp\":2,\"sessionID\":\"\{id}\",\"part\":{\"type\":\"text\",\"text\":\"\{text}\"}}",
    "{\"type\":\"step_finish\",\"timestamp\":3,\"sessionID\":\"\{id}\",\"part\":{\"type\":\"step-finish\",\"reason\":\"stop\",\"cost\":0,\"tokens\":{\"total\":0,\"input\":0,\"output\":0,\"reasoning\":0,\"cache\":{\"read\":0,\"write\":0}}}}",
  ].join("\n")
}

///|
fn fake_opencode_script() -> String {
  let script = #|#!/bin/sh
  #|set -eu
  #|record_dir="${FAKE_OPENCODE_RECORD_DIR:?}"
  #|counter="$record_dir/counter"
  #|call=0
  #|if [ -f "$counter" ]; then call=$(/bin/cat "$counter"); fi
  #|call=$((call + 1))
  #|printf '%s' "$call" > "$counter"
  #|printf '%s\n' "$@" > "$record_dir/args.$call"
  #|/bin/cat > "$record_dir/input.$call"
  #|eval "events=\${FAKE_OPENCODE_EVENTS_$call-}"
  #|if [ -n "$events" ]; then printf '%s\n' "$events"; fi
  #|if [ "${FAKE_OPENCODE_PAUSE-}" = "1" ]; then /bin/sleep 30; fi
  #|exit "${FAKE_OPENCODE_EXIT_CODE-0}"
  #|
  script
}

///|
async test "OpenCode adapter maps prompt, continuation, errors, and cancellation" {
  with_fake_opencode(async fn(fixture) {
    let cli = opencode_cli(
      options=fixture.options([
        opencode_events("session-1", "first"),
        opencode_events("session-1", "second"),
      ]),
    )
    let first = cli.start().prompt(@cli.Prompt::Prompt("hello"))
    inspect(first.text, content="first")
    assert_eq(
      first.continuation,
      Some(@cli.Continuation::Continuation("session-1")),
    )
    let second = cli
      .continue_session(first.continuation.unwrap())
      .prompt(@cli.Prompt::Prompt("continue"))
    inspect(second.text, content="second")
    inspect(fixture.record("input", 1), content="hello")
    inspect(fixture.record("input", 2), content="continue")
    assert_true(fixture.record("args", 2).contains("--session\nsession-1"))
  })
  with_fake_opencode(async fn(fixture) {
    let cli = opencode_cli(options=fixture.options([], exit_code=7))
    let code = try {
      cli.start().prompt(@cli.Prompt::Prompt("fail")) |> ignore
      0
    } catch {
      @sdk.OpenCodeSdkError::@sdk.ExecFailed(code~, ..) => code
      _ => -1
    }
    inspect(code, content="7")
  })
  with_fake_opencode(async fn(fixture) {
    let cli = opencode_cli(options=fixture.options([], pause=true))
    @async.with_task_group(async fn(group) {
      let task = group.spawn(
        async fn() {
          cli.start().prompt(@cli.Prompt::Prompt("cancel")) |> ignore
        },
        allow_failure=true,
      )
      task.cancel()
      let cancelled = try {
        task.wait()
        false
      } catch {
        error => @async.is_cancellation_error(error)
      }
      assert_true(cancelled)
    })
  })
}
