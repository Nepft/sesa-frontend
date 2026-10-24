import 'package:csv/csv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:steam_sentimen_analyzer/models/csv_analysis_result.dart';
import 'package:steam_sentimen_analyzer/models/csv_review_row.dart';
import 'package:steam_sentimen_analyzer/models/sentiment_label.dart';
import 'package:steam_sentimen_analyzer/services/csv_export_service.dart';

CsvAnalysisResult buildResult({required int rowCount}) {
  return CsvAnalysisResult(
    fileName: 'My Dataset (baru).CSV',
    totalRows: rowCount,
    analyzedRows: rowCount,
    failedRows: 0,
    rows: List<CsvReviewRow>.generate(
      rowCount,
      (index) => CsvReviewRow(
        rowNumber: index + 1,
        text: index.isEven ? 'ulasan ${index + 1}' : 'jelek, "parah"\nbaru',
        label: index.isEven ? SentimentLabel.positif : SentimentLabel.negatif,
      ),
    ),
  );
}

void main() {
  const service = CsvExportService();

  group('buildCsv', () {
    test('diawali UTF-8 BOM agar spreadsheet membaca teks non-ASCII', () {
      final csv = service.buildCsv(buildResult(rowCount: 2));

      expect(csv.startsWith('\uFEFF'), isTrue);
    });

    test('berisi seluruh baris hasil, bukan hanya halaman yang tampil', () {
      final result = buildResult(rowCount: 25);
      final rows = Csv().decode(service.buildCsv(result).substring(1));

      expect(rows, hasLength(26)); // header + 25 baris
      expect(rows.first, ['No', 'Ulasan', 'Sentimen']);
      // Decoder mempertahankan field sebagai teks (dynamicTyping nonaktif).
      expect(rows.last.first, '25');
    });

    test('meng-escaping koma, kutip, dan baris baru dengan benar', () {
      final result = buildResult(rowCount: 2);
      final decoded = Csv().decode(service.buildCsv(result).substring(1));

      expect(decoded, hasLength(3));
      expect(decoded[2], ['2', 'jelek, "parah"\nbaru', 'Negatif']);
    });
  });

  group('buildFileName', () {
    test('menyusun nama yang sudah disanitasi dan berakhiran .csv', () {
      final fileName = service.buildFileName(buildResult(rowCount: 1));

      expect(fileName, 'hasil-analisis-my-dataset-baru.csv');
    });

    test('tetap aman bila nama asli hanya berisi karakter khusus', () {
      final result = CsvAnalysisResult(
        fileName: '###.csv',
        totalRows: 1,
        analyzedRows: 1,
        failedRows: 0,
        rows: const [],
      );

      expect(service.buildFileName(result), 'hasil-analisis.csv');
    });
  });
}
