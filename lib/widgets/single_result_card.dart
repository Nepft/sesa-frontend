import 'package:flutter/material.dart';

import '../models/single_analysis_result.dart';
import '../theme/app_theme.dart';

/// Hasil analisis satu teks ulasan: label sentimen lalu kutipan ulasan.
class SingleResultCard extends StatelessWidget {
  const SingleResultCard({super.key, required this.result});

  final SingleAnalysisResult result;

  @override
  Widget build(BuildContext context) {
    final label = result.label;
    final confidence = result.confidence;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hasil Analisis',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 22),
        Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: label.softColor,
                borderRadius: BorderRadius.circular(AppColors.radius),
                border: Border.all(color: label.softColor),
              ),
              child: Icon(label.icon, size: 30, color: label.color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sentimen',
                    style: TextStyle(
                      fontSize: 12,
                      letterSpacing: 0.6,
                      color: AppColors.textDim,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label.displayName,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: label.color,
                    ),
                  ),
                  if (confidence != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Confidence ${(confidence * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textDim,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        const Divider(),
        const SizedBox(height: 18),
        const Text(
          'Ulasan',
          style: TextStyle(
            fontSize: 12,
            letterSpacing: 0.6,
            color: AppColors.textDim,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.only(left: 14),
          decoration: const BoxDecoration(
            border: Border(left: BorderSide(color: AppColors.accent, width: 3)),
          ),
          child: Text(
            result.text,
            style: const TextStyle(
              fontSize: 15,
              height: 1.55,
              color: AppColors.textMuted,
            ),
          ),
        ),
      ],
    );
  }
}
