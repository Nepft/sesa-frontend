import '../services/csv_file_service.dart';
import 'csv_review_row.dart';
import 'sentiment_label.dart';

/// Hasil analisis massal dari file CSV sesuai respons backend.
class CsvAnalysisResult {
  const CsvAnalysisResult({
    required this.fileName,
    required this.totalRows,
    required this.analyzedRows,
    required this.failedRows,
    required this.rows,
  });

  /// Nama file yang dianalisis (dari sisi aplikasi, bukan dari backend).
  final String fileName;

  /// Jumlah baris pada file, termasuk baris yang dilewati.
  final int totalRows;

  /// Jumlah baris yang berhasil dianalisis menurut backend.
  final int analyzedRows;

  /// Jumlah baris yang gagal/dilewati.
  final int failedRows;

  /// Seluruh baris hasil yang diterima.
  final List<CsvReviewRow> rows;

  int get positiveCount =>
      rows.where((row) => row.label == SentimentLabel.positif).length;

  int get negativeCount =>
      rows.where((row) => row.label == SentimentLabel.negatif).length;

  /// Penyebut persentase: jumlah baris yang benar-benar berlabel.
  ///
  /// Disamakan dengan `positiveCount + negativeCount` (RULES.md bagian 7)
  /// sehingga ringkasan, legenda, dan donut chart selalu memakai data hasil
  /// yang sama persis.
  int get labeledRows => positiveCount + negativeCount;

  double get positivePercentage =>
      labeledRows == 0 ? 0 : positiveCount / labeledRows * 100;

  double get negativePercentage =>
      labeledRows == 0 ? 0 : negativeCount / labeledRows * 100;

  /// Membaca respons `POST /predict/batch` dan menggabungkannya dengan hasil
  /// parsing lokal [parsed].
  ///
  /// ```json
  /// {
  ///   "total": 2,
  ///   "results": [ { "row": 2, "label": "Positif" } ],
  ///   "skipped": [ { "row": 5, "reason": "..." } ]
  /// }
  /// ```
  ///
  /// Backend tidak mengirim isi teks, sehingga teks dan nomor baris diambil
  /// dari parsing lokal; label hanya boleh berasal dari backend. Label
  /// dipasangkan **berdasarkan urutan (index)**, bukan nomor baris: parsing
  /// lokal memakai `skipEmptyLines`, jadi nomor baris bisa meleset begitu ada
  /// baris kosong di tengah file.
  ///
  /// Melempar [FormatException] bila bentuk respons tidak sesuai kontrak, ada
  /// hasil tanpa label sentimen yang dikenali, atau jumlah hasil tidak sama
  /// dengan jumlah baris valid.
  factory CsvAnalysisResult.fromBatchResponse(
    Map<String, dynamic> json, {
    required String fileName,
    required ParsedCsvFile parsed,
  }) {
    final results = _readItems(json['results'], 'results');
    final skipped = json['skipped'] == null
        ? const []
        : _readItems(json['skipped'], 'skipped');

    final labels = <SentimentLabel>[];
    for (final item in results) {
      if (item['row'] is! num) {
        throw const FormatException(
          'Respons server tidak menyertakan nomor baris pada hasil batch.',
        );
      }
      final label = SentimentLabel.tryParse(item['label']);
      if (label == null) {
        throw const FormatException(
          'Respons server mengirim baris tanpa label sentimen yang dikenali.',
        );
      }
      labels.add(label);
    }

    final validRows = parsed.validRows;
    if (labels.length != validRows.length) {
      throw const FormatException(
        'Jumlah hasil batch tidak sama dengan jumlah baris valid pada file.',
      );
    }

    final rows = <CsvReviewRow>[];
    for (var index = 0; index < validRows.length; index++) {
      rows.add(
        CsvReviewRow(
          rowNumber: validRows[index].rowNumber,
          text: validRows[index].text,
          label: labels[index],
        ),
      );
    }

    final analyzedRows = rows.length;
    // Baris yang dilewati backend = baris valid yang tak muncul di results,
    // ditambah baris kosong yang memang tidak ikut validRows.
    final failedRows = skipped.length;

    return CsvAnalysisResult(
      fileName: fileName,
      totalRows: analyzedRows + failedRows,
      analyzedRows: analyzedRows,
      failedRows: failedRows,
      rows: List<CsvReviewRow>.unmodifiable(rows),
    );
  }

  /// Membaca kunci `results`/`skipped` berupa daftar objek.
  static List<Map<String, dynamic>> _readItems(Object? value, String field) {
    if (value is! List) {
      throw FormatException(
        'Respons server tidak menyertakan daftar "$field" yang valid.',
      );
    }
    final items = <Map<String, dynamic>>[];
    for (var index = 0; index < value.length; index++) {
      final item = value[index];
      if (item is! Map<String, dynamic>) {
        throw FormatException(
          'Isi "$field" ke-${index + 1} pada respons server bukan objek.',
        );
      }
      items.add(item);
    }
    return items;
  }
}
