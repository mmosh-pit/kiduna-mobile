import 'package:flutter_test/flutter_test.dart';
import 'package:kiduna_mobile/core/utils/logger.dart';

void main() {
  test('every log level runs without throwing', () {
    expect(() => AppLogger.debug('debug'), returnsNormally);
    expect(() => AppLogger.info('info', tag: 'Test'), returnsNormally);
    expect(() => AppLogger.warning('warning'), returnsNormally);
    expect(
      () => AppLogger.error(
        'error',
        tag: 'Test',
        error: Exception('boom'),
        stackTrace: StackTrace.current,
      ),
      returnsNormally,
    );
  });
}
