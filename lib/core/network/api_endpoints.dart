abstract class ApiEndpoints {
  const ApiEndpoints._();

  // ── Auth (kinship-backend, uses authDio) ─────────────────────────────

  static const String login = '/login';
  static const String isAuth = '/is-auth';

  // ── Visitor flow (kinship-backend, uses authDio) ─────────────────────

  static const String generateOtp = '/visitors/generate-otp';
  static const String verifyOtp = '/visitors/verify-otp';
  static const String resendOtp = '/visitors/resend-otp';
  static const String saveEarlyAccess = '/visitors/save-early-access';
  static const String upsertEarlyAccess = '/visitors/upsert-early-access';
  static const String hasCodeExist = '/visitors/has-code-exist';

  // ── Agents (kinship-agent, uses dio) ─────────────────────────────────

  static const String allyAgent = '/api/agents/ally';

  // ── Chat (kinship-agent, uses dio) ───────────────────────────────────

  static const String chatStream = '/api/chatmessages/stream';

  static String conversationHistory(String presenceId, String userWallet) =>
      '/api/conversations/$presenceId/$userWallet';

  // ── Prompts (kinship-agent, uses dio) ────────────────────────────────

  static const String prompts = '/api/prompts';

  static String promptUpdate(String promptId) => '/api/prompts/$promptId';

  // ── Agent CRUD (kinship-agent, uses dio) ─────────────────────────────

  static String agentUpdate(String agentId) => '/api/agents/$agentId';
}
