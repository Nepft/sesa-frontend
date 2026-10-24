import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:steam_sentimen_analyzer/controllers/analysis_controller.dart';
import 'package:steam_sentimen_analyzer/pages/analyze_page.dart';
import 'package:steam_sentimen_analyzer/services/csv_export_service.dart';
import 'package:steam_sentimen_analyzer/services/csv_file_service.dart';
import 'package:steam_sentimen_analyzer/services/sentiment_api_service.dart';
import 'package:steam_sentimen_analyzer/theme/app_theme.dart';
import 'package:steam_sentimen_analyzer/widgets/app_navbar.dart';
import 'package:steam_sentimen_analyzer/widgets/csv_result_table.dart';

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

Future<void> pumpApp(WidgetTester tester, AnalysisController controller) {
  return tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(),
      home: AnalyzePage(controller: controller),
    ),
  );
}

Uint8List toBytes(String content) => Uint8List.fromList(utf8.encode(content));

void main() {
  testWidgets('menampilkan empty state, navbar, dan komposer', (tester) async {
    final controller = buildController(
      MockClient((request) async => http.Response('tak terpakai', 500)),
    );
    addTearDown(controller.dispose);
    await pumpApp(tester, controller);

    expect(find.byType(AppNavbar), findsOneWidget);
    expect(find.text('Analisis Sentimen Ulasan Steam'), findsOneWidget);
    expect(
      find.text('CSV · kolom content · maks 5 MB · Enter kirim'),
      findsOneWidget,
    );
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Hasil Analisis'), findsNothing);
    expect(find.byType(CsvResultTable), findsNothing);
  });

  testWidgets('menampilkan validasi ketika teks hanya berisi spasi', (
    tester,
  ) async {
    final controller = buildController(
      MockClient((request) async => fail('API tidak boleh dipanggil')),
    );
    addTearDown(controller.dispose);
    await pumpApp(tester, controller);

    await tester.enterText(find.byType(TextField), '   ');
    await tester.pump();
    await tester.tap(find.byTooltip('Kirim ulasan'));
    await tester.pump();

    expect(find.text('Tulis ulasan terlebih dahulu.'), findsOneWidget);
    expect(find.text('Hasil Analisis'), findsNothing);
  });

  testWidgets('analisis satu teks menampilkan hasil lalu mengosongkan input', (
    tester,
  ) async {
    final controller = buildController(
      MockClient((request) async {
        return http.Response(
          '{"text":"steam bagus","label":"Positif","confidence":0.94}',
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    addTearDown(controller.dispose);
    await pumpApp(tester, controller);

    await tester.enterText(find.byType(TextField), 'steam bagus');
    await tester.pump();
    expect(find.text('11 / 2000'), findsOneWidget);

    await tester.tap(find.byTooltip('Kirim ulasan'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    expect(find.text('Hasil Analisis'), findsOneWidget);
    expect(find.text('Positif'), findsOneWidget);
    expect(find.text('steam bagus'), findsOneWidget);
    expect(find.text('Confidence 94%'), findsOneWidget);
    expect(controller.textController.text, isEmpty);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('menampilkan status backend belum terhubung tanpa hasil palsu', (
    tester,
  ) async {
    final controller = buildController(
      MockClient((request) async {
        throw http.ClientException('connection refused');
      }),
    );
    addTearDown(controller.dispose);
    await pumpApp(tester, controller);

    await tester.enterText(find.byType(TextField), 'ulasan pengguna');
    await tester.pump();
    await tester.tap(find.byTooltip('Kirim ulasan'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    expect(find.textContaining('Backend belum terhubung'), findsOneWidget);
    expect(find.text('Coba lagi'), findsOneWidget);
    expect(find.text('Hasil Analisis'), findsNothing);
    // Teks pengguna tetap tersimpan ketika analisis gagal.
    expect(controller.textController.text, 'ulasan pengguna');
  });

  testWidgets('alur CSV: lampiran, ringkasan, tabel, dan pagination', (
    tester,
  ) async {
    final rows = [
      for (var index = 1; index <= 25; index++)
        {
          // Header menempati baris 1, jadi baris data pertama = baris 2.
          'row': index + 1,
          'label': index.isEven ? 'Negatif' : 'Positif',
        },
    ];
    final controller = buildController(
      MockClient((request) async {
        return http.Response(
          jsonEncode({'total': 25, 'results': rows, 'skipped': []}),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    addTearDown(controller.dispose);
    await pumpApp(tester, controller);

    final bytes = toBytes(
      [
        'content',
        for (var index = 1; index <= 25; index++) 'ulasan $index',
      ].join('\n'),
    );
    controller.attachCsvFile(
      fileName: 'dataset.csv',
      fileSizeBytes: bytes.length,
      bytes: bytes,
    );
    await tester.pump();

    expect(find.byType(TextField), findsNothing);
    expect(find.text('File CSV terlampir.'), findsOneWidget);
    expect(find.text('Hapus lampiran untuk menulis ulasan'), findsOneWidget);

    await tester.tap(find.byTooltip('Analisis file CSV'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    expect(find.text('Hasil Analisis'), findsOneWidget);
    // Nama file tampil di ringkasan hasil sekaligus pada chip lampiran.
    expect(find.text('dataset.csv'), findsWidgets);
    expect(find.text('Dianalisis'), findsOneWidget);
    expect(find.text('52.0%'), findsOneWidget);
    expect(find.text('48.0%'), findsOneWidget);
    expect(find.text('Dari 25 ulasan berhasil dianalisis.'), findsOneWidget);
    expect(find.text('Detail per ulasan'), findsOneWidget);
    expect(find.text('Unduh hasil'), findsOneWidget);
    expect(find.text('1 / 3'), findsOneWidget);
    expect(find.text('ulasan 1'), findsOneWidget);

    // Berpindah halaman tabel tanpa merender seluruh baris sekaligus.
    await tester.ensureVisible(find.text('Berikutnya'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Berikutnya'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(find.text('2 / 3'), findsOneWidget);
    expect(find.text('ulasan 1'), findsNothing);
    expect(find.text('ulasan 11'), findsOneWidget);
    expect(find.text('Sebelumnya'), findsOneWidget);
  });
}
