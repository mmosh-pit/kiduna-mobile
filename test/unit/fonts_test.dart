import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Verifies that every font declared in `pubspec.yaml` is actually bundled and
/// is a font Flutter's engine can parse — `rootBundle.load` fails if the asset
/// is missing, and `FontLoader.load` fails if the file is not a valid font.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const Map<String, List<String>> fontAssets = <String, List<String>>{
    'Avenir': <String>[
      'assets/fonts/Avenir-Book.ttf',
      'assets/fonts/Avenir-Regular.ttf',
      'assets/fonts/Avenir-Heavy.ttf',
    ],
    'GoudyHeavyface': <String>[
      'assets/fonts/GoudyHeavyface.ttf',
    ],
  };

  fontAssets.forEach((String family, List<String> paths) {
    test('loads the $family font family from bundled assets', () async {
      final FontLoader loader = FontLoader(family);
      for (final String path in paths) {
        final ByteData bytes = await rootBundle.load(path);
        expect(bytes.lengthInBytes, greaterThan(0), reason: '$path is empty');
        loader.addFont(Future<ByteData>.value(bytes));
      }
      await loader.load();
    });
  });
}
