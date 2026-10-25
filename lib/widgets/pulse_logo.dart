import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Glyph logo aplikasi, digambar dari path SVG yang sama dengan versi web
/// (`M3 12h4l3 8 4-16 3 8h4`), agar identitas visual tetap selaras.
class PulseLogo extends StatelessWidget {
  const PulseLogo({
    super.key,
    this.size = 18,
    this.color = AppColors.accent,
    this.strokeWidth = 2,
  });

  final double size;
  final Color color;

  /// Lebar garis dalam satuan viewBox 24 (sama seperti `strokeWidth` SVG).
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _PulseLogoPainter(color: color, strokeWidth: strokeWidth),
    );
  }
}

class _PulseLogoPainter extends CustomPainter {
  const _PulseLogoPainter({required this.color, required this.strokeWidth});

  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24;
    final path = Path()
      ..moveTo(3 * scale, 12 * scale)
      ..lineTo(7 * scale, 12 * scale)
      ..lineTo(10 * scale, 20 * scale)
      ..lineTo(14 * scale, 4 * scale)
      ..lineTo(17 * scale, 12 * scale)
      ..lineTo(21 * scale, 12 * scale);

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth * scale
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_PulseLogoPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
  }
}
