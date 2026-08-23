///|
/// Text and optional context files sent to a provider CLI session.
///
/// The `context_files` collection preserves caller order. Codex adapters append
/// the paths to the prompt text, while OpenCode adapters forward them as
/// ordered local-file inputs. Callers should resolve relative paths against
/// their workspace before constructing a prompt.
pub struct Prompt {
  text : String
  context_files : ReadOnlyArray[@path.Path]
} derive(Debug, Eq)

///|
/// Creates a provider-neutral prompt without changing text-only callers.
///
/// ```check
/// let prompt = Prompt::Prompt("review", context_files=[
///   @path.Path("src/main.mbt"),
/// ])
/// assert_eq(prompt.text, "review")
/// assert_eq(prompt.context_files.length(), 1)
/// ```
pub fn Prompt::Prompt(
  text : String,
  context_files? : ReadOnlyArray[@path.Path] = [],
) -> Prompt {
  { text, context_files }
}

///|
/// Opaque provider continuation handle.
///
/// A continuation captures provider-owned resume behavior. Pass it to
/// `Cli::continue_session`; callers do not inspect or construct its identifier.
pub struct Continuation {
  priv resume_session : () -> &CliSession
}

///|
/// Creates an opaque continuation handle from provider-owned resume behavior.
pub fn Continuation::Continuation(
  resume_session : () -> &CliSession,
) -> Continuation {
  { resume_session, }
}

///|
/// Final text, session metadata, changed files, and continuation returned by a
/// completed prompt.
///
/// `session_id` is populated when the provider exposes its thread identifier.
/// `changed_files` contains completed Codex patch paths and is empty for the
/// OpenCode adapter because its current event model has no reliable change set.
pub struct FinalResponse {
  text : String
  session_id : String?
  changed_files : ReadOnlyArray[@path.Path]
  continuation : Continuation?
}

///|
/// Creates a final response with optional provider metadata.
///
/// ```check
/// let response = FinalResponse::FinalResponse(
///   "done",
///   session_id="session-1",
/// )
/// assert_eq(response.text, "done")
/// assert_eq(response.session_id, Some("session-1"))
/// ```
pub fn FinalResponse::FinalResponse(
  text : String,
  session_id? : String,
  changed_files? : ReadOnlyArray[@path.Path] = [],
  continuation? : Continuation,
) -> FinalResponse {
  { text, session_id, changed_files, continuation }
}

///|
/// A live provider CLI session.
///
/// `id` exposes the provider thread or session identifier when available, and
/// `continuation` returns an opaque handle after a provider has completed a
/// prompt. Provider errors pass through unchanged.
///
/// Cancelling the task running `prompt` cancels the provider call and propagates
/// the cancellation error after provider cleanup.
pub(open) trait CliSession {
  /// Returns the provider thread or session identifier when available.
  fn id(Self) -> String?
  /// Returns an opaque handle for resuming this provider session when available.
  fn continuation(Self) -> Continuation?
  /// Sends a prompt and returns the provider's completed final response.
  async fn prompt(Self, Prompt) -> FinalResponse
}

///|
/// Provider-neutral entry point for starting or resuming CLI sessions.
///
/// Use `start` for a fresh provider session or `continue_session` with the
/// continuation from a previous `FinalResponse`.
pub struct Cli {
  priv start_session : () -> &CliSession
}

///|
/// Creates a CLI adapter from provider-specific session factories.
///
/// The factory is called when `start` is invoked, so provider-native options
/// remain owned by the selected adapter.
pub fn Cli::Cli(start : () -> &CliSession) -> Cli {
  { start_session: start }
}

///|
/// Starts a new provider session using the adapter's provider-native options.
pub fn Cli::start(self : Cli) -> &CliSession {
  (self.start_session)()
}

///|
/// Resumes the provider session represented by an opaque continuation.
///
/// The continuation remains opaque and is consumed only by the selected
/// provider adapter.
pub fn Cli::continue_session(
  _self : Cli,
  continuation : Continuation,
) -> &CliSession {
  (continuation.resume_session)()
}
