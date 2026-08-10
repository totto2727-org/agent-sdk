///|
/// Text sent to a provider CLI session.
pub struct Prompt {
  text : String
} derive(Debug, Eq)

///|
/// Creates a provider-neutral prompt.
pub fn Prompt::Prompt(text : String) -> Prompt {
  { text, }
}

///|
/// Opaque provider continuation identifier.
pub struct Continuation {
  value : String
} derive(Debug, Eq)

///|
/// Creates a continuation from a provider session identifier.
pub fn Continuation::Continuation(value : String) -> Continuation {
  { value, }
}

///|
/// Final text and continuation returned by a completed prompt.
pub struct FinalResponse {
  text : String
  continuation : Continuation?
} derive(Debug, Eq)

///|
/// Creates a final response.
pub fn FinalResponse::FinalResponse(
  text : String,
  continuation? : Continuation,
) -> FinalResponse {
  { text, continuation }
}

///|
/// A live provider CLI session.
///
/// Cancelling the task running `prompt` cancels the provider call and propagates
/// the cancellation error after provider cleanup.
pub(open) trait CliSession {
  fn continuation(Self) -> Continuation?
  async fn prompt(Self, Prompt) -> FinalResponse
}

///|
/// Provider-neutral entry point for starting or resuming CLI sessions.
pub struct Cli {
  priv start_session : () -> &CliSession
  priv resume_session : (Continuation) -> &CliSession
}

///|
/// Creates a CLI adapter from provider-specific session factories.
pub fn Cli::Cli(
  start : () -> &CliSession,
  resume_session : (Continuation) -> &CliSession,
) -> Cli {
  { start_session: start, resume_session }
}

///|
/// Starts a new provider session.
pub fn Cli::start(self : Cli) -> &CliSession {
  (self.start_session)()
}

///|
/// Resumes the provider session represented by an opaque continuation.
pub fn Cli::continue_session(
  self : Cli,
  continuation : Continuation,
) -> &CliSession {
  (self.resume_session)(continuation)
}
