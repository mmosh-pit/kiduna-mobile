import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// A canned reply for one request.
class FakeReply {
  final int statusCode;
  final Object? body;
  const FakeReply(this.body, {this.statusCode = 200});
}

/// A [Dio] whose HTTP layer is replaced by a handler function.
///
/// The project has no mocking package, and adding one needs approval — but Dio
/// already lets you swap the adapter, which is enough to drive a REST client
/// through real serialization without a server.
class FakeDio {
  FakeDio(this.handler) {
    dio = Dio(BaseOptions(baseUrl: 'https://backend.test'))
      ..httpClientAdapter = _FakeAdapter(this);
  }

  /// Answers a request, or throws to simulate a transport failure.
  final FakeReply Function(RequestOptions options) handler;

  late final Dio dio;

  /// Every request made, in order — so a test can assert on the path, method,
  /// query and body that a client actually sent.
  final List<RequestOptions> requests = [];
}

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this._owner);

  final FakeDio _owner;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    _owner.requests.add(options);
    final reply = _owner.handler(options);
    return ResponseBody.fromString(
      jsonEncode(reply.body ?? const <String, dynamic>{}),
      reply.statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// Wraps a payload in the backend's `{ data: … }` envelope.
Map<String, dynamic> envelope(Map<String, dynamic> data) => {'data': data};
