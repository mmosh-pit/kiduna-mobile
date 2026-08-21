import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// The poker table: a wooden-railed oval with green felt, drawn behind the
/// seats and community cards. Sized/positioned by the game layout.
class TableComponent extends PositionComponent {
  TableComponent({super.position, super.size}) : super(anchor: Anchor.center);

  @override
  void render(Canvas canvas) {
    final rect = Offset.zero & Size(width, height);

    // Soft drop shadow under the table.
    canvas.drawOval(
      rect.shift(const Offset(0, 6)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );

    // Wooden rail.
    canvas.drawOval(rect, Paint()..color = const Color(0xFF3A2A18));
    canvas.drawOval(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFFC8A24B),
    );

    // Green felt.
    final feltRect = rect.deflate(16);
    canvas.drawOval(feltRect, Paint()..color = const Color(0xFF1F5A40));
    // Inner rim shadow for depth.
    canvas.drawOval(
      feltRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..color = const Color(0xFF15402D).withValues(alpha: 0.8),
    );
  }
}
