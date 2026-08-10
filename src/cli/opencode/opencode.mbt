///|
/// Provider adapter session backed by an OpenCode SDK thread.
priv struct OpenCodeCliSession {
  client : @sdk.OpenCode
  thread : @sdk.Thread
  thread_options : @sdk.ThreadOptions
}

///|
impl @cli.CliSession for OpenCodeCliSession with fn continuation(self) {
  self.thread.id().map(fn(continuation_id) {
    @cli.Continuation::Continuation(fn() {
      opencode_session(
        self.client,
        self.thread_options,
        Some(continuation_id),
      )
    })
  })
}

///|
impl @cli.CliSession for OpenCodeCliSession with fn prompt(self, prompt) {
  let turn = self.thread.run(@sdk.Prompt(prompt.text))
  let continuation = @cli.CliSession::continuation(self)
  @cli.FinalResponse::FinalResponse(
    turn.final_response,
    continuation?=continuation,
  )
}

///|
fn opencode_session(
  client : @sdk.OpenCode,
  thread_options : @sdk.ThreadOptions,
  continuation_id : String?,
) -> &@cli.CliSession {
  let thread = match continuation_id {
    Some(id) => client.resume_thread(id, options=thread_options)
    None => client.start_thread(options=thread_options)
  }
  let session = OpenCodeCliSession::{ client, thread, thread_options }
  (session : &@cli.CliSession)
}

///|
/// Creates the provider-neutral CLI adapter while retaining OpenCode-native
/// client and thread options at this package boundary.
pub fn opencode_cli(
  options? : @sdk.OpenCodeOptions = @sdk.OpenCodeOptions::OpenCodeOptions(),
  thread_options? : @sdk.ThreadOptions = @sdk.ThreadOptions::ThreadOptions(),
) -> @cli.Cli {
  let client = @sdk.OpenCode::OpenCode(options~)
  @cli.Cli::Cli(fn() { opencode_session(client, thread_options, None) })
}
