import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:steam_sentimen_analyzer/models/sentiment_label.dart';
import 'package:steam_sentimen_analyzer/services/csv_file_service.dart';
import 'package:steam_sentimen_analyzer/services/sentiment_api_service.dart';

SentimentApiService buildService(
  MockClient client, {
  String baseUrl = 'http://backend.test',
}) {
  return SentimentApiService(client: client, baseUrl: baseUrl);
}

/// Hasil parsing lokal yang dipakai pemanggilan batch, persis seperti yang
/// dihasilkan controller dari file yang sama.
ParsedCsvFile parseCsv(String content) => const CsvFileService().parse(content);

Uint8List bytesOf(String content) => Uint8List.fromList(utf8.encode(content));

void main() {
  group('predictText', () {
    test('mengirim kontrak request dan membaca respons yang sah', () async {
      http.Request? captured;
      final service = buildService(
        MockClient((request) async {
          captured = request;
          return http.Response(
            '{"text":"game menyenangkan","label":"Positif","confidence":0.87}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      final result = await service.predictText('game menyenangkan');

      expect(captured, isNotNull);
      expect(captured!.method, 'POST');
      expect(captured!.url.toString(), 'http://backend.test/predict');
      expect(captured!.headers['content-type'], contains('application/json'));
      expect(jsonDecode(captured!.body), {'text': 'game menyenangkan'});
      expect(result.label, SentimentLabel.positif);
      expect(result.confidence, 0.87);
    });

    test(
      'memberi pesan backend belum terhubung bila server tidak ada',
      () async {
        final service = buildService(
          MockClient((request) async {
            throw http.ClientException('connection refused');
          }),
        );

        await expectLater(
          service.predictText('ulasan'),
          throwsA(
            isA<BackendUnavailableException>().having(
              (error) => error.message,
              'message',
              contains('Backend belum terhubung'),
            ),
          ),
        );
      },
    );

    test('memberi pesan endpoint belum tersedia pada status 404', () async {
      final service = buildService(
        MockClient((request) async => http.Response('Not Found', 404)),
      );

      await expectLater(
        service.predictText('ulasan'),
        throwsA(
          isA<BackendUnavailableException>().having(
            (error) => error.message,
            'message',
            contains('Endpoint prediksi belum tersedia'),
          ),
        ),
      );
    });

    test(
      'memakai pesan detail backend pada status 503 (model belum siap)',
      () async {
        final service = buildService(
          MockClient(
            (request) async => http.Response(
              '{"detail":"Model belum siap. Coba lagi nanti."}',
              503,
              headers: {'content-type': 'application/json'},
            ),
          ),
        );

        await expectLater(
          service.predictText('ulasan'),
          throwsA(
            isA<BackendUnavailableException>().having(
              (error) => error.message,
              'message',
              contains('Model belum siap'),
            ),
          ),
        );
      },
    );

    test(
      'melaporkan status HTTP selain 2xx tanpa menampilkan hasil palsu',
      () async {
        final service = buildService(
          MockClient((request) async => http.Response('boom', 500)),
        );

        await expectLater(
          service.predictText('ulasan'),
          throwsA(
            isA<SentimentApiException>().having(
              (error) => error.message,
              'message',
              contains('HTTP 500'),
            ),
          ),
        );
      },
    );

    test('memakai pesan detail backend untuk galat validasi', () async {
      final service = buildService(
        MockClient(
          (request) async => http.Response(
            '{"detail":"Teks terlalu panjang."}',
            400,
            headers: {'content-type': 'application/json'},
          ),
        ),
      );

      await expectLater(
        service.predictText('ulasan'),
        throwsA(
          isA<SentimentApiException>().having(
            (error) => error.message,
            'message',
            contains('Teks terlalu panjang'),
          ),
        ),
      );
    });

    test('menolak respons yang bukan JSON valid', () async {
      final service = buildService(
        MockClient((request) async => http.Response('<html></html>', 200)),
      );

      await expectLater(
        service.predictText('ulasan'),
        throwsA(isA<InvalidResponseException>()),
      );
    });

    test('menolak label sentimen yang tidak dikenali', () async {
      final service = buildService(
        MockClient((request) async => http.Response('{"label":"Netral"}', 200)),
      );

      await expectLater(
        service.predictText('ulasan'),
        throwsA(isA<InvalidResponseException>()),
      );
    });
  });

  group('analyzeCsv', () {
    test('mengirim file sebagai multipart dan membaca respons batch', () async {
      http.Request? captured;
      final service = buildService(
        MockClient((request) async {
          captured = request;
          return http.Response(
            '{"total":2,'
            '"results":['
            '{"row":2,"label":"Positif"},'
            '{"row":3,"label":"Negatif"}],'
            '"skipped":[]}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      final result = await service.analyzeCsv(
        fileName: 'dataset.csv',
        bytes: bytesOf('content\nbagus\njelek\n'),
        parsed: parseCsv('content\nbagus\njelek\n'),
      );

      expect(captured!.method, 'POST');
      expect(captured!.url.toString(), 'http://backend.test/predict/batch');
      expect(
        captured!.headers['content-type'],
        contains('multipart/form-data'),
      );
      final payload = utf8.decode(captured!.bodyBytes, allowMalformed: true);
      expect(payload, contains('name="file"'));
      expect(payload, contains('filename="dataset.csv"'));
      expect(payload, contains('content'));
      expect(payload, contains('bagus'));

      expect(result.fileName, 'dataset.csv');
      expect(result.analyzedRows, 2);
      expect(result.rows.map((row) => row.text), ['bagus', 'jelek']);
      expect(result.positiveCount, 1);
      expect(result.negativeCount, 1);
      expect(result.positivePercentage, 50);
    });

    test(
      'memberi pesan backend belum terhubung bila server tidak ada',
      () async {
        final service = buildService(
          MockClient((request) async {
            throw http.ClientException('connection refused');
          }),
        );

        await expectLater(
          service.analyzeCsv(
            fileName: 'dataset.csv',
            bytes: bytesOf('content\nsatu\n'),
            parsed: parseCsv('content\nsatu\n'),
          ),
          throwsA(isA<BackendUnavailableException>()),
        );
      },
    );

    test('memakai pesan detail backend ketika file ditolak', () async {
      final service = buildService(
        MockClient(
          (request) async => http.Response(
            '{"detail":"Kolom \'content\' tidak ditemukan pada file CSV."}',
            400,
            headers: {'content-type': 'application/json'},
          ),
        ),
      );

      await expectLater(
        service.analyzeCsv(
          fileName: 'dataset.csv',
          bytes: bytesOf('teks\nsatu\n'),
          parsed: parseCsv('content\nsatu\n'),
        ),
        throwsA(
          isA<SentimentApiException>().having(
            (error) => error.message,
            'message',
            contains("Kolom 'content' tidak ditemukan"),
          ),
        ),
      );
    });

    test('menolak respons dengan baris tanpa label sah', () async {
      final service = buildService(
        MockClient(
          (request) async => http.Response(
            '{"total":1,"results":[{"row":2}],"skipped":[]}',
            200,
          ),
        ),
      );

      await expectLater(
        service.analyzeCsv(
          fileName: 'dataset.csv',
          bytes: bytesOf('content\nsatu\n'),
          parsed: parseCsv('content\nsatu\n'),
        ),
        throwsA(isA<InvalidResponseException>()),
      );
    });
  });
}
