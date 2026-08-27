// Driver for running integration_test on the web via `flutter drive`.
//
// Web is not supported by `flutter test -d chrome`, so the browser path goes
// through flutter drive with chromedriver. See integration_test/README.md.
import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver();
