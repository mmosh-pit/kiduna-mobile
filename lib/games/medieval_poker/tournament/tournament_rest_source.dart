import 'package:dio/dio.dart';

import 'tournament_models.dart';
import 'tournament_source.dart';

/// Talks to the backend's `/tournaments` routes.
///
/// The other half of the [TournamentSource] seam: swap this in for
/// `FakeTournamentSource` and the screens are unchanged — they never learn
/// which they have.
///
/// Responses are wrapped as `{ data: ... }` by the backend's `ok()` helper, so
/// every read unwraps one level.
class RestTournamentSource implements TournamentSource {
  final Dio dio;

  RestTournamentSource({required this.dio});

  Map<String, dynamic> _data(Response<dynamic> res) {
    final body = res.data;
    if (body is Map && body['data'] is Map) {
      return Map<String, dynamic>.from(body['data'] as Map);
    }
    if (body is Map) return Map<String, dynamic>.from(body);
    return const {};
  }

  Never _fail(Object e) {
    if (e is DioException) {
      final body = e.response?.data;
      final message = body is Map ? body['error'] : null;
      throw TournamentException(
        message?.toString() ?? e.message ?? 'Request failed',
        statusCode: e.response?.statusCode,
      );
    }
    throw TournamentException('$e');
  }

  @override
  Future<List<TournamentSummary>> list() async {
    try {
      final res = await dio.get<dynamic>('/tournaments');
      final rows = _data(res)['tournaments'] as List? ?? const [];
      return [
        for (final t in rows)
          TournamentSummary.fromJson(Map<String, dynamic>.from(t as Map)),
      ];
    } catch (e) {
      _fail(e);
    }
  }

  @override
  Future<TournamentDetail> detail(String id) async {
    try {
      final res = await dio.get<dynamic>('/tournaments/$id');
      return TournamentDetail.fromJson(_data(res));
    } catch (e) {
      _fail(e);
    }
  }

  @override
  Future<TournamentDetail> register(String id) async {
    try {
      final res = await dio.post<dynamic>('/tournaments/$id/register');
      return TournamentDetail.fromJson(_data(res));
    } catch (e) {
      _fail(e);
    }
  }

  @override
  Future<TournamentDetail> withdraw(String id) async {
    try {
      final res = await dio.delete<dynamic>('/tournaments/$id/register');
      return TournamentDetail.fromJson(_data(res));
    } catch (e) {
      _fail(e);
    }
  }

  @override
  Future<TournamentDetail> create({
    required String name,
    required DateTime startsAt,
    int? maxTables,
    int? seatsPerTable,
    int? minSeatsPerTable,
  }) async {
    try {
      final res = await dio.post<dynamic>(
        '/tournaments',
        data: {
          'name': name,
          'startsAt': startsAt.toUtc().toIso8601String(),
          'maxTables': ?maxTables,
          'seatsPerTable': ?seatsPerTable,
          'minSeatsPerTable': ?minSeatsPerTable,
        },
      );
      return TournamentDetail.fromJson(_data(res));
    } catch (e) {
      _fail(e);
    }
  }

  @override
  void dispose() {}
}

/// A tournament request that failed, carrying the server's own message so the
/// UI can show why rather than a generic failure.
class TournamentException implements Exception {
  final String message;
  final int? statusCode;
  const TournamentException(this.message, {this.statusCode});

  @override
  String toString() => message;
}
