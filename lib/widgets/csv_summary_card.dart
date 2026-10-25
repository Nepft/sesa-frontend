import 'package:flutter/material.dart';

import '../models/csv_analysis_result.dart';
import '../models/sentiment_label.dart';
import '../theme/app_theme.dart';
import 'donut_chart.dart';

/// Ringkasan hasil CSV: nama file, angka utama, dan proporsi sentimen.
///
/// Selalu ditampilkan lebih dulu sebelum tabel detail (AGENT.md, Panduan UI/UX).
class CsvSummaryCard extends StatelessWidget {
  const CsvSummaryCard({super.key, required this.result});

  final CsvAnalysisResult result;

  @override
  Widget build(BuildContext context) {
    final failedRows = result.failedRows;

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
        const SizedBox(height: 20),
        Text(
          result.fileName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _StatBlock(value: result.totalRows, label: 'Total'),
            ),
            Expanded(
              child: _StatBlock(
                value: result.analyzedRows,
                label: 'Dianalisis',
              ),
            ),
          ],
        ),
        if (failedRows > 0) ...[
          const SizedBox(height: 12),
          Text(
            '$failedRows baris dilewati karena kolom teks kosong.',
            style: const TextStyle(fontSize: 12, color: AppColors.textDim),
          ),
        ],
        const SizedBox(height: 32),
        const Text(
          'Proporsi sentimen',
          style: TextStyle(fontSize: 13, color: AppColors.textDim),
        ),
        const SizedBox(height: 20),
        Center(
          child: DonutChart(
            positiveCount: result.positiveCount,
            negativeCount: result.negativeCount,
          ),
        ),
        const SizedBox(height: 22),
        _LegendRow(
          label: SentimentLabel.positif,
          percentage: result.positivePercentage,
          count: result.positiveCount,
        ),
        const SizedBox(height: 16),
        _LegendRow(
          label: SentimentLabel.negatif,
          percentage: result.negativePercentage,
          count: result.negativeCount,
        ),
        const SizedBox(height: 20),
        Text(
          'Dari ${result.labeledRows} ulasan berhasil dianalisis.',
          style: const TextStyle(fontSize: 13, color: AppColors.textDim),
        ),
      ],
    );
  }
}

class _StatBlock extends StatelessWidget {
  const _StatBlock({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$value',
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppColors.textDim),
        ),
      ],
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.label,
    required this.percentage,
    required this.count,
  });

  final SentimentLabel label;
  final double percentage;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: label.color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label.displayName,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        // FittedBox mengecilkannya bila angka besar + font skala besar
        // melebihi lebar layar, alih-alih memicu overflow.
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: label.color,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '$count ulasan',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textDim,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
