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

  // ── Agent updates (kinship-agent) ─────────────────────────────────────

  /// `PATCH /api/agents/{id}` — update agent fields.
  static String agentUpdate(String agentId) => '/api/agents/$agentId';

  // ── Prompts (kinship-agent) ────────────────────────────────────────

  /// `POST /api/prompts` — create a prompt record.
  static const String prompts = '/api/prompts';

  /// `PATCH /api/prompts/{promptId}` — update an existing prompt.
  static String promptUpdate(String promptId) => '/api/prompts/$promptId';

  // ── Knowledge (kinship-agent) ────────────────────────────────────────

  /// `GET/POST /api/knowledge` — list or create knowledge bases.
  static const String knowledge = '/api/knowledge';

  /// `GET/PATCH/DELETE /api/knowledge/{kbId}` — single KB operations.
  static String knowledgeById(String kbId) => '/api/knowledge/$kbId';

  /// `POST /api/knowledge/{kbId}/upload` — upload files to a KB.
  static String knowledgeUpload(String kbId) => '/api/knowledge/$kbId/upload';

  /// `POST /api/knowledge/{kbId}/ingest-text` — ingest raw text.
  static String knowledgeIngestText(String kbId) =>
      '/api/knowledge/$kbId/ingest-text';

  /// `DELETE /api/knowledge/{kbId}/items/{itemId}` — delete a KB item.
  static String knowledgeItem(String kbId, String itemId) =>
      '/api/knowledge/$kbId/items/$itemId';

  /// `POST /api/knowledge/{kbId}/ingest-pending` — ingest all pending items.
  static String knowledgeIngestPending(String kbId) =>
      '/api/knowledge/$kbId/ingest-pending';

  /// `POST /api/knowledge/search` — semantic search across KBs.
  static const String knowledgeSearch = '/api/knowledge/search';

  /// `POST /api/knowledge/{kbId}/gdrive-import` — import file from Drive.
  static String knowledgeGdriveImport(String kbId) =>
      '/api/knowledge/$kbId/gdrive-import';

  // ── Skills (kinship-agent) ────────────────────────────────────────────

  /// `POST /api/skills` — create a new skill.
  static const String skills = '/api/skills';

  /// `DELETE /api/skills/{id}` — delete a skill.
  static String skillDelete(String skillId) => '/api/skills/$skillId';

  /// `PATCH /api/skills/{id}` — update a skill's configuration.
  static String skillUpdate(String skillId) => '/api/skills/$skillId';

  /// `PATCH /api/skills/{id}/status` — pause or resume a skill.
  static String skillStatus(String skillId) => '/api/skills/$skillId/status';

  /// `POST /api/skills/generate-content` — AI-generate SKILL.md content.
  static const String skillGenerateContent = '/api/skills/generate-content';

  // ── Approvals ──────────────────────────────────────────────────

  /// `GET /api/approvals` — list approval requests.
  static const String approvals = '/api/approvals';

  /// `GET /api/approvals/stats` — approval statistics.
  static const String approvalStats = '/api/approvals/stats';

  /// `PATCH /api/approvals/{id}/approve` — approve an action.
  static String approvalApprove(String id) => '/api/approvals/$id/approve';

  /// `PATCH /api/approvals/{id}/reject` — reject an action.
  static String approvalReject(String id) => '/api/approvals/$id/reject';

  // ── Realms (kinship-backend) ────────────────────────────────────────────

  /// `POST /realms` — create any Realm type.
  /// `GET /realms` — list caller's Realms (with optional type/parentId/tags filters).
  static const String realms = '/realms';

  /// `GET /realms/:id` — single Realm detail + members.
  static String realmById(String id) => '/realms/$id';

  /// `GET /realms/handle-availability?handle=...` — unified handle check.
  static const String realmHandleAvailability = '/realms/handle-availability';

  /// `GET /realms/ecosystem` — genesis Ecosystem check (no auth).
  static const String realmsEcosystem = '/realms/ecosystem';

  /// `GET /realms/by-tags?tags=...` — tag-based Realm discovery.
  static const String realmsByTags = '/realms/by-tags';

  /// `GET /realms/tree/:id` — Realm + one level of children.
  static String realmTree(String id) => '/realms/tree/$id';

  /// `GET /realms/enrollments?wallet=...` — public enrollment disclosure.
  static const String realmEnrollments = '/realms/enrollments';

  // ── Tools (kinship-agent) ─────────────────────────────────────────────

  /// `GET /api/tools/available` — discover tools from MCP servers.
  static const String toolsAvailable = '/api/tools/available';

  // ── Tool connections (kinship-agent) ──────────────────────────────────

  /// `POST /api/tools/verify` — test credentials without saving.
  static const String toolsVerify = '/api/tools/verify';

  /// `POST /api/tools/save` — save verified tool to the wallet's global pool.
  static const String toolsSave = '/api/tools/save';

  /// `GET /api/tools/saved?wallet={wallet}` — list connected tool accounts.
  static String toolsSaved(String wallet) =>
      '/api/tools/saved?wallet=${Uri.encodeComponent(wallet)}';

  /// `DELETE /api/tools/saved/{id}?wallet={wallet}` — disconnect a tool.
  static String toolsRemove(String id, String wallet) =>
      '/api/tools/saved/$id?wallet=${Uri.encodeComponent(wallet)}';

  /// `GET /api/tools/saved/by-wallet?wallet={wallet}&tool_name={tool}` — get tool credentials.
  static String toolsSavedByWallet(String wallet, String toolName) =>
      '/api/tools/saved/by-wallet?wallet=${Uri.encodeComponent(wallet)}&tool_name=$toolName';

  // ── Presales (kinship-backend) ──────────────────────────────────────────

  /// `GET /tokens/presales` — list presales (public, filterable by status/symbol).
  static const String presales = '/tokens/presales';

  /// `GET /tokens/presales/{id}` — single presale details (public).
  static String presaleById(String id) => '/tokens/presales/$id';

  /// `POST /tokens/presales/{id}/buy` — purchase tokens (auth required).
  static String presaleBuy(String id) => '/tokens/presales/$id/buy';

  /// `GET /tokens/presales/{id}/purchases` — purchase history (auth required).
  static String presalePurchases(String id) =>
      '/tokens/presales/$id/purchases';
}