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

Uint8List toBytes(String content) => Uint8List.fromList(utf8.encode(content));

/// Layar 360px dengan skala font 2x (pengguna Android font besar). Layout yang
/// tidak menyesuaikan akan melempar overflow dan menjatuhkan tes ini.
Future<void> pumpNarrow(
  WidgetTester tester,
  AnalysisController controller,
) async {
  tester.binding.platformDispatcher.textScaleFactorTestValue = 2.0;
  addTearDown(tester.binding.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.binding.setSurfaceSize(const Size(360, 640));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(),
      home: AnalyzePage(controller: controller),
    ),
  );
}

void main() {
  testWidgets('empty state dan navbar utuh pada layar sempit berskala 2x', (
    tester,
  ) async {
    final controller = buildController(
      MockClient((request) async => http.Response('tak terpakai', 500)),
    );
    addTearDown(controller.dispose);
    await pumpNarrow(tester, controller);

    expect(find.byType(AppNavbar), findsOneWidget);
    expect(find.text('Analisis Sentimen Ulasan Steam'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('tabel dan pagination utuh pada layar sempit berskala 2x', (
    tester,
  ) async {
    final rows = [
      for (var index = 1; index <= 25; index++)
        {'row': index + 1, 'label': index.isEven ? 'Negatif' : 'Positif'},
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
    await pumpNarrow(tester, controller);

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

    await tester.tap(find.byTooltip('Analisis file CSV'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    expect(find.text('Hasil Analisis'), findsOneWidget);
    expect(find.text('1 / 3'), findsOneWidget);

    await tester.ensureVisible(find.text('Berikutnya'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Berikutnya'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(find.text('2 / 3'), findsOneWidget);
    expect(find.text('ulasan 11'), findsOneWidget);
  });
}
