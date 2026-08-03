import 'package:dio/dio.dart';

import '../../core/errors/exceptions.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/utils/logger.dart';
import '../models/knowledge_base_model.dart';

/// Handles knowledge base CRUD, file upload, Drive import, and agent linkage.
///
/// Returns parsed data or throws typed exceptions — no business logic.
class KnowledgeService {
  KnowledgeService._();

  static final KnowledgeService instance = KnowledgeService._();

  Dio get _dio => ApiClient.instance.dio;

  /// Fetch all knowledge bases for a wallet.
  Future<List<KnowledgeBaseModel>> fetchKnowledgeBases({
    required String wallet,
    String? platformId,
  }) async {
    try {
      final queryParams = <String, dynamic>{'wallet': wallet};
      if (platformId != null) {
        queryParams['platform_id'] = platformId;
      }

      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.knowledge,
        queryParameters: queryParams,
      );

      final body = response.data ?? {};
      final kbList = body['knowledgeBases'] as List<dynamic>? ?? [];
      final result = kbList
          .map((e) => KnowledgeBaseModel.fromJson(e as Map<String, dynamic>))
          .toList();

      AppLogger.info(
        'Loaded ${result.length} knowledge bases',
        tag: 'KnowledgeService',
      );
      return result;
    } on DioException catch (e) {
      _rethrowOrWrap(e, 'fetchKnowledgeBases');
    }
  }

  /// Fetch a single knowledge base with items and stats.
  Future<KnowledgeBaseModel> fetchKnowledgeBase(String kbId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.knowledgeById(kbId),
      );

      final body = response.data;
      if (body == null) {
        throw const ServerException('Empty knowledge base response');
      }

      return KnowledgeBaseModel.fromJson(body);
    } on DioException catch (e) {
      _rethrowOrWrap(e, 'fetchKnowledgeBase');
    }
  }

  /// Create a new knowledge base.
  ///
  /// This is a POST — never retry on failure.
  Future<KnowledgeBaseModel> createKnowledgeBase({
    required String name,
    required String wallet,
    String? platformId,
    String privacy = 'private',
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.knowledge,
        data: {
          'name': name,
          'wallet': wallet,
          if (platformId != null) 'platform_id': platformId,
          'privacy': privacy,
        },
      );

      final body = response.data;
      if (body == null) {
        throw const ServerException('Empty create response');
      }

      final kb = KnowledgeBaseModel.fromJson(body);
      AppLogger.info('Created KB: ${kb.id}', tag: 'KnowledgeService');
      return kb;
    } on DioException catch (e) {
      _rethrowOrWrap(e, 'createKnowledgeBase');
    }
  }

  /// Update knowledge base metadata (name, privacy).
  Future<KnowledgeBaseModel> updateKnowledgeBase(
    String kbId, {
    String? name,
    String? privacy,
  }) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        ApiEndpoints.knowledgeById(kbId),
        data: {
          if (name != null) 'name': name,
          if (privacy != null) 'privacy': privacy,
        },
      );

      final body = response.data;
      if (body == null) {
        throw const ServerException('Empty update response');
      }

      return KnowledgeBaseModel.fromJson(body);
    } on DioException catch (e) {
      _rethrowOrWrap(e, 'updateKnowledgeBase');
    }
  }

  /// Delete a knowledge base and all its items.
  ///
  /// Backend returns 204 No Content on success.
  Future<void> deleteKnowledgeBase(String kbId) async {
    try {
      await _dio.delete<void>(ApiEndpoints.knowledgeById(kbId));
      AppLogger.info('Deleted KB: $kbId', tag: 'KnowledgeService');
    } on DioException catch (e) {
      _rethrowOrWrap(e, 'deleteKnowledgeBase');
    }
  }

  /// Upload files to a knowledge base.
  ///
  /// Accepts file bytes + name pairs for cross-platform compatibility
  /// (web has no file path access). This is a POST — never retry on failure.
  /// Upload files to a knowledge base.
  ///
  /// The backend returns `{"files": [...]}` with ingest status per file —
  /// NOT a full KB model. The caller should refresh the KB after upload.
  /// This is a POST — never retry on failure.
  Future<void> uploadFiles(
    String kbId,
    List<({String name, List<int> bytes})> files,
  ) async {
    try {
      final formData = FormData();
      for (final file in files) {
        formData.files.add(
          MapEntry(
            'files',
            MultipartFile.fromBytes(file.bytes, filename: file.name),
          ),
        );
      }

      await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.knowledgeUpload(kbId),
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      AppLogger.info(
        'Uploaded ${files.length} files to KB $kbId',
        tag: 'KnowledgeService',
      );
    } on DioException catch (e) {
      _rethrowOrWrap(e, 'uploadFiles');
    }
  }

  /// Delete a single item from a knowledge base.
  Future<void> deleteItem(String kbId, String itemId) async {
    try {
      await _dio.delete<dynamic>(ApiEndpoints.knowledgeItem(kbId, itemId));
      AppLogger.info(
        'Deleted item $itemId from KB $kbId',
        tag: 'KnowledgeService',
      );
    } on DioException catch (e) {
      _rethrowOrWrap(e, 'deleteItem');
    }
  }

  /// Trigger ingestion of all pending items in a knowledge base.
  ///
  /// This is a POST — never retry on failure.
  Future<void> ingestPending(String kbId) async {
    try {
      await _dio.post<dynamic>(ApiEndpoints.knowledgeIngestPending(kbId));
      AppLogger.info('Ingest pending for KB $kbId', tag: 'KnowledgeService');
    } on DioException catch (e) {
      _rethrowOrWrap(e, 'ingestPending');
    }
  }

  /// Ingest raw text content into a knowledge base.
  ///
  /// This is a POST — never retry on failure.
  Future<void> ingestText(
    String kbId, {
    required String title,
    required String content,
    String? sourceUrl,
  }) async {
    try {
      await _dio.post<dynamic>(
        ApiEndpoints.knowledgeIngestText(kbId),
        data: {
          'title': title,
          'content': content,
          if (sourceUrl != null) 'source_url': sourceUrl,
        },
      );
      AppLogger.info('Ingested text into KB $kbId', tag: 'KnowledgeService');
    } on DioException catch (e) {
      _rethrowOrWrap(e, 'ingestText');
    }
  }

  /// Import a file from Google Drive via the backend proxy.
  ///
  /// The backend downloads the file server-side (avoids CORS) and feeds
  /// it into the existing upload pipeline. One file per call — sequential
  /// import matches the kinship-shared pattern.
  ///
  /// This is a POST — never retry on failure.
  Future<Map<String, dynamic>> importFromGdrive(
    String kbId, {
    required String fileId,
    required String fileName,
    required String accessToken,
    String? mimeType,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.knowledgeGdriveImport(kbId),
        data: {
          'kbId': kbId,
          'fileId': fileId,
          'fileName': fileName,
          'accessToken': accessToken,
          if (mimeType != null) 'mimeType': mimeType,
        },
      );

      final body = response.data;
      if (body == null) {
        throw const ServerException('Empty Drive import response');
      }

      AppLogger.info(
        'Imported Drive file "$fileName" to KB $kbId',
        tag: 'KnowledgeService',
      );
      return body;
    } on DioException catch (e) {
      _rethrowOrWrap(e, 'importFromGdrive');
    }
  }

  /// Semantic search across knowledge bases.
  ///
  /// This is a POST — never retry on failure.
  Future<List<Map<String, dynamic>>> search({
    required String query,
    required String wallet,
    List<String>? kbIds,
    int? limit,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.knowledgeSearch,
        data: {
          'query': query,
          'wallet': wallet,
          if (kbIds != null) 'kb_ids': kbIds,
          if (limit != null) 'limit': limit,
        },
      );

      final body = response.data;
      if (body == null) {
        return [];
      }

      final results = body['results'] as List<dynamic>? ?? [];
      return results.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      _rethrowOrWrap(e, 'search');
    }
  }

  /// Update an agent's knowledgeBaseIds to link/unlink KBs.
  Future<void> updateAgentKbIds(String agentId, List<String> kbIds) async {
    try {
      await _dio.patch<dynamic>(
        ApiEndpoints.agentUpdate(agentId),
        data: {'knowledgeBaseIds': kbIds},
      );
      AppLogger.info(
        'Updated agent $agentId KB IDs (${kbIds.length} linked)',
        tag: 'KnowledgeService',
      );
    } on DioException catch (e) {
      _rethrowOrWrap(e, 'updateAgentKbIds');
    }
  }

  /// Rethrows if the Dio error already wraps a typed [AppException];
  /// otherwise wraps it in a [NetworkException].
  Never _rethrowOrWrap(DioException e, String method) {
    if (e.error is AppException) {
      throw e.error!;
    }
    AppLogger.error(
      'Failed: $method',
      tag: 'KnowledgeService',
      error: e,
      stackTrace: e.stackTrace,
    );
    throw const NetworkException(
      'Unable to connect. Please check your internet.',
    );
  }
}
