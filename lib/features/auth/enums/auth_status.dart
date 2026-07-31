/// Authentication lifecycle states.
///
/// The app starts in [initial] while secure storage is checked, moves to
/// [loading] during a login or token-verify call, and settles on either
/// [authenticated] or [unauthenticated].
enum AuthStatus {
  /// App just launched — checking stored token.
  initial,

  /// A login or token-verify call is in flight.
  loading,

  /// User has a valid session (token + user data).
  authenticated,

  /// No valid session — show the login screen.
  unauthenticated,

  /// The last auth operation failed with an error.
  error,
}
