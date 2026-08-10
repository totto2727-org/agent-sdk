///|
/// Provider adapter session backed by a Codex SDK thread.
priv struct CodexCliSession {
  client : @sdk.Codex
  thread : @sdk.Thread
  thread_options : @sdk.ThreadOptions
  turn_options : @sdk.TurnOptions
}

///|
impl @cli.CliSession for CodexCliSession with fn continuation(self) {
  self.thread.id().map(fn(continuation_id) {
    @cli.Continuation::Continuation(fn() {
      codex_session(
        self.client,
        self.thread_options,
        self.turn_options,
        Some(continuation_id),
      )
    })
  })
}

///|
impl @cli.CliSession for CodexCliSession with fn prompt(self, prompt) {
  let turn = self.thread.run(
    @sdk.Prompt(prompt.text),
    turn_options=self.turn_options,
  )
  let continuation = @cli.CliSession::continuation(self)
  @cli.FinalResponse::FinalResponse(
    turn.final_response,
    continuation?=continuation,
  )
}

///|
fn codex_session(
  client : @sdk.Codex,
  thread_options : @sdk.ThreadOptions,
  turn_options : @sdk.TurnOptions,
  continuation_id : String?,
) -> &@cli.CliSession {
  let thread = match continuation_id {
    Some(id) => client.resume_thread(id, options=thread_options)
    None => client.start_thread(options=thread_options)
  }
  let session = CodexCliSession::{
    client,
    thread,
    thread_options,
    turn_options,
  }
  (session : &@cli.CliSession)
}

///|
/// Creates the provider-neutral CLI adapter while retaining Codex-native
/// client, thread, and turn options at this package boundary.
pub fn codex_cli(
  options? : @sdk.CodexOptions = @sdk.CodexOptions::CodexOptions(),
  thread_options? : @sdk.ThreadOptions = @sdk.ThreadOptions::ThreadOptions(),
  turn_options? : @sdk.TurnOptions = @sdk.TurnOptions::TurnOptions(),
) -> @cli.Cli {
  let client = @sdk.Codex::Codex(options~)
  @cli.Cli::Cli(fn() {
    codex_session(client, thread_options, turn_options, None)
  })
}
