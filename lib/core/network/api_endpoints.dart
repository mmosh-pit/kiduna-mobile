/// Centralised API endpoint paths — never hardcode path strings at call sites.
///
/// Paths for the kinship-agent API use [agent]; paths for the auth backend
/// (kinship-backend) use [auth].
abstract class ApiEndpoints {
  const ApiEndpoints._();

  // ── Auth (kinship-backend) ────────────────────────────────────────────

  /// `POST /login` — email + password login.
  static const String login = '/login';

  /// `GET /is-auth` — verify token and refresh user data.
  static const String isAuth = '/is-auth';

  // ── Codes (kinship-agent) ─────────────────────────────────────────────

  /// `POST /api/v1/codes` — create an invitation code.
  static const String codes = '/api/v1/codes';

  // ── Skills (kinship-agent) ────────────────────────────────────────────

  /// `POST /api/skills` — create a new skill.
  static const String skills = '/api/skills';
}
