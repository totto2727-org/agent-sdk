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
fn fake_cli(
  label : String,
  starts : Array[FakeSession],
  resumes : Array[Continuation],
) -> Cli {
  Cli::Cli(
    fn() {
      let session = FakeSession::{
        continuation_value: Some(Continuation::Continuation("\{label}-session")),
        response: "\{label} response",
        prompts: [],
        fail: false,
        block: false,
      }
      starts.push(session)
      (session : &CliSession)
    },
    fn(continuation) {
      resumes.push(continuation)
      let session = FakeSession::{
        continuation_value: Some(Continuation::Continuation("\{label}-next")),
        response: "\{label} continued",
        prompts: [],
        fail: false,
        block: false,
      }
      starts.push(session)
      (session : &CliSession)
    },
  )
}

///|
async test "consumer swaps providers without changing the prompt flow" {
  let prompt = Prompt::Prompt("same prompt")
  for label in ["codex", "opencode"] {
    let sessions : Array[FakeSession] = []
    let cli = fake_cli(label, sessions, [])
    let session = cli.start()
    let response = session.prompt(prompt)
    assert_eq(sessions[0].prompts, ["same prompt"])
    inspect(response.text, content="\{label} response")
    assert_eq(
      response.continuation,
      Some(Continuation::Continuation("\{label}-session")),
    )
  }
}

///|
async test "resume passes the opaque continuation unchanged" {
  let sessions : Array[FakeSession] = []
  let resumes : Array[Continuation] = []
  let cli = fake_cli("codex", sessions, resumes)
  let continuation = Continuation::Continuation("continuation-a")
  let response = cli
    .continue_session(continuation)
    .prompt(Prompt::Prompt("continue"))
  assert_eq(resumes, [Continuation::Continuation("continuation-a")])
  inspect(response.text, content="codex continued")
  assert_eq(
    response.continuation,
    Some(Continuation::Continuation("codex-next")),
  )
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
