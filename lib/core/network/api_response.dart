/// Generic wrapper for the `{ "data": { ... } }` envelope returned by
/// kinship-backend.
///
/// The auth endpoints (login, is-auth) wrap their payload inside a `data` key.
/// This class extracts it once so every caller doesn't repeat the same logic.
class ApiResponse<T> {
  const ApiResponse({required this.data});

  final T data;

  /// Parse a raw JSON map using the provided [fromJson] converter.
  ///
  /// Expects the shape `{ "data": { ... } }`.  If the outer `data` key is
  /// missing the entire map is forwarded to [fromJson] — this keeps the
  /// wrapper safe for APIs that don't use an envelope.
  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final inner = json['data'];
    if (inner is Map<String, dynamic>) {
      return ApiResponse(data: fromJson(inner));
    }
    return ApiResponse(data: fromJson(json));
  }
}
