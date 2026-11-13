import 'sentiment_label.dart';

/// Mengurai field `confidence` respons backend menjadi persentase per label
/// (0-100), atau `null` bila field tidak ada, kosong, atau tidak valid.
///
/// Angka di luar rentang 0-100 dan bukan angka membuat seluruh field dianggap
/// tidak pasti: lebih baik baris confidence disembunyikan daripada menampilkan
/// angka yang salah (RULES.md bagian 5).
Map<String, double>? tryParseConfidence(Object? raw) {
  if (raw is! Map) return null;
  final parsed = <String, double>{};
  for (final entry in raw.entries) {
    final key = entry.key;
    final value = entry.value;
    if (key is! String || value is! num) return null;
    final percent = value.toDouble();
    if (percent.isNaN || percent < 0 || percent > 100) return null;
    parsed[key] = percent;
  }
  return parsed.isEmpty ? null : parsed;
}

/// Persentase per label dalam urutan tampilan (Positif lalu Negatif), hanya
/// label yang tersedia pada [confidence].
List<MapEntry<SentimentLabel, double>> confidenceEntries(
  Map<String, double>? confidence,
) {
  final entries = <MapEntry<SentimentLabel, double>>[];
  if (confidence == null) return entries;
  for (final label in SentimentLabel.values) {
    final value = confidence[label.displayName];
    if (value != null) entries.add(MapEntry(label, value));
  }
  return entries;
}

/// Menyusun [confidence] menjadi satu baris tampilan, mis.
/// `Positif 81.6% · Negatif 18.4%`; `null` bila tidak ada yang ditampilkan.
String? formatConfidenceLine(Map<String, double>? confidence) {
  final entries = confidenceEntries(confidence);
  if (entries.isEmpty) return null;
  return entries
      .map((entry) => '${entry.key.displayName} ${entry.value.toStringAsFixed(1)}%')
      .join(' · ');
}
