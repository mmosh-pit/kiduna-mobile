import 'package:dio/dio.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/utils/logger.dart';

/// Model for an approval request from the backend.
class ApprovalModel {
  const ApprovalModel({
    required this.id,
    required this.skillId,
    required this.skillName,
    required this.presenceId,
    required this.wallet,
    required this.status,
    required this.source,
    required this.triggerType,
    required this.summary,
    required this.proposedAction,
    this.editedAction,
    this.toolCall,
    this.triggerData,
    this.eventId,
    this.rejectReason,
    required this.createdAt,
  });

  final String id;
  final String skillId;
  final String skillName;
  final String presenceId;
  final String wallet;
  final String status;
  final String source;
  final String triggerType;
  final String summary;
  final String proposedAction;
  final String? editedAction;
  final String? toolCall;
  final Map<String, dynamic>? triggerData;
  final String? eventId;
  final String? rejectReason;
  final String createdAt;

  /// Actions that need editable draft before approving.
  static const _editableActions = {
    'replyToPost',
    'createPost',
    'sendDirectMessage',
    'google_send_email',
    'google_reply_forward_email',
    'google_draft_emails',
    'sendMessage',
  };

  /// Whether this approval needs an editable draft field.
  bool get needsEdit =>
      _editableActions.contains(toolCall) || toolCall == null;

  /// Whether this is a simple approve/reject (no editing).
  bool get isSimpleAction => !needsEdit;

  factory ApprovalModel.fromJson(Map<String, dynamic> json) {
    return ApprovalModel(
      id: (json['id'] ?? '') as String,
      skillId: (json['skillId'] ?? json['skill_id'] ?? '') as String,
      skillName: (json['skillName'] ?? json['skill_name'] ?? '') as String,
      presenceId:
          (json['presenceId'] ?? json['presence_id'] ?? '') as String,
      wallet: (json['wallet'] ?? '') as String,
      status: (json['status'] ?? 'pending') as String,
      source: (json['source'] ?? '') as String,
      triggerType:
          (json['triggerType'] ?? json['trigger_type'] ?? '') as String,
      summary: (json['summary'] ?? '') as String,
      proposedAction:
          (json['proposedAction'] ?? json['proposed_action'] ?? '') as String,
      editedAction:
          (json['editedAction'] ?? json['edited_action']) as String?,
      toolCall: (json['toolCall'] ?? json['tool_call']) as String?,
      triggerData: json['triggerData'] as Map<String, dynamic>? ??
          json['trigger_data'] as Map<String, dynamic>?,
      eventId: (json['eventId'] ?? json['event_id']) as String?,
      rejectReason:
          (json['rejectReason'] ?? json['reject_reason']) as String?,
      createdAt:
          (json['createdAt'] ?? json['created_at'] ?? '') as String,
    );
  }
}

/// API service for approval operations.
class ApprovalService {
  ApprovalService._() : _dio = ApiClient.instance.dio;

  static final ApprovalService instance = ApprovalService._();

  final Dio _dio;

  /// Fetch pending approvals for a wallet.
  Future<List<ApprovalModel>> fetchPending({required String wallet, String? realmId}) async {
    try {
      final queryParams = <String, dynamic>{
        'wallet': wallet,
        'status': 'pending',
      };
      if (realmId != null) queryParams['realmId'] = realmId;
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.approvals,
        queryParameters: queryParams,
      );

      final body = response.data;
      if (body == null) return [];

      final approvals = body['approvals'] as List<dynamic>? ?? [];
      final result = approvals
          .whereType<Map<String, dynamic>>()
          .map(ApprovalModel.fromJson)
          .toList();

      AppLogger.info(
        'Fetched ${result.length} pending approvals',
        tag: 'ApprovalService',
      );
      return result;
    } on DioException catch (e) {
      AppLogger.warning(
        'Failed to fetch approvals: ${e.message}',
        tag: 'ApprovalService',
      );
      return [];
    }
  }

  /// Approve an action, optionally with edited text.
  Future<bool> approve({
    required String approvalId,
    required String wallet,
    String? editedAction,
  }) async {
    try {
      await _dio.patch<Map<String, dynamic>>(
        ApiEndpoints.approvalApprove(approvalId),
        data: {
          'wallet': wallet,
          if (editedAction != null) 'editedAction': editedAction,
        },
        options: Options(
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 60),
        ),
      );
      AppLogger.info(
        'Approved: $approvalId',
        tag: 'ApprovalService',
      );
      return true;
    } on DioException catch (e) {
      // If timeout but request was sent, treat as success
      // (backend will execute in background).
      if (e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionTimeout) {
        AppLogger.info(
          'Approve sent (timeout waiting for execution): $approvalId',
          tag: 'ApprovalService',
        );
        return true;
      }
      AppLogger.warning(
        'Failed to approve: ${e.message}',
        tag: 'ApprovalService',
      );
      return false;
    }
  }

  /// Reject an action with optional reason.
  Future<bool> reject({
    required String approvalId,
    required String wallet,
    String? reason,
  }) async {
    try {
      await _dio.patch<Map<String, dynamic>>(
        ApiEndpoints.approvalReject(approvalId),
        data: {
          'wallet': wallet,
          if (reason != null) 'reason': reason,
        },
      );
      AppLogger.info(
        'Rejected: $approvalId',
        tag: 'ApprovalService',
      );
      return true;
    } on DioException catch (e) {
      AppLogger.warning(
        'Failed to reject: ${e.message}',
        tag: 'ApprovalService',
      );
      return false;
    }
  }
}