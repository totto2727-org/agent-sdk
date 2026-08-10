///|
/// Provider adapter session backed by an OpenCode SDK thread.
priv struct OpenCodeCliSession {
  thread : @sdk.Thread
}

///|
impl @cli.CliSession for OpenCodeCliSession with fn continuation(self) {
  self.thread.id().map(fn(value) { @cli.Continuation::Continuation(value) })
}

///|
impl @cli.CliSession for OpenCodeCliSession with fn prompt(self, prompt) {
  let turn = self.thread.run(@sdk.Prompt(prompt.text))
  @cli.FinalResponse::FinalResponse(
    turn.final_response,
    continuation?=@cli.CliSession::continuation(self),
  )
}

///|
/// Creates the provider-neutral CLI adapter while retaining OpenCode-native
/// client and thread options at this package boundary.
pub fn opencode_cli(
  options? : @sdk.OpenCodeOptions = @sdk.OpenCodeOptions::OpenCodeOptions(),
  thread_options? : @sdk.ThreadOptions = @sdk.ThreadOptions::ThreadOptions(),
) -> @cli.Cli {
  let client = @sdk.OpenCode::OpenCode(options~)
  @cli.Cli::Cli(
    fn() {
      let session = OpenCodeCliSession::{
        thread: client.start_thread(options=thread_options),
      }
      (session : &@cli.CliSession)
    },
    fn(continuation) {
      let session = OpenCodeCliSession::{
        thread: client.resume_thread(
          continuation.value,
          options=thread_options,
        ),
      }
      (session : &@cli.CliSession)
    },
  )
}
