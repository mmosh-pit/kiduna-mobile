import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import 'tournament_models.dart';

/// Raised for a tournament REST failure, carrying the server's message when
/// present so the UI can say what actually went wrong.
class TournamentException implements Exception {
  final String message;

  /// True when the backend has no `/tournaments` routes at all, which is a
  /// deployment problem rather than something the player did wrong.
  final bool isMissingEndpoint;

  const TournamentException(this.message, {this.isMissingEndpoint = false});

  @override
  String toString() => message;
}

/// REST client for the Node tournament routes (`/tournaments/*`).
///
/// Uses the app's [ApiClient.authDio], which targets `AUTH_API_URL` (the Node
/// backend, where these routes live) and attaches the bearer token — so the
/// caller must already be signed in.
class TournamentClient {
  final Dio _dio;
  TournamentClient({Dio? dio}) : _dio = dio ?? ApiClient.instance.authDio;

  Future<List<TournamentSummary>> list({String? status, int? limit}) async {
    final res = await _call(
      () => _dio.get(
        '/tournaments',
        queryParameters: {'status': ?status, 'limit': ?limit},
      ),
    );
    final rows = _data(res)['tournaments'] as List? ?? const [];
    return [
      for (final t in rows)
        TournamentSummary.fromJson(t as Map<String, dynamic>),
    ];
  }

  Future<TournamentDetail> create({
    required String name,
    required int size,
    bool? timedLevels,
  }) async {
    final res = await _call(
      () => _dio.post(
        '/tournaments',
        data: {'name': name, 'size': size, 'timedLevels': ?timedLevels},
      ),
    );
    return TournamentDetail.fromJson(_data(res));
  }

  Future<TournamentDetail> detail(String id) async {
    final res = await _call(() => _dio.get('/tournaments/$id'));
    return TournamentDetail.fromJson(_data(res));
  }

  Future<TournamentDetail> register(String id) async {
    final res = await _call(() => _dio.post('/tournaments/$id/register'));
    return TournamentDetail.fromJson(_data(res));
  }

  Future<TournamentDetail> withdraw(String id) async {
    final res = await _call(() => _dio.delete('/tournaments/$id/register'));
    return TournamentDetail.fromJson(_data(res));
  }

  Future<TournamentDetail> start(String id) async {
    final res = await _call(() => _dio.post('/tournaments/$id/start'));
    return TournamentDetail.fromJson(_data(res));
  }

  /// The viewer's live heat, or null when they have no table to sit at.
  Future<MyMatch?> myMatch(String id) async {
    final res = await _call(() => _dio.get('/tournaments/$id/my-match'));
    final m = _data(res)['myMatch'];
    return m == null ? null : MyMatch.fromJson(m as Map<String, dynamic>);
  }

  // ── plumbing ─────────────────────────────────────────────────────────────

  Future<Response<dynamic>> _call(
    Future<Response<dynamic>> Function() fn,
  ) async {
    try {
      return await fn();
    } on DioException catch (e) {
      final data = e.response?.data;
      final msg = (data is Map && data['error'] is String)
          ? data['error'] as String
          : (e.message ?? 'Network error');
      // A 404 on the collection itself means the backend does not serve these
      // routes — worth distinguishing from "this tournament doesn't exist", so
      // an un-deployed backend doesn't read as an empty list.
      final missing =
          e.response?.statusCode == 404 &&
          !(data is Map && data['error'] is String);
      throw TournamentException(msg, isMissingEndpoint: missing);
    }
  }

  Map<String, dynamic> _data(Response<dynamic> res) {
    final body = res.data;
    if (body is Map && body['data'] is Map) {
      return (body['data'] as Map).cast<String, dynamic>();
    }
    throw const TournamentException('Malformed tournament response');
  }
}
