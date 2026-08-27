import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiduna/games/medieval_poker/flame/seat_ring.dart';

/// Visual check on short-handed seating.
///
/// The numeric tests in seat_ring_test.dart prove the angles; this shows what
/// they mean on the felt. Tournament tables run with two or three players when
/// no-shows leave them light, so those layouts have to look deliberate rather
/// than like a four-seat table with holes in it.

Future<void> _loadFonts() async {
  final loader = FontLoader('IBMPlexSans');
  for (final path in const [
    'assets/fonts/IBMPlexSans-Regular.ttf',
    'assets/fonts/IBMPlexSans-Medium.ttf',
  ]) {
    final file = File(path);
    if (!file.existsSync()) continue;
    loader.addFont(
      file.readAsBytes().then(
        (b) => ByteData.view(Uint8List.fromList(b).buffer),
      ),
    );
  }
  await loader.load();
}

const _felt = Color(0xFF1E4034);
const _rim = Color(0xFF6B5533);
const _gold = Color(0xFFEDC169);
const _ink = Color(0xFF14100A);

class _TablePainter extends CustomPainter {
  final int opponents;
  const _TablePainter(this.opponents);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.46;
    final fx = size.width * 0.46;
    final fy = size.height * 0.24;

    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy), width: fx * 2, height: fy * 2),
      Paint()..color = _felt,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy), width: fx * 2, height: fy * 2),
      Paint()
        ..color = _rim
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    final ring = SeatRing(
      centreX: cx,
      centreY: cy,
      radiusX: size.width * 0.37,
      radiusY: fy + 26,
      viewerDrop: fy * 0.52,
    );

    void seat(SeatSlot s, String label, bool isViewer) {
      canvas.drawCircle(
        Offset(s.x, s.y),
        18,
        Paint()..color = isViewer ? _gold : const Color(0xFF3A2E1C),
      );
      canvas.drawCircle(
        Offset(s.x, s.y),
        18,
        Paint()
          ..color = _rim
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            fontFamily: 'IBMPlexSans',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isViewer ? _ink : Colors.white70,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(s.x - tp.width / 2, s.y - tp.height / 2));
    }

    for (var i = 0; i < opponents; i++) {
      seat(ring.opponent(i, opponents), 'P${i + 2}', false);
    }
    seat(ring.viewer, 'You', true);
  }

  @override
  bool shouldRepaint(covariant _TablePainter old) => old.opponents != opponents;
}

class _Tables extends StatelessWidget {
  const _Tables();

  @override
  Widget build(BuildContext context) {
    const labels = {1: 'Heads-up', 2: '3-handed', 3: '4-handed'};
    return ColoredBox(
      color: _ink,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final n in [1, 2, 3])
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                children: [
                  Text(
                    '${labels[n]}  ·  ${n + 1} seats',
                    style: const TextStyle(
                      fontFamily: 'IBMPlexSans',
                      fontSize: 11,
                      letterSpacing: 1.8,
                      color: Color(0xFF9C8459),
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: 380,
                    height: 210,
                    child: CustomPaint(painter: _TablePainter(n)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

void main() {
  setUpAll(_loadFonts);

  testWidgets('golden: short-handed seat layouts', (tester) async {
    tester.view.physicalSize = const Size(400, 780);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: _ink,
          body: Center(child: _Tables()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(_Tables),
      matchesGoldenFile('goldens/seat_ring_short_handed.png'),
    );
  });
}
