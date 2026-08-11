///|
suberror FakeProviderError {
  FakeProviderError(String)
} derive(Debug, Eq)

///|
struct FakeSession {
  id_value : String?
  continuation_value : Continuation?
  response : String
  prompts : Array[String]
  fail : Bool
  block : Bool
}

///|
struct FakeCodexSession {
  id_value : String?
  prompts : Array[String]
  response : String
  continued_prompts : Array[String]
  continued_response : String?
}

///|
impl CliSession for FakeCodexSession with fn continuation(_self) {
  match _self.continued_response {
    Some(response) =>
      Some(
        Continuation::Continuation(fn() {
          let session = FakeCodexSession::{
            id_value: _self.id_value,
            prompts: _self.continued_prompts,
            response,
            continued_prompts: [],
            continued_response: None,
          }
          (session : &CliSession)
        }),
      )
    None => None
  }
}

///|
impl CliSession for FakeCodexSession with fn id(self) {
  self.id_value
}

///|
impl CliSession for FakeCodexSession with fn prompt(self, prompt) {
  self.prompts.push(prompt.text)
  FinalResponse::FinalResponse(
    self.response,
    session_id?=CliSession::id(self),
    continuation?=CliSession::continuation(self),
  )
}

///|
struct FakeOpenCodeSession {
  id_value : String?
  prompts : Array[String]
  response : String
  continued_prompts : Array[String]
  continued_response : String?
}

///|
impl CliSession for FakeOpenCodeSession with fn continuation(_self) {
  match _self.continued_response {
    Some(response) =>
      Some(
        Continuation::Continuation(fn() {
          let session = FakeOpenCodeSession::{
            id_value: _self.id_value,
            prompts: _self.continued_prompts,
            response,
            continued_prompts: [],
            continued_response: None,
          }
          (session : &CliSession)
        }),
      )
    None => None
  }
}

///|
impl CliSession for FakeOpenCodeSession with fn id(self) {
  self.id_value
}

///|
impl CliSession for FakeOpenCodeSession with fn prompt(self, prompt) {
  self.prompts.push(prompt.text)
  FinalResponse::FinalResponse(
    self.response,
    session_id?=CliSession::id(self),
    continuation?=CliSession::continuation(self),
  )
}

///|
impl CliSession for FakeSession with fn continuation(self) {
  self.continuation_value
}

///|
impl CliSession for FakeSession with fn id(self) {
  self.id_value
}

///|
impl CliSession for FakeSession with fn prompt(self, prompt) {
  self.prompts.push(prompt.text)
  if self.fail {
    raise FakeProviderError("provider failed")
  }
  if self.block {
    while true {
      @async.pause()
    }
  }
  FinalResponse::FinalResponse(
    self.response,
    session_id?=CliSession::id(self),
    continuation?=self.continuation_value,
  )
}

///|
async fn run_consumer(cli : Cli, text : String) -> FinalResponse {
  cli.start().prompt(Prompt::Prompt(text))
}

///|
async test "consumer swaps providers without changing the prompt flow" {
  let codex_prompts : Array[String] = []
  let codex_continued_prompts : Array[String] = []
  let codex = Cli::Cli(fn() {
    let session = FakeCodexSession::{
      id_value: Some("codex-thread"),
      prompts: codex_prompts,
      response: "codex response",
      continued_prompts: codex_continued_prompts,
      continued_response: Some("codex continued"),
    }
    (session : &CliSession)
  })
  let opencode_prompts : Array[String] = []
  let opencode_continued_prompts : Array[String] = []
  let opencode = Cli::Cli(fn() {
    let session = FakeOpenCodeSession::{
      id_value: Some("opencode-session"),
      prompts: opencode_prompts,
      response: "opencode response",
      continued_prompts: opencode_continued_prompts,
      continued_response: Some("opencode continued"),
    }
    (session : &CliSession)
  })
  let codex_response = run_consumer(codex, "same prompt")
  let opencode_response = run_consumer(opencode, "same prompt")
  assert_eq(codex_prompts, ["same prompt"])
  assert_eq(opencode_prompts, ["same prompt"])
  inspect(codex_response.text, content="codex response")
  inspect(opencode_response.text, content="opencode response")
  assert_eq(codex_response.session_id, Some("codex-thread"))
  assert_eq(opencode_response.session_id, Some("opencode-session"))
  assert_eq(codex_response.changed_files, [])
  assert_eq(opencode_response.changed_files, [])
  let codex_continued = codex
    .continue_session(codex_response.continuation.unwrap())
    .prompt(Prompt::Prompt("codex next"))
  let opencode_continued = opencode
    .continue_session(opencode_response.continuation.unwrap())
    .prompt(Prompt::Prompt("opencode next"))
  inspect(codex_continued.text, content="codex continued")
  inspect(opencode_continued.text, content="opencode continued")
  assert_eq(codex_continued_prompts, ["codex next"])
  assert_eq(opencode_continued_prompts, ["opencode next"])
}

///|
async test "resume passes the opaque continuation unchanged" {
  let resumed : Array[String] = []
  let resumed_session = FakeSession::{
    id_value: Some("continuation-a"),
    continuation_value: None,
    response: "continued",
    prompts: [],
    fail: false,
    block: false,
  }
  let continuation = Continuation::Continuation(fn() {
    resumed.push("continuation-a")
    (resumed_session : &CliSession)
  })
  let cli = Cli::Cli(fn() { abort("start is not used") })
  let response = cli
    .continue_session(continuation)
    .prompt(Prompt::Prompt("continue"))
  assert_eq(resumed, ["continuation-a"])
  inspect(response.text, content="continued")
  assert_eq(response.session_id, Some("continuation-a"))
  assert_true(response.continuation is None)
}

///|
async test "provider errors pass through unchanged" {
  let session = FakeSession::{
    id_value: None,
    continuation_value: None,
    response: "",
    prompts: [],
    fail: true,
    block: false,
  }
  let message = try {
    CliSession::prompt(session, Prompt::Prompt("fail")) |> ignore
    "no error"
  } catch {
    FakeProviderError(message) => message
    error => "unexpected: \{error}"
  }
  inspect(message, content="provider failed")
}

///|
async test "cancelling an in-flight prompt propagates cancellation" {
  let session = FakeSession::{
    id_value: None,
    continuation_value: None,
    response: "unreachable",
    prompts: [],
    fail: false,
    block: true,
  }
  @async.with_task_group(async fn(group) {
    let task = group.spawn(
      async fn() {
        CliSession::prompt(session, Prompt::Prompt("block")) |> ignore
      },
      allow_failure=true,
    )
    while session.prompts.is_empty() {
      @async.pause()
    }
    task.cancel()
    let cancelled = try {
      task.wait()
      false
    } catch {
      error => @async.is_cancellation_error(error)
    }
    assert_true(cancelled)
  })
}

///|
test "prompt keeps optional context files without changing text-only callers" {
  let text_only = Prompt::Prompt("translate")
  inspect(text_only.text, content="translate")
  assert_eq(text_only.context_files, [])
  let with_context = Prompt::Prompt("review", context_files=[
    @path.Path("src/a.mbt"),
    @path.Path("docs/b.md"),
  ])
  inspect(with_context.text, content="review")
  assert_eq(with_context.context_files.map(fn(path) { path.to_string() }), [
    "src/a.mbt", "docs/b.md",
  ])
}
