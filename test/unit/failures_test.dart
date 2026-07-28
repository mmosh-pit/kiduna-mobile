import 'package:flutter_test/flutter_test.dart';
import 'package:kiduna_mobile/core/errors/failures.dart';

void main() {
  test('failures of the same type and message are equal', () {
    expect(const ServerFailure('x'), const ServerFailure('x'));
    expect(
      const ServerFailure('x').hashCode,
      const ServerFailure('x').hashCode,
    );
  });

  test('different failure types are never equal', () {
    expect(const ServerFailure('x') == const NetworkFailure('x'), isFalse);
  });

  test('failures expose a non-empty default message', () {
    expect(const NetworkFailure().message, isNotEmpty);
    expect(const UnknownFailure().message, isNotEmpty);
  });
}
