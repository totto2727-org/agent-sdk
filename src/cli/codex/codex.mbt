///|
/// Provider adapter session backed by a Codex SDK thread.
priv struct CodexCliSession {
  client : @sdk.Client
  thread : @sdk.Thread
  thread_options : @sdk.ThreadOptions
  turn_options : @sdk.TurnOptions
}

///|
impl @cli.CliSession for CodexCliSession with fn id(self) {
  self.thread.id()
}

///|
impl @cli.CliSession for CodexCliSession with fn continuation(self) {
  self.thread
  .id()
  .map(fn(continuation_id) {
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
    codex_input(prompt),
    turn_options=self.turn_options,
  )
  let continuation = @cli.CliSession::continuation(self)
  @cli.FinalResponse::FinalResponse(
    turn.final_response,
    session_id?=self.thread.id(),
    changed_files=codex_changed_files(turn.items),
    continuation?,
  )
}

///|
fn codex_input(prompt : @cli.Prompt) -> @sdk.Input {
  if prompt.context_files.is_empty() {
    return @sdk.Prompt(prompt.text)
  }
  let files = prompt.context_files
    .iter()
    .map(path => path.to_string())
    .join("\n")
  @sdk.Prompt(
    "\{prompt.text}\n\nContext files supplied by the caller:\n\{files}",
  )
}

///|
fn codex_changed_files(
  items : ReadOnlyArray[@sdk.ThreadItem],
) -> ReadOnlyArray[@path.Path] {
  let files : Array[@path.Path] = []
  for item in items {
    match item {
      @sdk.FileChange(change) =>
        match change.status {
          @sdk.PatchCompleted =>
            for update in change.changes {
              files.push(update.path)
            }
          _ => ()
        }
      _ => ()
    }
  }
  ReadOnlyArray::from_array(files)
}

///|
fn codex_session(
  client : @sdk.Client,
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
/// Creates a Codex-backed provider-neutral CLI adapter.
///
/// Codex-native client, thread, and turn options remain available at this
/// package boundary. Prompt context paths are appended to the prompt text in
/// caller order, and completed Codex patch paths are returned in
/// `FinalResponse.changed_files`.
///
/// ```check
/// let cli = codex_cli()
/// let session = cli.start()
/// assert_eq(session.id(), None)
/// ```
pub fn codex_cli(
  options? : @sdk.ClientOptions = @sdk.ClientOptions::ClientOptions(),
  thread_options? : @sdk.ThreadOptions = @sdk.ThreadOptions::ThreadOptions(),
  turn_options? : @sdk.TurnOptions = @sdk.TurnOptions::TurnOptions(),
  resume_thread_id? : String,
) -> @cli.Cli {
  let client = @sdk.Client::Client(options~)
  @cli.Cli::Cli(fn() {
    codex_session(client, thread_options, turn_options, resume_thread_id)
  })
}
