///|
/// Provider adapter session backed by a Codex SDK thread.
priv struct CodexCliSession {
  thread : @sdk.Thread
  turn_options : @sdk.TurnOptions
}

///|
impl @cli.CliSession for CodexCliSession with fn continuation(self) {
  self.thread.id().map(fn(value) { @cli.Continuation::Continuation(value) })
}

///|
impl @cli.CliSession for CodexCliSession with fn prompt(self, prompt) {
  let turn = self.thread.run(
    @sdk.Prompt(prompt.text),
    turn_options=self.turn_options,
  )
  @cli.FinalResponse::FinalResponse(
    turn.final_response,
    continuation?=@cli.CliSession::continuation(self),
  )
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
  @cli.Cli::Cli(
    fn() {
      let session = CodexCliSession::{
        thread: client.start_thread(options=thread_options),
        turn_options,
      }
      (session : &@cli.CliSession)
    },
    fn(continuation) {
      let session = CodexCliSession::{
        thread: client.resume_thread(
          continuation.value,
          options=thread_options,
        ),
        turn_options,
      }
      (session : &@cli.CliSession)
    },
  )
}
