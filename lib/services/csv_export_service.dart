import 'package:csv/csv.dart';

import '../models/csv_analysis_result.dart';

/// Menyusun file CSV berisi seluruh baris hasil analisis untuk tombol
/// "Unduh hasil".
class CsvExportService {
  const CsvExportService();

  /// Membuat isi file hasil unduhan.
  ///
  /// - Kolom mengikuti tabel di layar: nomor, ulasan, sentimen.
  /// - Diawali UTF-8 BOM agar aplikasi spreadsheet membaca teks non-ASCII
  ///   dengan benar.
  /// - Pembuatan baris diserahkan ke encoder CSV sehingga koma, tanda kutip,
  ///   dan newline di dalam teks ulasan ikut di-escaping dengan benar.
  /// - Berisi seluruh baris hasil, bukan hanya halaman yang sedang tampil.
  String buildCsv(CsvAnalysisResult result) {
    final rows = <List<dynamic>>[
      const ['No', 'Ulasan', 'Sentimen'],
      for (final row in result.rows)
        [row.rowNumber, row.text, row.label.displayName],
    ];
    return Csv(addBom: true).encode(rows);
  }

  /// Menyusun nama file hasil yang sudah disanitasi; nama asli file pengguna
  /// tidak dipakai mentah-mentah (RULES.md bagian 7).
  String buildFileName(CsvAnalysisResult result) {
    final base = result.fileName.toLowerCase().replaceFirst(
      RegExp(r'\.csv$'),
      '',
    );
    final sanitized = base
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    final prefix = sanitized.isEmpty
        ? 'hasil-analisis'
        : 'hasil-analisis-$sanitized';
    final trimmed = prefix.length > 60 ? prefix.substring(0, 60) : prefix;
    return '$trimmed.csv';
  }
}
