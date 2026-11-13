import 'sentiment_label.dart';

/// Satu baris hasil analisis CSV.
///
/// Teks dan nomor baris berasal dari parsing file di sisi aplikasi, sedangkan
/// [label] selalu diterima dari backend, tidak pernah ditebak.
class CsvReviewRow {
  const CsvReviewRow({
    required this.rowNumber,
    required this.text,
    required this.label,
    this.confidence,
  });

  /// Nomor baris pada file sumber (baris data pertama = 1, tanpa header).
  final int rowNumber;

  final String text;

  final SentimentLabel label;

  /// Persentase confidence per label (0-100) dari backend; `null` bila baris
  /// hasil tidak memuatnya atau nilainya tidak valid.
  final Map<String, double>? confidence;
}
