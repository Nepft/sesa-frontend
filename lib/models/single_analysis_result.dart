import 'confidence_percentages.dart';
import 'sentiment_label.dart';

/// Hasil analisis satu teks ulasan yang berasal dari respons backend.
class SingleAnalysisResult {
  const SingleAnalysisResult({
    required this.text,
    required this.label,
    this.confidence,
  });

  /// Teks ulasan yang dianalisis; dipakai untuk menampilkan kutipan di hasil.
  final String text;

  final SentimentLabel label;

  /// Persentase confidence per label (0-100) dari backend, atau `null` bila
  /// tidak dikirim / tidak valid sehingga baris confidence disembunyikan.
  final Map<String, double>? confidence;

  /// Membaca respons `POST /predict` sesuai kontrak backend:
  ///
  /// ```json
  /// { "text": "ulasan seperti dikirim", "label": "Positif",
  ///   "confidence": { "Negatif": 18.4, "Positif": 81.6 } }
  /// ```
  ///
  /// `confidence` bersifat opsional (bisa `null` pada artefak model tanpa
  /// probabilitas); label yang tidak dikenal tetap membuat [FormatException].
  factory SingleAnalysisResult.fromJson(
    Map<String, dynamic> json, {
    required String submittedText,
  }) {
    final label = SentimentLabel.tryParse(json['label']);
    if (label == null) {
      throw const FormatException(
        'Respons server tidak menyertakan label sentimen yang dikenali.',
      );
    }

    final rawText = json['text'];
    return SingleAnalysisResult(
      text: rawText is String && rawText.trim().isNotEmpty
          ? rawText
          : submittedText,
      label: label,
      confidence: tryParseConfidence(json['confidence']),
    );
  }
}
