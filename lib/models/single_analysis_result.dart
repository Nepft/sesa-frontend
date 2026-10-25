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

  /// Confidence dari backend dalam rentang 0..1, atau `null` bila tidak ada.
  ///
  /// Nilai di luar rentang itu sengaja tidak ditampilkan karena artinya tidak
  /// pasti (bisa jadi persentase); RULES.md bagian 5 melarang angka
  /// confidence yang dibuat-buat.
  final double? confidence;

  /// Membaca respons `POST /predict` sesuai kontrak backend:
  ///
  /// ```json
  /// { "text": "ulasan seperti dikirim", "label": "Positif" }
  /// ```
  ///
  /// `confidence` tidak dikirim backend saat ini; bila suatu saat tersedia dan
  /// berada pada rentang 0..1, nilai itu dipakai.
  ///
  /// Melempar [FormatException] bila label sentimen tidak dikenali agar
  /// lapisan service mengubahnya menjadi galat respons yang jelas.
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
      confidence: _readConfidence(json['confidence']),
    );
  }

  static double? _readConfidence(Object? raw) {
    if (raw is! num) return null;
    final value = raw.toDouble();
    if (value < 0 || value > 1) return null;
    return value;
  }
}
