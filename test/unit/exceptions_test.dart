import 'package:flutter_test/flutter_test.dart';
import 'package:kiduna_mobile/core/errors/exceptions.dart';

void main() {
  test('exceptions expose their message and are Exceptions', () {
    const exception = ServerException('boom');
    expect(exception, isA<Exception>());
    expect(exception.message, 'boom');
    expect(exception.toString(), 'ServerException: boom');
  });

  test('toString omits the colon when there is no message', () {
    expect(const NetworkException().toString(), 'NetworkException');
  });
}
