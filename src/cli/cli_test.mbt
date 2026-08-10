///|
suberror FakeProviderError {
  FakeProviderError(String)
} derive(Debug, Eq)

///|
struct FakeSession {
  continuation_value : Continuation?
  response : String
  prompts : Array[String]
  fail : Bool
  block : Bool
}

///|
struct FakeCodexSession {
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
impl CliSession for FakeCodexSession with fn prompt(self, prompt) {
  self.prompts.push(prompt.text)
  FinalResponse::FinalResponse(
    self.response,
    continuation?=CliSession::continuation(self),
  )
}

///|
struct FakeOpenCodeSession {
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
impl CliSession for FakeOpenCodeSession with fn prompt(self, prompt) {
  self.prompts.push(prompt.text)
  FinalResponse::FinalResponse(
    self.response,
    continuation?=CliSession::continuation(self),
  )
}

///|
impl CliSession for FakeSession with fn continuation(self) {
  self.continuation_value
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
  assert_true(response.continuation is None)
}

///|
async test "provider errors pass through unchanged" {
  let session = FakeSession::{
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
