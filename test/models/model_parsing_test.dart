import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:steam_sentimen_analyzer/models/csv_analysis_result.dart';
import 'package:steam_sentimen_analyzer/models/sentiment_label.dart';
import 'package:steam_sentimen_analyzer/models/single_analysis_result.dart';
import 'package:steam_sentimen_analyzer/services/csv_file_service.dart';

Map<String, dynamic> decodeObject(String source) =>
    jsonDecode(source) as Map<String, dynamic>;

/// Membangun hasil parsing lokal: baris data pertama bernomor 1.
ParsedCsvFile parsedOf(List<String> texts) => ParsedCsvFile(
  totalRows: texts.length,
  validRows: [
    for (var index = 0; index < texts.length; index++)
      CsvTextRow(rowNumber: index + 1, text: texts[index]),
  ],
);

void main() {
  group('SentimentLabel.tryParse', () {
    test('mengenali label Indonesia dan Inggris', () {
      expect(SentimentLabel.tryParse('Positif'), SentimentLabel.positif);
      expect(SentimentLabel.tryParse(' negative '), SentimentLabel.negatif);
      expect(SentimentLabel.tryParse('Positive'), SentimentLabel.positif);
      expect(SentimentLabel.tryParse('NEGATIF'), SentimentLabel.negatif);
    });

    test('menolak label yang tidak dikenali atau bukan teks', () {
      expect(SentimentLabel.tryParse('Netral'), isNull);
      expect(SentimentLabel.tryParse('1'), isNull);
      expect(SentimentLabel.tryParse(1), isNull);
      expect(SentimentLabel.tryParse(null), isNull);
      expect(SentimentLabel.tryParse(''), isNull);
    });
  });

  group('SingleAnalysisResult.fromJson', () {
    test('membaca label, teks, dan confidence yang valid', () {
      final result = SingleAnalysisResult.fromJson(
        decodeObject(
          '{"text":"game seru","label":"Positif","confidence":0.94}',
        ),
        submittedText: 'game seru',
      );

      expect(result.label, SentimentLabel.positif);
      expect(result.text, 'game seru');
      expect(result.confidence, 0.94);
    });

    test('mengembalikan teks kiriman bila backend tidak mengembalikannya', () {
      final result = SingleAnalysisResult.fromJson(
        decodeObject('{"label":"Negatif"}'),
        submittedText: 'ulasan asli',
      );

      expect(result.text, 'ulasan asli');
      expect(result.confidence, isNull);
    });

    test('mengabaikan confidence di luar rentang probabilitas', () {
      final result = SingleAnalysisResult.fromJson(
        decodeObject('{"label":"Positif","confidence":94}'),
        submittedText: 'ulasan',
      );

      expect(result.confidence, isNull);
    });

    test('melempar FormatException saat label tidak dikenali', () {
      expect(
        () => SingleAnalysisResult.fromJson(
          decodeObject('{"label":"Netral"}'),
          submittedText: 'ulasan',
        ),
        throwsFormatException,
      );

      expect(
        () => SingleAnalysisResult.fromJson(
          decodeObject('{"confidence":0.5}'),
          submittedText: 'ulasan',
        ),
        throwsFormatException,
      );
    });
  });

  group('CsvAnalysisResult.fromBatchResponse', () {
    test('memasangkan hasil berurutan dan menghitung ringkasan', () {
      final result = CsvAnalysisResult.fromBatchResponse(
        decodeObject(
          '{"total":3,'
          '"results":['
          '{"row":2,"label":"Positif"},'
          '{"row":3,"label":"Negatif"},'
          '{"row":4,"label":"Positif"}],'
          '"skipped":[]}',
        ),
        fileName: 'dataset.csv',
        parsed: parsedOf(['bagus', 'jelek', 'mantap']),
      );

      expect(result.fileName, 'dataset.csv');
      expect(result.totalRows, 3);
      expect(result.analyzedRows, 3);
      expect(result.failedRows, 0);
      expect(result.rows, hasLength(3));
      expect(result.rows.map((row) => row.text), ['bagus', 'jelek', 'mantap']);
      expect(result.positiveCount, 2);
      expect(result.negativeCount, 1);
      expect(result.labeledRows, 3);
      expect(result.positivePercentage, closeTo(66.67, 0.01));
      expect(result.negativePercentage, closeTo(33.33, 0.01));
    });

    test('menghitung baris yang dilewati backend sebagai baris gagal', () {
      // Baris kosong di baris file ke-2 tidak ikut parsing lokal, tetapi tetap
      // dilaporkan backend sehingga ringkasan tidak menghitungnya dua kali.
      final result = CsvAnalysisResult.fromBatchResponse(
        decodeObject(
          '{"total":3,'
          '"results":[{"row":2,"label":"Negatif"},{"row":4,"label":"Positif"}],'
          '"skipped":[{"row":3,"reason":"baris tidak memiliki kolom teks yang '
          'valid"}]}',
        ),
        fileName: 'dataset.csv',
        parsed: parsedOf(['satu', 'dua']),
      );

      expect(result.analyzedRows, 2);
      expect(result.failedRows, 1);
      expect(result.totalRows, 3);
      expect(result.rows.map((row) => row.text), ['satu', 'dua']);
      expect(result.negativeCount, 1);
      expect(result.positiveCount, 1);
    });

    test('memetakan lewat nomor baris ketika jumlah hasil berbeda dari parsing '
        'lokal', () {
      final result = CsvAnalysisResult.fromBatchResponse(
        decodeObject(
          '{"total":2,'
          '"results":[{"row":3,"label":"Positif"}],'
          '"skipped":[{"row":2,"reason":"teks kosong"}]}',
        ),
        fileName: 'dataset.csv',
        parsed: parsedOf(['satu', 'dua']),
      );

      // Baris data pertama = baris 2 menurut backend, jadi baris 3 menurut
      // backend menunjuk ke baris data kedua menurut aplikasi.
      expect(result.analyzedRows, 1);
      expect(result.rows.single.rowNumber, 2);
      expect(result.rows.single.text, 'dua');
      expect(result.rows.single.label, SentimentLabel.positif);
      expect(result.failedRows, 2);
      expect(result.totalRows, 3);
    });

    test('tidak membagi nol ketika tidak ada baris berlabel', () {
      final result = CsvAnalysisResult.fromBatchResponse(
        decodeObject('{"total":0,"results":[],"skipped":[]}'),
        fileName: 'dataset.csv',
        parsed: parsedOf(const []),
      );

      expect(result.totalRows, 0);
      expect(result.analyzedRows, 0);
      expect(result.failedRows, 0);
      expect(result.labeledRows, 0);
      expect(result.positivePercentage, 0);
      expect(result.negativePercentage, 0);
    });

    test('melempar FormatException saat ada baris tanpa label sah', () {
      expect(
        () => CsvAnalysisResult.fromBatchResponse(
          decodeObject('{"results":[{"row":2}],"skipped":[]}'),
          fileName: 'dataset.csv',
          parsed: parsedOf(['satu']),
        ),
        throwsFormatException,
      );
    });

    test('melempar FormatException saat nomor baris tidak ada', () {
      expect(
        () => CsvAnalysisResult.fromBatchResponse(
          decodeObject('{"results":[{"label":"Positif"}],"skipped":[]}'),
          fileName: 'dataset.csv',
          parsed: parsedOf(['satu']),
        ),
        throwsFormatException,
      );
    });

    test('melempar FormatException saat daftar hasil bukan array', () {
      expect(
        () => CsvAnalysisResult.fromBatchResponse(
          decodeObject('{"results":"kosong","skipped":[]}'),
          fileName: 'dataset.csv',
          parsed: parsedOf(const []),
        ),
        throwsFormatException,
      );
    });
  });
}
