import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:steam_sentimen_analyzer/services/csv_file_service.dart';

Uint8List toBytes(String content) => Uint8List.fromList(utf8.encode(content));

void main() {
  const service = CsvFileService();

  group('validateFile', () {
    test('menerima file .csv dalam batas ukuran', () {
      expect(
        service.validateFile(fileName: 'dataset.csv', fileSizeBytes: 2048),
        isNull,
      );
      expect(
        service.validateFile(
          fileName: 'DATASET.CSV',
          fileSizeBytes: 5 * 1024 * 1024,
        ),
        isNull,
      );
    });

    test('menolak ekstensi selain .csv', () {
      final message = service.validateFile(
        fileName: 'dataset.txt',
        fileSizeBytes: 10,
      );
      expect(message, contains('.csv'));
    });

    test('menolak file yang melampaui 5 MB', () {
      final message = service.validateFile(
        fileName: 'dataset.csv',
        fileSizeBytes: 6 * 1024 * 1024,
      );
      expect(message, contains('5 MB'));
    });

    test('menolak file kosong', () {
      final message = service.validateFile(
        fileName: 'dataset.csv',
        fileSizeBytes: 0,
      );
      expect(message, contains('kosong'));
    });
  });

  group('parseBytes', () {
    test('membaca file UTF-8 normal', () {
      final parsed = service.parseBytes(toBytes('content\nsteam bagus\n'));

      expect(parsed.totalRows, 1);
      expect(parsed.validRows.single.text, 'steam bagus');
      expect(parsed.validRows.single.rowNumber, 1);
    });

    test('menolak file dengan encoding tidak didukung', () {
      final invalidUtf8 = Uint8List.fromList([0x63, 0x6f, 0x6e, 0xff, 0xfe]);

      expect(
        () => service.parseBytes(invalidUtf8),
        throwsA(
          isA<CsvFileException>().having(
            (error) => error.message,
            'message',
            contains('UTF-8'),
          ),
        ),
      );
    });

    test('menolak file kosong', () {
      expect(
        () => service.parseBytes(Uint8List(0)),
        throwsA(isA<CsvFileException>()),
      );
    });
  });

  group('parse', () {
    test('membaca kolom content beserta koma dan baris di dalam kutipan', () {
      const content =
          'id,content\n'
          '1,"game seru, tapi berat"\n'
          '2,"baris satu\nbaris dua"\n';

      final parsed = service.parse(content);

      expect(parsed.totalRows, 2);
      expect(parsed.validRows, hasLength(2));
      expect(parsed.validRows[0].text, 'game seru, tapi berat');
      expect(parsed.validRows[1].text, 'baris satu\nbaris dua');
      expect(parsed.validRows[1].rowNumber, 2);
    });

    test('mengabaikan BOM dan tidak membedakan huruf besar/kecil header', () {
      final parsed = service.parse('\uFEFFContent\nulasan pertama\n');

      expect(parsed.validRows.single.text, 'ulasan pertama');
    });

    test('mempertahankan nomor baris walau ada baris yang dilewati', () {
      const content =
          'id,content\n'
          '1,\n'
          '2,ulasan kedua\n'
          '3,   \n'
          '4,ulasan keempat\n';

      final parsed = service.parse(content);

      expect(parsed.totalRows, 4);
      expect(parsed.skippedRows, 2);
      expect(parsed.validRows.map((row) => row.rowNumber), [2, 4]);
      expect(parsed.validRows.map((row) => row.text), [
        'ulasan kedua',
        'ulasan keempat',
      ]);
    });

    test('menolak file tanpa kolom content', () {
      expect(
        () => service.parse('text\nulasan\n'),
        throwsA(
          isA<CsvFileException>().having(
            (error) => error.message,
            'message',
            allOf(contains('kolom'), contains('content')),
          ),
        ),
      );
    });

    test('menolak file tanpa baris data', () {
      expect(
        () => service.parse('content\n'),
        throwsA(
          isA<CsvFileException>().having(
            (error) => error.message,
            'message',
            contains('baris data'),
          ),
        ),
      );
    });

    test('menolak file yang seluruh isinya whitespace', () {
      expect(
        () => service.parse('   \n  \n'),
        throwsA(isA<CsvFileException>()),
      );
    });

    test('menolak file yang semua baris teksnya kosong', () {
      expect(
        () => service.parse('id,content\n1,\n2,\n'),
        throwsA(
          isA<CsvFileException>().having(
            (error) => error.message,
            'message',
            contains('Semua baris'),
          ),
        ),
      );
    });

    test('menangani file satu kolom tanpa pemisah', () {
      final parsed = service.parse('content\nulasan satu\nulasan dua\n');

      expect(parsed.validRows, hasLength(2));
      expect(parsed.validRows.first.text, 'ulasan satu');
    });

    test('menangani akhir baris Windows', () {
      final parsed = service.parse('content\r\nulasan pertama\r\n');

      expect(parsed.totalRows, 1);
      expect(parsed.validRows.single.text, 'ulasan pertama');
    });
  });
}
