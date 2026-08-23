///|
/// Provider adapter session backed by an OpenCode SDK thread.
priv struct OpenCodeCliSession {
  client : @sdk.Client
  thread : @sdk.Thread
  thread_options : @sdk.ThreadOptions
}

///|
impl @cli.CliSession for OpenCodeCliSession with fn id(self) {
  self.thread.id()
}

///|
impl @cli.CliSession for OpenCodeCliSession with fn continuation(self) {
  self.thread
  .id()
  .map(fn(continuation_id) {
    @cli.Continuation::Continuation(fn() {
      opencode_session(self.client, self.thread_options, Some(continuation_id))
    })
  })
}

///|
impl @cli.CliSession for OpenCodeCliSession with fn prompt(self, prompt) {
  let turn = self.thread.run(opencode_input(prompt))
  let continuation = @cli.CliSession::continuation(self)
  @cli.FinalResponse::FinalResponse(
    turn.final_response,
    session_id?=self.thread.id(),
    changed_files=[],
    continuation?,
  )
}

///|
fn opencode_input(prompt : @cli.Prompt) -> @sdk.Input {
  if prompt.context_files.is_empty() {
    return @sdk.Prompt(prompt.text)
  }
  let inputs : Array[@sdk.UserInput] = [@sdk.Text(prompt.text)]
  for path in prompt.context_files {
    inputs.push(@sdk.LocalFile(path))
  }
  @sdk.UserInputs(inputs)
}

///|
fn opencode_session(
  client : @sdk.Client,
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
/// Creates an OpenCode-backed provider-neutral CLI adapter.
///
/// OpenCode-native client and thread options remain available at this package
/// boundary. Prompt context paths are forwarded as ordered local-file inputs;
/// OpenCode currently returns an empty `FinalResponse.changed_files` collection
/// because its event model does not expose a reliable change set.
///
/// ```check
/// let cli = opencode_cli()
/// let session = cli.start()
/// assert_eq(session.id(), None)
/// ```
pub fn opencode_cli(
  options? : @sdk.ClientOptions = @sdk.ClientOptions::ClientOptions(),
  thread_options? : @sdk.ThreadOptions = @sdk.ThreadOptions::ThreadOptions(),
  resume_thread_id? : String,
) -> @cli.Cli {
  let client = @sdk.Client::Client(options~)
  @cli.Cli::Cli(fn() {
    opencode_session(client, thread_options, resume_thread_id)
  })
}
