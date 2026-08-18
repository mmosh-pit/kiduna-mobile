import 'package:dio/dio.dart';

import '../../core/errors/exceptions.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/utils/logger.dart';
import '../models/presale_model.dart';
import '../models/purchase_model.dart';

/// Presale API operations via kinship-backend.
///
/// Uses [authDio] (kinship-backend base URL) for all calls. Public endpoints
/// (list, detail) work without auth; buy and purchases require a JWT.
///
/// Returns parsed data or throws typed exceptions — no business logic.
class PresaleService {
  PresaleService._();

  static final PresaleService instance = PresaleService._();

  /// kinship-backend Dio instance (same as RealmService, AuthService).
  Dio get _dio => ApiClient.instance.authDio;

  // ─── List presales ──────────────────────────────────────────────────────

  /// Fetch presales with optional filters.
  ///
  /// [status] — 'live' (default), 'upcoming', 'completed', 'all'.
  /// [symbol] — filter by token symbol (e.g. 'KIDUNA').
  Future<List<PresaleModel>> listPresales({
    String status = 'all',
    String? symbol,
  }) async {
    try {
      final queryParams = <String, dynamic>{'status': status};
      if (symbol != null && symbol.isNotEmpty) {
        queryParams['symbol'] = symbol;
      }

      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.presales,
        queryParameters: queryParams,
      );

      final body = response.data;
      if (body == null) {
        throw const ServerException('Empty response from presales list');
      }

      final list = body['presales'] as List<dynamic>? ?? [];
      final presales = list
          .map((e) => PresaleModel.fromJson(e as Map<String, dynamic>))
          .toList();

      AppLogger.info(
        'Fetched ${presales.length} presales (status=$status)',
        tag: 'PresaleService',
      );
      return presales;
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error!;
      AppLogger.error(
        'Failed to fetch presales',
        tag: 'PresaleService',
        error: e,
      );
      throw ServerException(
        e.response?.data?['error']?.toString() ?? 'Failed to load presales',
      );
    }
  }

  // ─── Get presale detail ─────────────────────────────────────────────────

  /// Fetch a single presale with full details including buyer count.
  Future<PresaleModel> getPresale(String presaleId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.presaleById(presaleId),
      );

      final body = response.data;
      if (body == null) {
        throw const ServerException('Empty response from presale detail');
      }

      AppLogger.info(
        'Fetched presale $presaleId',
        tag: 'PresaleService',
      );
      return PresaleModel.fromJson(body);
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error!;
      AppLogger.error(
        'Failed to fetch presale $presaleId',
        tag: 'PresaleService',
        error: e,
      );
      throw ServerException(
        e.response?.data?['error']?.toString() ?? 'Failed to load presale',
      );
    }
  }

  // ─── Buy tokens ─────────────────────────────────────────────────────────

  /// Purchase tokens from a presale. Requires authentication.
  ///
  /// [usdcAmount] is the amount in whole USDC (e.g. 500 = $500).
  /// Returns the purchase record with on-chain signatures.
  Future<PurchaseModel> buyTokens(
    String presaleId,
    double usdcAmount,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.presaleBuy(presaleId),
        data: {'usdcAmount': usdcAmount},
      );

      final body = response.data;
      if (body == null) {
        throw const ServerException('Empty response from buy');
      }

      AppLogger.info(
        'Purchased \$$usdcAmount USDC from presale $presaleId',
        tag: 'PresaleService',
      );
      return PurchaseModel.fromJson(body);
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error!;
      AppLogger.error(
        'Failed to buy from presale $presaleId',
        tag: 'PresaleService',
        error: e,
      );
      throw ServerException(
        e.response?.data?['error']?.toString() ?? 'Purchase failed',
      );
    }
  }

  // ─── Purchase history ───────────────────────────────────────────────────

  /// Fetch purchase history for a presale. Requires authentication.
  ///
  /// Creator sees all purchases; buyer sees only their own.
  Future<List<PurchaseModel>> getPurchases(String presaleId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.presalePurchases(presaleId),
      );

      final body = response.data;
      if (body == null) {
        throw const ServerException('Empty response from purchases');
      }

      final list = body['purchases'] as List<dynamic>? ?? [];
      final purchases = list
          .map((e) => PurchaseModel.fromJson(e as Map<String, dynamic>))
          .toList();

      AppLogger.info(
        'Fetched ${purchases.length} purchases for presale $presaleId',
        tag: 'PresaleService',
      );
      return purchases;
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error!;
      AppLogger.error(
        'Failed to fetch purchases for presale $presaleId',
        tag: 'PresaleService',
        error: e,
      );
      throw ServerException(
        e.response?.data?['error']?.toString() ?? 'Failed to load purchases',
      );
    }
  }
}
