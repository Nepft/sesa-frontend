import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:steam_sentimen_analyzer/controllers/analysis_controller.dart';
import 'package:steam_sentimen_analyzer/models/sentiment_label.dart';
import 'package:steam_sentimen_analyzer/services/csv_export_service.dart';
import 'package:steam_sentimen_analyzer/services/csv_file_service.dart';
import 'package:steam_sentimen_analyzer/services/sentiment_api_service.dart';

Uint8List toBytes(String content) => Uint8List.fromList(utf8.encode(content));

AnalysisController buildController(MockClient client) {
  return AnalysisController(
    apiService: SentimentApiService(
      client: client,
      baseUrl: 'http://backend.test',
    ),
    csvFileService: const CsvFileService(),
    csvExportService: const CsvExportService(),
  );
}

/// Client yang gagal bila ada request yang seharusnya tidak dikirim.
MockClient unexpectedRequestClient() {
  return MockClient((request) async {
    fail('Tidak seharusnya memanggil API, tetapi memanggil ${request.url}');
  });
}

void main() {
  group('validasi teks', () {
    test('menolak teks kosong dan hanya spasi', () {
      expect(
        AnalysisController.validateText(''),
        'Tulis ulasan terlebih dahulu.',
      );
      expect(
        AnalysisController.validateText('   \n '),
        'Tulis ulasan terlebih dahulu.',
      );
    });

    test('menolak teks melebihi batas karakter', () {
      final message = AnalysisController.validateText('a' * 2001);
      expect(message, contains('2000'));
    });

    test('menerima teks wajar', () {
      expect(AnalysisController.validateText('game bagus'), isNull);
    });
  });

  group('analyzeText', () {
    test('tidak memanggil API untuk teks yang tidak valid', () async {
      final controller = buildController(unexpectedRequestClient());
      addTearDown(controller.dispose);
      controller.textController.text = '   ';

      await controller.analyzeText();

      expect(controller.composerMessage, 'Tulis ulasan terlebih dahulu.');
      expect(controller.singleResult, isNull);
      expect(controller.isLoading, isFalse);
    });

    test(
      'menyimpan hasil, mengosongkan teks, dan membersihkan pesan',
      () async {
        final controller = buildController(
          MockClient((request) async {
            return http.Response(
              '{"label":"Positif","confidence":0.9}',
              200,
              headers: {'content-type': 'application/json'},
            );
          }),
        );
        addTearDown(controller.dispose);
        controller.textController.text = 'steam bagus';

        await controller.analyzeText();

        expect(controller.singleResult?.label, SentimentLabel.positif);
        expect(controller.textController.text, isEmpty);
        expect(controller.composerMessage, isNull);
        expect(controller.notice, isNull);
        expect(controller.isLoading, isFalse);
      },
    );

    test(
      'menampilkan status backend belum terhubung dan menyimpan teks',
      () async {
        final controller = buildController(
          MockClient((request) async {
            throw http.ClientException('connection refused');
          }),
        );
        addTearDown(controller.dispose);
        controller.textController.text = 'ulasan pengguna';

        await controller.analyzeText();

        expect(controller.singleResult, isNull);
        expect(controller.textController.text, 'ulasan pengguna');
        expect(controller.notice, isNotNull);
        expect(controller.notice!.message, contains('Backend belum terhubung'));
        expect(controller.notice!.retry, NoticeRetry.text);
        expect(controller.notice!.tone, NoticeTone.info);
      },
    );

    test('mengosongkan pesan komposer begitu pengguna mengedit teks', () async {
      final controller = buildController(unexpectedRequestClient());
      addTearDown(controller.dispose);
      controller.textController.text = '';

      await controller.analyzeText();
      expect(controller.composerMessage, isNotNull);

      controller.textController.text = 'b';
      controller.onTextChanged();

      expect(controller.composerMessage, isNull);
    });
  });

  group('lampiran CSV', () {
    test('melampirkan file valid dan menghitung baris siap kirim', () {
      final controller = buildController(unexpectedRequestClient());
      addTearDown(controller.dispose);

      controller.attachCsvFile(
        fileName: 'dataset.csv',
        fileSizeBytes: 40,
        bytes: toBytes('content\nsteam bagus\naplikasi jelek\n'),
      );

      expect(controller.attachment, isNotNull);
      expect(controller.attachment!.fileName, 'dataset.csv');
      expect(controller.attachment!.parsed.validRows.map((row) => row.text), [
        'steam bagus',
        'aplikasi jelek',
      ]);
      expect(
        controller.attachment!.bytes,
        toBytes('content\nsteam bagus\naplikasi jelek\n'),
      );
      expect(controller.composerMessage, isNull);
    });

    test('menolak file tanpa kolom content tanpa mengganti lampiran lama', () {
      final controller = buildController(unexpectedRequestClient());
      addTearDown(controller.dispose);
      controller.attachCsvFile(
        fileName: 'lama.csv',
        fileSizeBytes: 20,
        bytes: toBytes('content\nulasan\n'),
      );

      controller.attachCsvFile(
        fileName: 'baru.csv',
        fileSizeBytes: 20,
        bytes: toBytes('teks\nulasan\n'),
      );

      expect(controller.attachment!.fileName, 'lama.csv');
      expect(controller.composerMessage, contains('content'));
    });

    test('menolak file dengan ukuran melampaui batas', () {
      final controller = buildController(unexpectedRequestClient());
      addTearDown(controller.dispose);

      controller.attachCsvFile(
        fileName: 'besar.csv',
        fileSizeBytes: 6 * 1024 * 1024,
        bytes: toBytes('content\nulasan\n'),
      );

      expect(controller.attachment, isNull);
      expect(controller.composerMessage, contains('5 MB'));
    });

    test('melepas lampiran tanpa menghapus hasil yang sudah tampil', () async {
      final controller = buildController(
        MockClient((request) async {
          return http.Response(
            '{"total":1,"results":[{"row":2,"label":"Positif"}],"skipped":[]}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      addTearDown(controller.dispose);
      controller.attachCsvFile(
        fileName: 'dataset.csv',
        fileSizeBytes: 30,
        bytes: toBytes('content\nbagus\n'),
      );

      await controller.analyzeCsv();
      expect(controller.csvResult, isNotNull);

      controller.clearAttachment();

      expect(controller.attachment, isNull);
      expect(controller.csvResult, isNotNull);
      expect(controller.hasAnyResult, isTrue);
    });
  });

  group('analyzeCsv', () {
    test('menyimpan hasil CSV dan menggantikan hasil teks tunggal', () async {
      // Satu client melayani dua endpoint dengan respons yang sesuai kontrak
      // masing-masing.
      final controller = buildController(
        MockClient((request) async {
          final isBatch = request.url.path.endsWith('/predict/batch');
          final body = isBatch
              ? '{"total":1,'
                    '"results":[{"row":2,"label":"Negatif"}],"skipped":[]}'
              : '{"label":"Positif","confidence":0.9}';
          return http.Response(
            body,
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      addTearDown(controller.dispose);
      controller.textController.text = 'sudah dianalisis';
      await controller.analyzeText();
      expect(controller.singleResult, isNotNull);

      controller.textController.text = '';
      controller.attachCsvFile(
        fileName: 'dataset.csv',
        fileSizeBytes: 26,
        bytes: toBytes('content\njelek\n'),
      );
      await controller.analyzeCsv();

      expect(controller.csvResult, isNotNull);
      expect(controller.singleResult, isNull);
      expect(controller.csvResult!.negativeCount, 1);
      expect(controller.isLoading, isFalse);
    });

    test('memberi pesan ulang (retry) ketika backend belum tersedia', () async {
      final controller = buildController(
        MockClient((request) async {
          throw http.ClientException('connection refused');
        }),
      );
      addTearDown(controller.dispose);
      controller.attachCsvFile(
        fileName: 'dataset.csv',
        fileSizeBytes: 26,
        bytes: toBytes('content\njelek\n'),
      );

      await controller.analyzeCsv();

      expect(controller.csvResult, isNull);
      expect(controller.notice?.retry, NoticeRetry.csv);
      expect(controller.attachment, isNotNull);
    });

    test('submit mengarah ke alur CSV bila ada lampiran', () async {
      final controller = buildController(
        MockClient((request) async {
          return http.Response(
            '{"total":1,"results":[{"row":2,"label":"Positif"}],"skipped":[]}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      addTearDown(controller.dispose);
      controller.attachCsvFile(
        fileName: 'dataset.csv',
        fileSizeBytes: 27,
        bytes: toBytes('content\nbagus\n'),
      );

      await controller.submit();

      expect(controller.csvResult, isNotNull);
      expect(controller.singleResult, isNull);
    });
  });
}
