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

  // ── Agents (kinship-agent) ────────────────────────────────────────────

  /// `GET /api/agents/ally` — fetch the system ally agent.
  static const String allyAgent = '/api/agents/ally';

  // ── Chat (kinship-agent) ──────────────────────────────────────────────

  /// `POST /api/chatmessages/stream` — SSE streaming chat.
  static const String chatStream = '/api/chatmessages/stream';

  /// `GET /api/conversations/{presenceId}/{userWallet}` — conversation history.
  static String conversationHistory(String presenceId, String userWallet) =>
      '/api/conversations/$presenceId/$userWallet';

  // ── Skills (kinship-agent) ────────────────────────────────────────────

  /// `POST /api/skills` — create a new skill.
  static const String skills = '/api/skills';

  /// `DELETE /api/skills/{id}` — delete a skill.
  static String skillDelete(String skillId) => '/api/skills/$skillId';

  /// `PATCH /api/skills/{id}` — update a skill's configuration.
  static String skillUpdate(String skillId) => '/api/skills/$skillId';

  /// `PATCH /api/skills/{id}/status` — pause or resume a skill.
  static String skillStatus(String skillId) => '/api/skills/$skillId/status';

  // ── Tools (kinship-agent) ─────────────────────────────────────────────

  /// `GET /api/tools/available` — discover tools from MCP servers.
  static const String toolsAvailable = '/api/tools/available';

  // ── Agent updates (kinship-agent) ─────────────────────────────────────

  /// `PATCH /api/agents/{id}` — update agent fields (e.g. `skill_ids`).
  static String agentUpdate(String agentId) => '/api/agents/$agentId';
}