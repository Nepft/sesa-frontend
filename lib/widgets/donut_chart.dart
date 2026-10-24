import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Donut chart perbandingan sentimen.
///
/// Dibuat dengan [CustomPaint] mengikuti keputusan versi web: satu donut saja,
/// tanpa library chart tambahan (RULES.md bagian 6 — "Visualisasi").
class DonutChart extends StatelessWidget {
  const DonutChart({
    super.key,
    required this.positiveCount,
    required this.negativeCount,
  });

  final int positiveCount;
  final int negativeCount;

  int get total => positiveCount + negativeCount;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label:
          'Proporsi sentimen: $positiveCount ulasan positif dan '
          '$negativeCount ulasan negatif dari $total ulasan.',
      child: SizedBox(
        width: 168,
        height: 168,
        child: CustomPaint(
          painter: DonutChartPainter(
            positiveCount: positiveCount,
            negativeCount: negativeCount,
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$total',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'ulasan',
                  style: TextStyle(fontSize: 12, color: AppColors.textDim),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DonutChartPainter extends CustomPainter {
  const DonutChartPainter({
    required this.positiveCount,
    required this.negativeCount,
  });

  final int positiveCount;
  final int negativeCount;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 16.0;
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - stroke / 2;
    if (radius <= 0) return;

    final ring = Rect.fromCircle(center: center, radius: radius);

    // Cincin dasar tetap terlihat ketika belum ada hasil.
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = AppColors.surfaceAlt,
    );

    final total = positiveCount + negativeCount;
    if (total <= 0) return;

    const startAngle = -math.pi / 2;
    final positiveSweep = positiveCount / total * 2 * math.pi;

    if (positiveSweep > 0) {
      canvas.drawArc(
        ring,
        startAngle,
        positiveSweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..color = AppColors.positive,
      );
    }

    final negativeSweep = 2 * math.pi - positiveSweep;
    if (negativeSweep > 0) {
      canvas.drawArc(
        ring,
        startAngle + positiveSweep,
        negativeSweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..color = AppColors.negative,
      );
    }
  }

  @override
  bool shouldRepaint(DonutChartPainter oldDelegate) {
    return oldDelegate.positiveCount != positiveCount ||
        oldDelegate.negativeCount != negativeCount;
  }
}
