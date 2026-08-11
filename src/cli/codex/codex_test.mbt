///|
priv struct FakeCodex {
  executable : @path.Path
  records : String
}

///|
async fn with_fake_codex(run : async (FakeCodex) -> Unit) -> Unit {
  let root = @fs.tmpdir(prefix="agent-sdk-codex-test-")
  let executable = @path.Path(root) |> @path.Path::join(@path.Path("codex"))
  let records = (root |> @path.Path::join(@path.Path("records"))).to_string()
  @fs.mkdir(records, recursive=true)
  @fs.write_file(
    executable.to_string(),
    fake_codex_script(),
    create_mode=CreateOrTruncate,
  )
  @fs.chmod(executable.to_string(), 0o755)
  let fixture = FakeCodex::{ executable, records }
  run(fixture) catch {
    error => {
      @async.protect_from_cancel(async fn() { @fs.rmdir(root, recursive=true) })
      raise error
    }
  }
  @fs.rmdir(root, recursive=true)
}

///|
fn FakeCodex::options(
  self : FakeCodex,
  events : Array[String],
  pause? : Bool = false,
  exit_code? : Int = 0,
) -> @sdk.CodexOptions {
  let env : Map[String, String] = {
    "PATH": "/usr/bin:/bin",
    "FAKE_CODEX_RECORD_DIR": self.records,
    "FAKE_CODEX_EXIT_CODE": exit_code.to_string(),
  }
  if pause {
    env["FAKE_CODEX_PAUSE"] = "1"
  }
  for index, event in events {
    env["FAKE_CODEX_EVENTS_\{index + 1}"] = event
  }
  @sdk.CodexOptions::CodexOptions(codex_path_override=self.executable, env~)
}

///|
async fn FakeCodex::record(
  self : FakeCodex,
  name : String,
  call : Int,
) -> String {
  @fs.read_file("\{self.records}/\{name}.\{call}").text()
}

///|
async fn wait_for_codex_file(path : String) -> Unit {
  @async.with_timeout(2000, async fn() {
    while !@fs.exists(path) {
      @async.pause()
    }
  })
}

///|
async fn codex_process_is_running(pid : Int) -> Bool {
  let (code, _, _) = @process.collect_output("kill", ["-0", pid.to_string()])
  code == 0
}

///|
fn codex_events(id : String, text : String, changed_path? : String) -> String {
  let patch = match changed_path {
    Some(path) =>
      [
        "{\"type\":\"item.completed\",\"item\":{\"id\":\"patch-1\",\"type\":\"file_change\",\"changes\":[{\"path\":\"\{path}\",\"kind\":\"update\"}],\"status\":\"completed\"}}",
      ]
    None => []
  }
  [
    "{\"type\":\"thread.started\",\"thread_id\":\"\{id}\"}",
    "{\"type\":\"turn.started\"}",
    "{\"type\":\"item.completed\",\"item\":{\"id\":\"item-1\",\"type\":\"agent_message\",\"text\":\"\{text}\"}}",
    ..patch,
    "{\"type\":\"turn.completed\",\"usage\":{\"input_tokens\":1,\"cached_input_tokens\":0,\"cache_write_input_tokens\":0,\"output_tokens\":1,\"reasoning_output_tokens\":0}}",
  ].join("\n")
}

///|
fn fake_codex_script() -> String {
  let script =
    #|#!/bin/sh
    #|set -eu
    #|record_dir="${FAKE_CODEX_RECORD_DIR:?}"
    #|counter="$record_dir/counter"
    #|call=0
    #|if [ -f "$counter" ]; then call=$(/bin/cat "$counter"); fi
    #|call=$((call + 1))
    #|printf '%s' "$call" > "$counter"
    #|printf '%s\n' "$@" > "$record_dir/args.$call"
    #|/bin/cat > "$record_dir/input.$call"
    #|printf '%s\n' "$$" > "$record_dir/pid.$call"
    #|case "$call" in
    #|  1) events="${FAKE_CODEX_EVENTS_1-}" ;;
    #|  2) events="${FAKE_CODEX_EVENTS_2-}" ;;
    #|  3) events="${FAKE_CODEX_EVENTS_3-}" ;;
    #|  *) events="${FAKE_CODEX_EVENTS-}" ;;
    #|esac
    #|if [ -n "$events" ]; then printf '%s\n' "$events"; fi
    #|if [ "${FAKE_CODEX_PAUSE-}" = "1" ]; then exec /bin/sleep 30; fi
    #|exit "${FAKE_CODEX_EXIT_CODE-0}"
    #|
  script
}

///|
async test "Codex adapter maps prompt, continuation, errors, and cancellation" {
  with_fake_codex(async fn(fixture) {
    let cli = codex_cli(
      options=fixture.options([
        codex_events("thread-1", "first", changed_path="src/changed.mbt"),
        codex_events("thread-1", "second"),
      ]),
    )
    let session = cli.start()
    assert_eq(session.id(), None)
    let first = session.prompt(
      @cli.Prompt::Prompt("hello", context_files=[
        @path.Path("docs/a.md"),
        @path.Path("src/b.mbt"),
      ]),
    )
    inspect(first.text, content="first")
    assert_eq(first.session_id, Some("thread-1"))
    assert_eq(first.changed_files.map(fn(path) { path.to_string() }), [
      "src/changed.mbt",
    ])
    assert_true(first.continuation is Some(_))
    let second = cli
      .continue_session(first.continuation.unwrap())
      .prompt(@cli.Prompt::Prompt("continue"))
    inspect(second.text, content="second")
    inspect(
      fixture.record("input", 1),
      content="hello\n\nContext files supplied by the caller:\ndocs/a.md\nsrc/b.mbt",
    )
    inspect(fixture.record("input", 2), content="continue")
    assert_true(fixture.record("args", 2).contains("resume\nthread-1"))
  })
  with_fake_codex(async fn(fixture) {
    let cli = codex_cli(
      options=fixture.options([codex_events("thread-existing", "resumed")]),
      resume_thread_id="thread-existing",
    )
    let session = cli.start()
    assert_eq(session.id(), Some("thread-existing"))
    let response = session.prompt(@cli.Prompt::Prompt("resume now"))
    assert_eq(response.session_id, Some("thread-existing"))
    assert_true(fixture.record("args", 1).contains("resume\nthread-existing"))
  })
  with_fake_codex(async fn(fixture) {
    let cli = codex_cli(options=fixture.options([], exit_code=7))
    let code = try {
      cli.start().prompt(@cli.Prompt::Prompt("fail")) |> ignore
      0
    } catch {
      @sdk.CodexSdkError::@sdk.ExecFailed(code~, ..) => code
      _ => -1
    }
    inspect(code, content="7")
  })
  with_fake_codex(async fn(fixture) {
    let cli = codex_cli(options=fixture.options([], pause=true))
    @async.with_task_group(async fn(group) {
      let task = group.spawn(
        async fn() {
          cli.start().prompt(@cli.Prompt::Prompt("cancel")) |> ignore
        },
        allow_failure=true,
      )
      let pid_path = "\{fixture.records}/pid.1"
      wait_for_codex_file(pid_path)
      let pid = @string.parse_int(
        @fs.read_file(pid_path).text().trim(),
        base=10,
      )
      assert_true(codex_process_is_running(pid))
      task.cancel()
      let cancelled = try {
        task.wait()
        false
      } catch {
        error => @async.is_cancellation_error(error)
      }
      assert_true(cancelled)
      assert_false(codex_process_is_running(pid))
    })
  })
}
